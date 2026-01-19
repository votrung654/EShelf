# Script to test 3 environments deployment
# Usage: .\scripts\test-3-environments.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing 3 Environments Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ErrorActionPreference = "Continue"

# Check kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] kubectl not found" -ForegroundColor Red
    exit 1
}

$environments = @("dev", "staging", "prod")
$services = @("frontend", "api-gateway", "auth-service", "book-service", "user-service", "ml-service")
$allPassed = $true

foreach ($env in $environments) {
    $namespace = "eshelf-$env"
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Testing Environment: $env ($namespace)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Check namespace exists
    Write-Host "`n[1] Checking namespace..." -ForegroundColor Yellow
    $ns = kubectl get namespace $namespace 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[FAIL] Namespace $namespace does not exist" -ForegroundColor Red
        $allPassed = $false
        continue
    }
    Write-Host "[OK] Namespace exists" -ForegroundColor Green
    
    # Check pods
    Write-Host "`n[2] Checking pods..." -ForegroundColor Yellow
    $pods = kubectl get pods -n $namespace -o json | ConvertFrom-Json
    if ($pods.items.Count -eq 0) {
        Write-Host "[WARN] No pods found in $namespace" -ForegroundColor Yellow
    } else {
        $runningPods = ($pods.items | Where-Object { $_.status.phase -eq "Running" }).Count
        $totalPods = $pods.items.Count
        Write-Host "  Pods: $runningPods/$totalPods Running" -ForegroundColor $(if ($runningPods -eq $totalPods) { "Green" } else { "Yellow" })
        
        foreach ($pod in $pods.items) {
            $status = $pod.status.phase
            $name = $pod.metadata.name
            $color = if ($status -eq "Running") { "Green" } elseif ($status -eq "Pending") { "Yellow" } else { "Red" }
            Write-Host "    $name : $status" -ForegroundColor $color
        }
    }
    
    # Check services
    Write-Host "`n[3] Checking services..." -ForegroundColor Yellow
    foreach ($service in $services) {
        $svc = kubectl get service $service -n $namespace 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Service $service exists" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Service $service not found" -ForegroundColor Yellow
        }
    }
    
    # Check ArgoCD applications
    Write-Host "`n[4] Checking ArgoCD applications..." -ForegroundColor Yellow
    $apps = kubectl get applications -n argocd -o json | ConvertFrom-Json
    $envApps = $apps.items | Where-Object { 
        $_.metadata.name -like "*-$env" -or 
        ($env -eq "dev" -and $_.metadata.name -like "*-dev" -and $_.metadata.name -notlike "*-staging" -and $_.metadata.name -notlike "*-prod")
    }
    
    if ($envApps) {
        Write-Host "  Found $($envApps.Count) applications for $env environment" -ForegroundColor Green
        foreach ($app in $envApps) {
            $name = $app.metadata.name
            $syncStatus = $app.status.sync.status
            $healthStatus = $app.status.health.status
            $syncColor = if ($syncStatus -eq "Synced") { "Green" } else { "Yellow" }
            $healthColor = if ($healthStatus -eq "Healthy") { "Green" } else { "Yellow" }
            Write-Host "    $name : Sync=$syncStatus, Health=$healthStatus" -ForegroundColor $(if ($syncStatus -eq "Synced" -and $healthStatus -eq "Healthy") { "Green" } else { "Yellow" })
        }
    } else {
        Write-Host "  [WARN] No ArgoCD applications found for $env environment" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "[OK] All basic checks passed!" -ForegroundColor Green
} else {
    Write-Host "[WARN] Some checks failed. Please review the output above." -ForegroundColor Yellow
}

Write-Host "`nTo view detailed status:" -ForegroundColor Cyan
Write-Host "  kubectl get applications -n argocd" -ForegroundColor Gray
Write-Host "  kubectl get pods -A | Select-String eshelf" -ForegroundColor Gray
Write-Host "  kubectl get services -A | Select-String eshelf" -ForegroundColor Gray

