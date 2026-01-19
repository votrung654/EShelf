# Script to deploy Production Environment
# Usage: .\scripts\deploy-production.ps1
# WARNING: This will deploy to PRODUCTION. Use with caution!

Write-Host "========================================" -ForegroundColor Red
Write-Host "DEPLOYING PRODUCTION ENVIRONMENT" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red

$ErrorActionPreference = "Stop"

# Safety check
Write-Host "`n[WARNING] You are about to deploy to PRODUCTION!" -ForegroundColor Yellow
Write-Host "Make sure you have:" -ForegroundColor Yellow
Write-Host "  - Tested thoroughly on Staging" -ForegroundColor Gray
Write-Host "  - Reviewed all changes" -ForegroundColor Gray
Write-Host "  - Backup plan ready" -ForegroundColor Gray
Write-Host "  - Approval from team lead (if required)" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Type 'DEPLOY' to continue (case-sensitive)"
if ($confirm -ne "DEPLOY") {
    Write-Host "[CANCELLED] Deployment cancelled by user" -ForegroundColor Yellow
    exit 0
}

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

# Check staging status (recommendation)
Write-Host "`n[4/6] Checking staging environment..." -ForegroundColor Yellow
$stagingPods = kubectl get pods -n eshelf-staging 2>&1
if ($LASTEXITCODE -eq 0) {
    $stagingRunning = ($stagingPods | Select-String -Pattern "Running" | Measure-Object).Count
    Write-Host "Staging pods running: $stagingRunning" -ForegroundColor Cyan
    if ($stagingRunning -eq 0) {
        Write-Host "[WARN] No pods running in staging. Consider testing on staging first." -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Staging environment is active" -ForegroundColor Green
    }
} else {
    Write-Host "[WARN] Cannot check staging environment" -ForegroundColor Yellow
}

# Check current branch
Write-Host "`n[5/6] Checking Git branch..." -ForegroundColor Yellow
$currentBranch = git rev-parse --abbrev-ref HEAD 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] Not in a Git repository or Git not available" -ForegroundColor Yellow
} else {
    Write-Host "Current branch: $currentBranch" -ForegroundColor Cyan
    if ($currentBranch -ne "main") {
        Write-Host "[WARN] You are not on 'main' branch. Production deployment requires 'main' branch." -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            exit 0
        }
    } else {
        Write-Host "[OK] On main branch" -ForegroundColor Green
    }
}

# Deploy ArgoCD applications
Write-Host "`n[6/6] Deploying ArgoCD applications..." -ForegroundColor Yellow
$appDir = "infrastructure/kubernetes/argocd/applications"

if (-not (Test-Path $appDir)) {
    Write-Host "[ERROR] Applications directory not found: $appDir" -ForegroundColor Red
    exit 1
}

$prodApps = Get-ChildItem -Path $appDir -Filter "*-prod-app.yaml"
$appCount = $prodApps.Count

if ($appCount -eq 0) {
    Write-Host "[WARN] No production applications found. Applying all applications..." -ForegroundColor Yellow
    $allApps = Get-ChildItem -Path $appDir -Filter "*-app.yaml"
    foreach ($app in $allApps) {
        if ($app.Name -match "prod") {
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
    Write-Host "Found $appCount production applications" -ForegroundColor Cyan
    foreach ($app in $prodApps) {
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
Write-Host "Production Environment Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nArgoCD Applications:" -ForegroundColor Yellow
kubectl get applications -n argocd | Select-String -Pattern "prod"

Write-Host "`nPods:" -ForegroundColor Yellow
kubectl get pods -n eshelf-prod

Write-Host "`nServices:" -ForegroundColor Yellow
kubectl get services -n eshelf-prod

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Push code to 'main' branch to trigger build:" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor White
Write-Host ""
Write-Host "2. Monitor GitHub Actions for build progress" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Monitor ArgoCD sync status:" -ForegroundColor Gray
Write-Host "   kubectl get applications -n argocd -w" -ForegroundColor White
Write-Host ""
Write-Host "4. Monitor pods:" -ForegroundColor Gray
Write-Host "   kubectl get pods -n eshelf-prod -w" -ForegroundColor White
Write-Host ""
Write-Host "5. Check logs if issues occur:" -ForegroundColor Gray
Write-Host "   kubectl logs -n eshelf-prod -l app=api-gateway --tail=100" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Red
Write-Host "PRODUCTION DEPLOYMENT INITIATED" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host "Monitor closely and be ready to rollback if needed!" -ForegroundColor Yellow






