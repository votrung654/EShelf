# Script to deploy Staging Environment
# Usage: .\scripts\deploy-staging.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Staging Environment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# Check kubectl
Write-Host "`n[1/6] Checking kubectl..." -ForegroundColor Yellow
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] kubectl not found. Please install kubectl first." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] kubectl is available" -ForegroundColor Green

# Check cluster connection
Write-Host "`n[2/6] Checking cluster connection..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot connect to cluster"
    }
    Write-Host "[OK] Connected to cluster" -ForegroundColor Green
    kubectl get nodes
} catch {
    Write-Host "[ERROR] Cannot connect to Kubernetes cluster. Please check your kubeconfig." -ForegroundColor Red
    exit 1
}

# Check ArgoCD
Write-Host "`n[3/6] Checking ArgoCD..." -ForegroundColor Yellow
$argocdPods = kubectl get pods -n argocd 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] ArgoCD namespace not found. Please deploy ArgoCD first." -ForegroundColor Red
    exit 1
}
$argocdServer = kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server 2>&1
if ($LASTEXITCODE -ne 0 -or ($argocdServer | Select-String -Pattern "Running" -Quiet) -eq $false) {
    Write-Host "[WARN] ArgoCD server may not be running. Continuing anyway..." -ForegroundColor Yellow
} else {
    Write-Host "[OK] ArgoCD is running" -ForegroundColor Green
}

# Check GitHub Secrets (informational)
Write-Host "`n[4/6] Checking prerequisites..." -ForegroundColor Yellow
Write-Host "[INFO] Make sure GitHub Secrets are set up:" -ForegroundColor Cyan
Write-Host "       - DOCKERHUB_USERNAME" -ForegroundColor Gray
Write-Host "       - DOCKERHUB_TOKEN" -ForegroundColor Gray
Write-Host "[OK] Prerequisites check completed" -ForegroundColor Green

# Check current branch
Write-Host "`n[5/6] Checking Git branch..." -ForegroundColor Yellow
$currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Not in a Git repository or Git not available" -ForegroundColor Yellow
} else {
    Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
    if ($currentBranch -ne "staging") {
        Write-Host "[WARN] You are not on 'staging' branch. Staging deployment requires 'staging' branch." -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 0
        }
    } else {
        Write-Host "[OK] On staging branch" -ForegroundColor Green
    }
}

# Deploy ArgoCD applications
Write-Host "`n[6/6] Deploying ArgoCD applications..." -ForegroundColor Yellow
$appDir = "infrastructure/kubernetes/argocd/applications"

if (-not (Test-Path $appDir)) {
    Write-Host "[ERROR] Applications directory not found: $appDir" -ForegroundColor Red
    exit 1
}

$stagingApps = Get-ChildItem -Path $appDir -Filter "*-staging-app.yaml"
$appCount = $stagingApps.Count

if ($appCount -eq 0) {
    Write-Host "[WARN] No staging applications found. Applying all applications..." -ForegroundColor Yellow
    $allApps = Get-ChildItem -Path $appDir -Filter "*-app.yaml"
    foreach ($app in $allApps) {
        if ($app.Name -match "staging") {
            Write-Host "  Applying: $($app.Name)" -ForegroundColor Gray
            kubectl apply -f $app.FullName
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] Failed to apply $($app.Name)" -ForegroundColor Red
            } else {
                Write-Host "  [OK] Applied $($app.Name)" -ForegroundColor Green
            }
        }
    }
} else {
    Write-Host "Found $appCount staging applications" -ForegroundColor Cyan
    foreach ($app in $stagingApps) {
        Write-Host "  Applying: $($app.Name)" -ForegroundColor Gray
        kubectl apply -f $app.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to apply $($app.Name)" -ForegroundColor Red
        } else {
            Write-Host "  [OK] Applied $($app.Name)" -ForegroundColor Green
        }
    }
}

# Wait for applications to sync
Write-Host "`nWaiting for applications to sync..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Show status
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Staging Environment Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nArgoCD Applications:" -ForegroundColor Yellow
kubectl get applications -n argocd | Select-String -Pattern "staging"

Write-Host "`nPods:" -ForegroundColor Yellow
kubectl get pods -n eshelf-staging

Write-Host "`nServices:" -ForegroundColor Yellow
kubectl get services -n eshelf-staging

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Push code to 'staging' branch to trigger build:" -ForegroundColor Gray
Write-Host "   git push origin staging" -ForegroundColor White
Write-Host ""
Write-Host "2. Monitor GitHub Actions for build progress" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Check ArgoCD sync status:" -ForegroundColor Gray
Write-Host "   kubectl get applications -n argocd" -ForegroundColor White
Write-Host ""
Write-Host "4. Port forward to test:" -ForegroundColor Gray
Write-Host "   kubectl port-forward svc/frontend -n eshelf-staging 3002:80" -ForegroundColor White
Write-Host "   kubectl port-forward svc/api-gateway -n eshelf-staging 3003:3000" -ForegroundColor White

Write-Host "`n[OK] Staging deployment initiated!" -ForegroundColor Green






