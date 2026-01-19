# Script to deploy all ArgoCD applications for 3 environments
# Usage: .\scripts\deploy-3-environments.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying 3 Environments (Dev, Staging, Prod)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

# Check kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] kubectl not found. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Check if connected to cluster
Write-Host "`n[1/4] Checking cluster connection..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot connect to cluster"
    }
    Write-Host "[OK] Connected to cluster" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Cannot connect to Kubernetes cluster. Please check your kubeconfig." -ForegroundColor Red
    exit 1
}

# Check ArgoCD namespace
Write-Host "`n[2/4] Checking ArgoCD namespace..." -ForegroundColor Yellow
$argocdNs = kubectl get namespace argocd 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARN] ArgoCD namespace not found. Creating..." -ForegroundColor Yellow
    kubectl create namespace argocd
    Write-Host "[OK] ArgoCD namespace created" -ForegroundColor Green
} else {
    Write-Host "[OK] ArgoCD namespace exists" -ForegroundColor Green
}

# Apply all ArgoCD applications
Write-Host "`n[3/4] Applying ArgoCD applications..." -ForegroundColor Yellow
$appDir = "infrastructure/kubernetes/argocd/applications"

if (-not (Test-Path $appDir)) {
    Write-Host "[ERROR] Applications directory not found: $appDir" -ForegroundColor Red
    exit 1
}

$apps = Get-ChildItem -Path $appDir -Filter "*-app.yaml"
$appCount = $apps.Count

Write-Host "Found $appCount ArgoCD applications" -ForegroundColor Cyan

foreach ($app in $apps) {
    Write-Host "  Applying: $($app.Name)" -ForegroundColor Gray
    kubectl apply -f $app.FullName
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to apply $($app.Name)" -ForegroundColor Red
    } else {
        Write-Host "  [OK] Applied $($app.Name)" -ForegroundColor Green
    }
}

# Wait for applications to sync
Write-Host "`n[4/4] Waiting for applications to sync..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Show application status
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ArgoCD Applications Status" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
kubectl get applications -n argocd

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dev Environment:     eshelf-dev" -ForegroundColor Green
Write-Host "Staging Environment: eshelf-staging" -ForegroundColor Yellow
Write-Host "Prod Environment:    eshelf-prod" -ForegroundColor Red

Write-Host "`nTo check application status:" -ForegroundColor Cyan
Write-Host "  kubectl get applications -n argocd" -ForegroundColor Gray
Write-Host "`nTo check pods in each environment:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n eshelf-dev" -ForegroundColor Gray
Write-Host "  kubectl get pods -n eshelf-staging" -ForegroundColor Gray
Write-Host "  kubectl get pods -n eshelf-prod" -ForegroundColor Gray

Write-Host "`n[OK] Deployment completed!" -ForegroundColor Green

