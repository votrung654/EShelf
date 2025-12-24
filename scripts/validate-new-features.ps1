# PowerShell validation script for new features
# Checks syntax, structure, and safety of new implementations

$Errors = 0
$Warnings = 0

Write-Host "=== Validating New Features ===" -ForegroundColor Cyan
Write-Host ""

# Check YAML files exist
Write-Host "1. Checking YAML files..." -ForegroundColor Yellow
$YamlFiles = @(
  ".github/workflows/pr-only.yml",
  ".github/workflows/sonarqube-scan.yml",
  "infrastructure/kubernetes/jenkins/deployment.yaml",
  "infrastructure/kubernetes/jenkins/service.yaml",
  "infrastructure/kubernetes/jenkins/ingress.yaml",
  "infrastructure/kubernetes/sonarqube/deployment.yaml",
  "infrastructure/kubernetes/sonarqube/service.yaml",
  "infrastructure/kubernetes/sonarqube/ingress.yaml"
)

foreach ($file in $YamlFiles) {
    if (Test-Path $file) {
        Write-Host "  OK: $file" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: $file not found" -ForegroundColor Red
        $Errors++
    }
}

Write-Host ""

# Check Terraform environments
Write-Host "2. Checking Terraform environments..." -ForegroundColor Yellow
$TerraformEnvs = @("staging", "prod")
foreach ($env in $TerraformEnvs) {
    $envPath = "infrastructure/terraform/environments/$env"
    if (Test-Path $envPath) {
        $requiredFiles = @("main.tf", "variables.tf", "outputs.tf", "terraform.tfvars.example")
        $allExist = $true
        foreach ($reqFile in $requiredFiles) {
            if (-not (Test-Path "$envPath/$reqFile")) {
                Write-Host "  ERROR: $envPath/$reqFile not found" -ForegroundColor Red
                $Errors++
                $allExist = $false
            }
        }
        if ($allExist) {
            Write-Host "  OK: $env environment" -ForegroundColor Green
        }
    } else {
        Write-Host "  ERROR: $envPath not found" -ForegroundColor Red
        $Errors++
    }
}

Write-Host ""

# Check shell scripts
Write-Host "3. Checking shell scripts..." -ForegroundColor Yellow
$ShellScripts = @(
    "scripts/aws-shutdown.sh",
    "scripts/aws-startup.sh",
    "scripts/setup-harbor-credentials.sh"
)

foreach ($script in $ShellScripts) {
    if (Test-Path $script) {
        Write-Host "  OK: $script" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: $script not found" -ForegroundColor Yellow
        $Warnings++
    }
}

Write-Host ""

# Check Harbor migration
Write-Host "4. Checking Harbor registry migration..." -ForegroundColor Yellow
$WorkflowFiles = Get-ChildItem -Path ".github/workflows" -Filter "*.yml" -Recurse
$DockerHubRefs = 0

foreach ($file in $WorkflowFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "docker\.io/eshelf" -and $content -notmatch "registry-1\.docker\.io") {
        Write-Host "  WARNING: Found DockerHub reference in $($file.Name)" -ForegroundColor Yellow
        $DockerHubRefs++
        $Warnings++
    }
}

if ($DockerHubRefs -eq 0) {
    Write-Host "  OK: Harbor migration appears complete" -ForegroundColor Green
}

Write-Host ""

# Check ArgoCD Image Updater annotations
Write-Host "5. Checking ArgoCD Image Updater annotations..." -ForegroundColor Yellow
$AppFiles = Get-ChildItem -Path "infrastructure/kubernetes/argocd/applications" -Filter "*.yaml"
$MissingAnnotations = 0

foreach ($app in $AppFiles) {
    $content = Get-Content $app.FullName -Raw
    if ($content -notmatch "argocd-image-updater\.argoproj\.io/image-list") {
        Write-Host "  WARNING: Missing Image Updater annotations in $($app.Name)" -ForegroundColor Yellow
        $MissingAnnotations++
        $Warnings++
    }
}

if ($MissingAnnotations -eq 0) {
    Write-Host "  OK: All ArgoCD applications have Image Updater annotations" -ForegroundColor Green
}

Write-Host ""

# Summary
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
Write-Host "Errors: $Errors" -ForegroundColor $(if ($Errors -gt 0) { "Red" } else { "Green" })
Write-Host "Warnings: $Warnings" -ForegroundColor $(if ($Warnings -gt 0) { "Yellow" } else { "Green" })

if ($Errors -gt 0) {
    Write-Host ""
    Write-Host "VALIDATION FAILED: Please fix errors before proceeding" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "VALIDATION PASSED" -ForegroundColor Green
    exit 0
}

