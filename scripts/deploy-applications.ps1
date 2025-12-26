# Script to deploy applications to K3s cluster
# Usage: .\scripts\deploy-applications.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Deploy Applications to K3s Cluster" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check kubectl
Write-Host "[Pre-check] Checking kubectl..." -ForegroundColor Cyan
$kubectlVersion = kubectl version --client --short 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  $kubectlVersion" -ForegroundColor Green
} else {
    Write-Host "  Error: kubectl not found or not configured" -ForegroundColor Red
    Write-Host "  Please run: .\scripts\get-kubeconfig.ps1 -Environment $Environment" -ForegroundColor Yellow
    exit 1
}

# Check cluster connection
Write-Host "`n[Pre-check] Checking cluster connection..." -ForegroundColor Cyan
$nodes = kubectl get nodes 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Cluster connected!" -ForegroundColor Green
    Write-Host $nodes -ForegroundColor White
} else {
    Write-Host "  Error: Cannot connect to cluster" -ForegroundColor Red
    Write-Host "  Please ensure kubeconfig is set up correctly" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Deploying Applications" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Deploy ArgoCD
Write-Host "[1/3] Deploying ArgoCD..." -ForegroundColor Cyan
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f - 2>&1 | Out-Null

$argocdPath = "infrastructure\kubernetes\argocd"
if (Test-Path $argocdPath) {
    Write-Host "  Applying ArgoCD manifests..." -ForegroundColor Yellow
    Get-ChildItem -Path $argocdPath -Filter "*.yaml" -Recurse | ForEach-Object {
        kubectl apply -f $_.FullName -n argocd 2>&1 | Out-Null
    }
    Write-Host "  ✅ ArgoCD manifests applied" -ForegroundColor Green
    
    Write-Host "  Waiting for ArgoCD server to be ready..." -ForegroundColor Yellow
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ ArgoCD server is ready!" -ForegroundColor Green
        
        # Get ArgoCD admin password
        Write-Host "`n  ArgoCD Admin Password:" -ForegroundColor Cyan
        $password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>&1
        if ($password) {
            $decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
            Write-Host "    $decodedPassword" -ForegroundColor Yellow
        }
        
        Write-Host "`n  To access ArgoCD UI:" -ForegroundColor Cyan
        Write-Host "    kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Gray
        Write-Host "    Then open: https://localhost:8080" -ForegroundColor Gray
        Write-Host "    Username: admin" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  ArgoCD server not ready yet. Check with: kubectl get pods -n argocd" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ⚠️  ArgoCD manifests not found at: $argocdPath" -ForegroundColor Yellow
}

# Deploy Monitoring Stack
Write-Host "`n[2/3] Deploying Monitoring Stack..." -ForegroundColor Cyan
$monitoringPath = "infrastructure\kubernetes\monitoring"
if (Test-Path $monitoringPath) {
    Write-Host "  Applying monitoring manifests..." -ForegroundColor Yellow
    Get-ChildItem -Path $monitoringPath -Filter "*.yaml" -Recurse | ForEach-Object {
        kubectl apply -f $_.FullName 2>&1 | Out-Null
    }
    Write-Host "  ✅ Monitoring stack applied" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Monitoring manifests not found at: $monitoringPath" -ForegroundColor Yellow
}

# Deploy Harbor Registry
Write-Host "`n[3/3] Deploying Harbor Registry..." -ForegroundColor Cyan
$harborPath = "infrastructure\kubernetes\harbor"
if (Test-Path $harborPath) {
    Write-Host "  Applying Harbor manifests..." -ForegroundColor Yellow
    Get-ChildItem -Path $harborPath -Filter "*.yaml" -Recurse | ForEach-Object {
        kubectl apply -f $_.FullName 2>&1 | Out-Null
    }
    Write-Host "  ✅ Harbor registry applied" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Harbor manifests not found at: $harborPath" -ForegroundColor Yellow
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Check application status:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -A" -ForegroundColor Gray
Write-Host "  kubectl get svc -A" -ForegroundColor Gray
Write-Host "  kubectl get applications -n argocd" -ForegroundColor Gray

Write-Host "`n✅ Application deployment initiated!" -ForegroundColor Green



