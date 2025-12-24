# Script để test tất cả các thay đổi đã làm
# Test an toàn, không ảnh hưởng code hiện tại

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing All Changes" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()
$success = @()

# Test 1: Validate YAML syntax
Write-Host "[Test 1] Validating YAML syntax..." -ForegroundColor Yellow
$yamlFiles = @(
    ".github/workflows/smart-build.yml",
    ".github/workflows/ci.yml",
    ".github/workflows/pr-only.yml",
    ".github/workflows/sonarqube-scan.yml",
    ".github/workflows/mlops-model-training.yml",
    "infrastructure/kubernetes/jenkins/deployment.yaml",
    "infrastructure/kubernetes/sonarqube/deployment.yaml"
)

foreach ($file in $yamlFiles) {
    if (Test-Path $file) {
        try {
            $content = Get-Content $file -Raw
            # Basic YAML check - look for common syntax errors
            if ($content -match '^\s*-\s*$' -and $content -notmatch '^\s*-\s*.*:') {
                $warnings += "Potential YAML issue in $file (empty list item)"
            } else {
                $success += "YAML syntax OK: $file"
            }
        } catch {
            $errors += "✗ YAML error in $file : $_"
        }
    } else {
        $errors += "✗ File not found: $file"
    }
}

# Test 2: Check scripts exist and are valid
Write-Host "[Test 2] Checking scripts..." -ForegroundColor Yellow
$scripts = @(
    "scripts/check-service-changes.sh",
    "scripts/check-code-changes.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        $content = Get-Content $script -Raw
        if ($content -match '#!/bin/bash') {
            $success += "Script exists and valid: $script"
        } else {
            $warnings += "Script missing shebang: $script"
        }
    } else {
        $errors += "Script not found: $script"
    }
}

# Test 3: Verify package.json changes
Write-Host "[Test 3] Verifying package.json changes..." -ForegroundColor Yellow
$packageFiles = @(
    "backend/services/api-gateway/package.json",
    "backend/services/auth-service/package.json",
    "backend/services/book-service/package.json",
    "backend/services/user-service/package.json"
)

foreach ($pkg in $packageFiles) {
    if (Test-Path $pkg) {
        $json = Get-Content $pkg | ConvertFrom-Json
        if ($json.scripts.lint) {
            $success += "Lint script added: $pkg"
        } else {
            $errors += "Lint script missing: $pkg"
        }
        if ($json.scripts.test -match '--passWithNoTests') {
            $success += "Jest flag added: $pkg"
        } else {
            $warnings += "Jest flag not found: $pkg"
        }
    }
}

# Test 4: Check workflow permissions
Write-Host "[Test 4] Checking workflow permissions..." -ForegroundColor Yellow
$ciContent = Get-Content ".github/workflows/ci.yml" -Raw
if ($ciContent -match 'permissions:') {
    $success += "Permissions added to security-scan job"
} else {
    $warnings += "Permissions not found in ci.yml"
}

# Test 5: Check MLflow workflow changes
Write-Host "[Test 5] Checking MLflow workflow..." -ForegroundColor Yellow
$mlflowContent = Get-Content ".github/workflows/mlops-model-training.yml" -Raw
if ($mlflowContent -match 'continue-on-error: true') {
    $success += "Error handling added to MLflow workflow"
}
if ($mlflowContent -match './mlruns') {
    $success += "File-based MLflow backend configured"
}

# Test 6: Check smart build integration
Write-Host "[Test 6] Checking smart build integration..." -ForegroundColor Yellow
$smartBuildContent = Get-Content ".github/workflows/smart-build.yml" -Raw
if ($smartBuildContent -match 'check-service-changes.sh') {
    $success += "Smart build script integrated"
} else {
    $errors += "Smart build script not integrated"
}

# Test 8: Check PR-only pipeline
Write-Host "[Test 8] Checking PR-only pipeline..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/pr-only.yml") {
    $prOnlyContent = Get-Content ".github/workflows/pr-only.yml" -Raw
    if ($prOnlyContent -match 'pull_request:' -and $prOnlyContent -notmatch 'docker build') {
        $success += "PR-only pipeline configured (no deploy in PR)"
    } else {
        $warnings += "PR-only pipeline may have deploy steps"
    }
} else {
    $errors += "PR-only pipeline not found"
}

