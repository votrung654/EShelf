# eShelf Lab 1 & 2 Verification Script
# This script verifies all requirements for Lab 1 (Infrastructure) and Lab 2 (CI/CD)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "eShelf Lab 1 & 2 Verification Report" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$results = @{}

# Check 1: Terraform Validation
Write-Host "[1/4] Checking Terraform..." -ForegroundColor Yellow
$terraformPath = "infrastructure/terraform/environments/dev"
if (Test-Path $terraformPath) {
    Push-Location $terraformPath
    try {
        $terraformValidate = terraform validate 2>&1
        if ($LASTEXITCODE -eq 0) {
            $results["Terraform"] = "PASS"
            Write-Host "  [OK] Terraform validation: PASS" -ForegroundColor Green
        } else {
            $results["Terraform"] = "FAIL"
            Write-Host "  [X] Terraform validation: FAIL" -ForegroundColor Red
            Write-Host "    Error: $terraformValidate" -ForegroundColor Red
        }
    } catch {
        $results["Terraform"] = "FAIL"
        Write-Host "  [X] Terraform validation: FAIL (Error: $_)" -ForegroundColor Red
    } finally {
        Pop-Location
    }
} else {
    $results["Terraform"] = "FAIL"
    Write-Host "  [X] Terraform directory not found: $terraformPath" -ForegroundColor Red
}

Write-Host ""

# Check 2: CloudFormation Templates
Write-Host "[2/4] Checking CloudFormation..." -ForegroundColor Yellow
$cfnVpcPath = "infrastructure/cloudformation/templates/vpc-stack.yaml"
if (Test-Path $cfnVpcPath) {
    $results["CloudFormation"] = "PASS"
    Write-Host "  [OK] CloudFormation VPC template: PASS" -ForegroundColor Green
} else {
    $results["CloudFormation"] = "FAIL"
    Write-Host "  [X] CloudFormation VPC template not found: $cfnVpcPath" -ForegroundColor Red
}

Write-Host ""

# Check 3: Taskcat Configuration
Write-Host "[3/4] Checking Taskcat..." -ForegroundColor Yellow
$taskcatPath = ".taskcat.yml"
if (Test-Path $taskcatPath) {
    $taskcatContent = Get-Content $taskcatPath -Raw
    if ($taskcatContent -match "ap-southeast-2") {
        $results["Taskcat"] = "PASS"
        Write-Host "  [OK] Taskcat configuration: PASS" -ForegroundColor Green
    } else {
        $results["Taskcat"] = "FAIL"
        Write-Host "  [X] Taskcat configuration missing ap-southeast-2 region" -ForegroundColor Red
    }
} else {
    $results["Taskcat"] = "FAIL"
    Write-Host "  [X] Taskcat configuration not found: $taskcatPath" -ForegroundColor Red
}

Write-Host ""

# Check 4: Jenkins Pipeline (Trivy & SonarQube)
Write-Host "[4/4] Checking Jenkins Pipeline..." -ForegroundColor Yellow
$jenkinsfilePath = "Jenkinsfile"
if (Test-Path $jenkinsfilePath) {
    $jenkinsfileContent = Get-Content $jenkinsfilePath -Raw
    $hasTrivy = $jenkinsfileContent -match "Trivy|trivy"
    $hasSonarQube = $jenkinsfileContent -match "SonarQube|sonarqube|SonarQubeScanner"
    
    if ($hasTrivy -and $hasSonarQube) {
        $results["Jenkins"] = "PASS"
        Write-Host "  [OK] Jenkinsfile contains Trivy: PASS" -ForegroundColor Green
        Write-Host "  [OK] Jenkinsfile contains SonarQube: PASS" -ForegroundColor Green
    } else {
        $results["Jenkins"] = "FAIL"
        if (-not $hasTrivy) {
            Write-Host "  [X] Jenkinsfile missing Trivy: FAIL" -ForegroundColor Red
        }
        if (-not $hasSonarQube) {
            Write-Host "  [X] Jenkinsfile missing SonarQube: FAIL" -ForegroundColor Red
        }
    }
} else {
    $results["Jenkins"] = "FAIL"
    Write-Host "  [X] Jenkinsfile not found: $jenkinsfilePath" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY REPORT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

foreach ($check in $results.Keys) {
    $status = $results[$check]
    if ($status -eq "PASS") {
        Write-Host "$check : $status" -ForegroundColor Green
    } else {
        Write-Host "$check : $status" -ForegroundColor Red
    }
}

$passCount = ($results.Values | Where-Object { $_ -eq "PASS" }).Count
$totalCount = $results.Count
$passRate = [math]::Round(($passCount / $totalCount) * 100, 1)

Write-Host ""
$passRateText = "$passRate percent"
Write-Host "Pass Rate: $passCount/$totalCount ($passRateText)" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })

if ($passRate -eq 100) {
    Write-Host ""
    Write-Host "[OK] All Lab 1 & 2 requirements are met!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "[X] Some requirements are missing. Please fix the issues above." -ForegroundColor Red
    exit 1
}
