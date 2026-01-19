# Test script for Kubernetes environments (dev, staging, prod)
# Usage: .\scripts\test-environments.ps1 [dev|staging|prod]

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "prod", "all")]
    [string]$Environment = "all"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Kubernetes Environments" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Test-Environment {
    param(
        [string]$EnvName,
        [string]$Namespace,
        [string]$OverlayPath
    )
    
    Write-Host "Testing $EnvName environment..." -ForegroundColor Yellow
    Write-Host "Namespace: $Namespace" -ForegroundColor Gray
    Write-Host "Overlay: $OverlayPath" -ForegroundColor Gray
    Write-Host ""
    
    # Check if kubectl is available
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Host "ERROR: kubectl not found. Please install kubectl first." -ForegroundColor Red
        return $false
    }
    
    # Check if kustomize is available
    if (-not (Get-Command kustomize -ErrorAction SilentlyContinue)) {
        Write-Host "WARNING: kustomize not found. Installing via kubectl plugin..." -ForegroundColor Yellow
        # kustomize is included in kubectl >= 1.14
    }
    
    # Validate kustomization.yaml
    Write-Host "  [1/4] Validating kustomization.yaml..." -ForegroundColor Cyan
    try {
        $kustomizeOutput = kubectl kustomize $OverlayPath 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ❌ FAILED: kustomize validation failed" -ForegroundColor Red
            Write-Host $kustomizeOutput -ForegroundColor Red
            return $false
        }
        Write-Host "  ✅ PASSED: kustomization.yaml is valid" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    # Check namespace exists (if cluster is accessible)
    Write-Host "  [2/4] Checking namespace..." -ForegroundColor Cyan
    try {
        $nsCheck = kubectl get namespace $Namespace 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ PASSED: Namespace exists" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  WARNING: Namespace does not exist (will be created on apply)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ⚠️  WARNING: Cannot connect to cluster" -ForegroundColor Yellow
    }
    
    # Check required resources
    Write-Host "  [3/4] Checking required resources..." -ForegroundColor Cyan
    $requiredResources = @("frontend", "api-gateway", "auth-service", "book-service", "user-service", "ml-service")
    $allFound = $true
    
    foreach ($resource in $requiredResources) {
        $found = $kustomizeOutput | Select-String -Pattern "kind: Deployment" -Context 0,5 | Select-String -Pattern "name: $resource"
        if ($found) {
            Write-Host "    ✅ $resource" -ForegroundColor Green
        } else {
            Write-Host "    ❌ $resource (missing)" -ForegroundColor Red
            $allFound = $false
        }
    }
    
    if (-not $allFound) {
        Write-Host "  ❌ FAILED: Some required resources are missing" -ForegroundColor Red
        return $false
    }
    Write-Host "  ✅ PASSED: All required resources found" -ForegroundColor Green
    
    # Check ingress configuration
    Write-Host "  [4/4] Checking ingress configuration..." -ForegroundColor Cyan
    $ingressFound = $kustomizeOutput | Select-String -Pattern "kind: Ingress"
    if ($ingressFound) {
        Write-Host "  ✅ PASSED: Ingress configuration found" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  WARNING: Ingress configuration not found" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "✅ $EnvName environment validation PASSED" -ForegroundColor Green
    Write-Host ""
    
    return $true
}

# Test environments
$results = @{}

if ($Environment -eq "all" -or $Environment -eq "dev") {
    $results["dev"] = Test-Environment -EnvName "dev" -Namespace "eshelf-dev" -OverlayPath "infrastructure/kubernetes/overlays/dev"
}

if ($Environment -eq "all" -or $Environment -eq "staging") {
    $results["staging"] = Test-Environment -EnvName "staging" -Namespace "eshelf-staging" -OverlayPath "infrastructure/kubernetes/overlays/staging"
}

if ($Environment -eq "all" -or $Environment -eq "prod") {
    $results["prod"] = Test-Environment -EnvName "prod" -Namespace "eshelf-prod" -OverlayPath "infrastructure/kubernetes/overlays/prod"
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$allPassed = $true
foreach ($env in $results.Keys) {
    if ($results[$env]) {
        Write-Host "$env : ✅ PASSED" -ForegroundColor Green
    } else {
        Write-Host "$env : ❌ FAILED" -ForegroundColor Red
        $allPassed = $false
    }
}

Write-Host ""

if ($allPassed) {
    Write-Host "All environments validated successfully! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "To deploy an environment, run:" -ForegroundColor Cyan
    Write-Host "  kubectl apply -k infrastructure/kubernetes/overlays/dev" -ForegroundColor White
    Write-Host "  kubectl apply -k infrastructure/kubernetes/overlays/staging" -ForegroundColor White
    Write-Host "  kubectl apply -k infrastructure/kubernetes/overlays/prod" -ForegroundColor White
    exit 0
} else {
    Write-Host "Some environments failed validation. Please fix the issues above." -ForegroundColor Red
    exit 1
}