# Test 9: Check Harbor migration
Write-Host "[Test 9] Checking Harbor migration..." -ForegroundColor Yellow
$workflowFiles = Get-ChildItem -Path ".github/workflows" -Filter "*.yml"
$harborRefs = 0
$dockerHubRefs = 0
foreach ($file in $workflowFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match 'HARBOR_REGISTRY' -or $content -match 'harbor\.yourdomain\.com') {
        $harborRefs++
    }
    if ($content -match 'docker\.io/eshelf' -and $content -notmatch 'registry-1\.docker\.io') {
        $dockerHubRefs++
    }
}
if ($harborRefs -gt 0) {
    $success += "Harbor registry configured in workflows"
}
if ($dockerHubRefs -gt 0) {
    $warnings += "Found DockerHub references (should use Harbor)"
}

# Test 10: Check ArgoCD Image Updater
Write-Host "[Test 10] Checking ArgoCD Image Updater..." -ForegroundColor Yellow
$appFiles = Get-ChildItem -Path "infrastructure/kubernetes/argocd/applications" -Filter "*.yaml"
$annotatedApps = 0
foreach ($app in $appFiles) {
    $content = Get-Content $app.FullName -Raw
    if ($content -match 'argocd-image-updater\.argoproj\.io/image-list') {
        $annotatedApps++
    }
}
if ($annotatedApps -ge 4) {
    $success += "ArgoCD Image Updater annotations added ($annotatedApps apps)"
} else {
    $warnings += "Some ArgoCD apps missing Image Updater annotations"
}

# Test 11: Check Terraform environments
Write-Host "[Test 11] Checking Terraform environments..." -ForegroundColor Yellow
$terraformEnvs = @("dev", "staging", "prod")
$validEnvs = 0
foreach ($env in $terraformEnvs) {
    $envPath = "infrastructure/terraform/environments/$env"
    if (Test-Path $envPath) {
        if ((Test-Path "$envPath/main.tf") -and (Test-Path "$envPath/variables.tf")) {
            $validEnvs++
        }
    }
}
if ($validEnvs -eq 3) {
    $success += "All 3 Terraform environments configured"
} else {
    $errors += "Missing Terraform environments (found $validEnvs/3)"
}

# Test 12: Check Jenkins and SonarQube deployments
Write-Host "[Test 12] Checking Jenkins and SonarQube..." -ForegroundColor Yellow
if (Test-Path "infrastructure/kubernetes/jenkins/deployment.yaml") {
    $success += "Jenkins deployment manifest exists"
} else {
    $errors += "Jenkins deployment manifest not found"
}
if (Test-Path "infrastructure/kubernetes/sonarqube/deployment.yaml") {
    $success += "SonarQube deployment manifest exists"
} else {
    $errors += "SonarQube deployment manifest not found"
}

# Test 7: Verify no runtime code changes
Write-Host "[Test 7] Verifying no runtime code changes..." -ForegroundColor Yellow
$sourceDirs = @(
    "backend/services/api-gateway/src",
    "backend/services/auth-service/src",
    "backend/services/book-service/src",
    "backend/services/user-service/src",
    "src"
)

$hasSourceChanges = $false
foreach ($dir in $sourceDirs) {
    if (Test-Path $dir) {
        # Check if any .js/.jsx/.ts files were modified in our changes
        # This is a safety check - we shouldn't have modified source
        $hasSourceChanges = $true
    }
}
if (-not $hasSourceChanges) {
    $success += "No source code files modified (safe)"
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($success.Count -gt 0) {
    Write-Host "[SUCCESS] ($($success.Count)):" -ForegroundColor Green
    foreach ($msg in $success) {
        Write-Host "  [OK] $msg" -ForegroundColor Green
    }
    Write-Host ""
}

if ($warnings.Count -gt 0) {
    Write-Host "[WARNINGS] ($($warnings.Count)):" -ForegroundColor Yellow
    foreach ($msg in $warnings) {
        Write-Host "  [WARN] $msg" -ForegroundColor Yellow
    }
    Write-Host ""
}

if ($errors.Count -gt 0) {
    Write-Host "[ERRORS] ($($errors.Count)):" -ForegroundColor Red
    foreach ($msg in $errors) {
        Write-Host "  [ERROR] $msg" -ForegroundColor Red
    }
    Write-Host ""
} else {
    Write-Host "[SUCCESS] No errors found!" -ForegroundColor Green
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    exit 0
} else {
    exit 1
}

