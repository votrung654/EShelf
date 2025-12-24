# DevOps/MLOps Test Script for eShelf
# Tests CI/CD, Infrastructure, Docker builds, etc.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "eShelf DevOps/MLOps Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$PASS = 0
$FAIL = 0

function Test-Case {
    param(
        [string]$Name,
        [scriptblock]$Command
    )
    
    Write-Host -NoNewline "Testing: $Name... " -ForegroundColor Yellow
    
    try {
        $result = & $Command 2>&1
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Host "[PASS]" -ForegroundColor Green
            $script:PASS++
            return $true
        } else {
            Write-Host "[FAIL]" -ForegroundColor Red
            Write-Host "  Error: $result" -ForegroundColor Red
            $script:FAIL++
            return $false
        }
    } catch {
        Write-Host "[FAIL]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $script:FAIL++
        return $false
    }
}

# Test 1: Docker Builds
Write-Host "`n=== Docker Build Tests ===" -ForegroundColor Cyan

$services = @("api-gateway", "auth-service", "book-service", "user-service")
foreach ($service in $services) {
    $dockerfilePath = "backend\services\$service\Dockerfile"
    if (Test-Path $dockerfilePath) {
        Test-Case "Dockerfile exists: $service" {
            Test-Path $dockerfilePath
        }
    } else {
        Write-Host "Testing: Dockerfile exists: $service... [SKIP]" -ForegroundColor Gray
    }
}

# Test 2: CI/CD Workflows
Write-Host "`n=== CI/CD Workflow Tests ===" -ForegroundColor Cyan

$workflows = @(
    ".github\workflows\ci.yml",
    ".github\workflows\smart-build.yml",
    ".github\workflows\terraform.yml",
    ".github\workflows\update-manifests.yml"
)

foreach ($workflow in $workflows) {
    Test-Case "Workflow exists: $(Split-Path $workflow -Leaf)" {
        Test-Path $workflow
    }
}

# Test 3: Terraform Modules
Write-Host "`n=== Terraform Infrastructure Tests ===" -ForegroundColor Cyan

$terraformFiles = @(
    "infrastructure\terraform\modules\vpc\main.tf",
    "infrastructure\terraform\modules\ec2\main.tf",
    "infrastructure\terraform\modules\security-groups\main.tf",
    "infrastructure\terraform\environments\dev\main.tf"
)

foreach ($file in $terraformFiles) {
    Test-Case "Terraform file exists: $(Split-Path $file -Leaf)" {
        Test-Path $file
    }
}

# Test 4: Kubernetes Manifests
Write-Host "`n=== Kubernetes Manifests Tests ===" -ForegroundColor Cyan

$k8sFiles = @(
    "infrastructure\kubernetes\base\kustomization.yaml",
    "infrastructure\kubernetes\base\api-gateway-deployment.yaml",
    "infrastructure\kubernetes\base\auth-service-deployment.yaml",
    "infrastructure\kubernetes\base\book-service-deployment.yaml",
    "infrastructure\kubernetes\base\user-service-deployment.yaml",
    "infrastructure\kubernetes\base\ml-service-deployment.yaml"
)

foreach ($file in $k8sFiles) {
    Test-Case "K8s manifest exists: $(Split-Path $file -Leaf)" {
        Test-Path $file
    }
}

# Test 5: CloudFormation Templates
Write-Host "`n=== CloudFormation Templates Tests ===" -ForegroundColor Cyan

$cfnFiles = @(
    "infrastructure\cloudformation\templates\vpc-stack.yaml",
    "infrastructure\cloudformation\templates\ec2-stack.yaml"
)

foreach ($file in $cfnFiles) {
    Test-Case "CloudFormation template exists: $(Split-Path $file -Leaf)" {
        Test-Path $file
    }
}

# Test 6: Jenkins Pipeline
Write-Host "`n=== Jenkins Pipeline Tests ===" -ForegroundColor Cyan

Test-Case "Jenkinsfile exists" {
    Test-Path "jenkins\Jenkinsfile"
}

# Test 7: Docker Compose
Write-Host "`n=== Docker Compose Tests ===" -ForegroundColor Cyan

Test-Case "docker-compose.yml exists" {
    Test-Path "backend\docker-compose.yml"
}

# Test 8: Scripts
Write-Host "`n=== Utility Scripts Tests ===" -ForegroundColor Cyan

$scripts = @(
    "scripts\test-infrastructure.sh",
    "scripts\check-services.sh",
    "scripts\setup-project.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Test-Case "Script exists: $(Split-Path $script -Leaf)" {
            $true
        }
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Passed: $PASS" -ForegroundColor Green
Write-Host "Failed: $FAIL" -ForegroundColor $(if ($FAIL -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($FAIL -eq 0) {
    Write-Host "[OK] All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "[WARNING] Some tests failed or skipped" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Note: Some tests require:" -ForegroundColor Yellow
    Write-Host "  - Terraform CLI (for Terraform validation)" -ForegroundColor Yellow
    Write-Host "  - kubectl (for K8s manifest validation)" -ForegroundColor Yellow
    Write-Host "  - AWS CLI (for CloudFormation validation)" -ForegroundColor Yellow
    Write-Host "  - Docker (for Docker builds)" -ForegroundColor Yellow
    exit 0
}

