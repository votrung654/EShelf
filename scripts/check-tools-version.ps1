# Script to check all tools versions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking Tools Versions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

# AWS CLI
Write-Host "AWS CLI:" -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    if (Test-Path $awsPath) {
        $awsVersion = & $awsPath --version 2>&1 | Select-Object -First 1
        Write-Host "  $awsVersion" -ForegroundColor Green
        Write-Host "  Location: $awsPath" -ForegroundColor Gray
    } else {
        Write-Host "  Not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host ""

# Terraform
Write-Host "Terraform:" -ForegroundColor Yellow
try {
    $tfPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe"
    if (Test-Path $tfPath) {
        $tfVersion = & $tfPath version 2>&1 | Select-Object -First 1
        Write-Host "  $tfVersion" -ForegroundColor Green
        Write-Host "  Location: $tfPath" -ForegroundColor Gray
    } else {
        Write-Host "  Not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host ""

# kubectl
Write-Host "kubectl:" -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client 2>&1 | Select-Object -First 1
    Write-Host "  $kubectlVersion" -ForegroundColor Green
} catch {
    Write-Host "  Not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if tools are in PATH
Write-Host "PATH Status:" -ForegroundColor Yellow
$awsInPath = Get-Command aws -ErrorAction SilentlyContinue
$tfInPath = Get-Command terraform -ErrorAction SilentlyContinue
$kubectlInPath = Get-Command kubectl -ErrorAction SilentlyContinue

if ($awsInPath) {
    Write-Host "  AWS CLI: In PATH" -ForegroundColor Green
} else {
    Write-Host "  AWS CLI: Not in PATH (use full path or restart PowerShell)" -ForegroundColor Yellow
}

if ($tfInPath) {
    Write-Host "  Terraform: In PATH" -ForegroundColor Green
} else {
    Write-Host "  Terraform: Not in PATH (use full path or restart PowerShell)" -ForegroundColor Yellow
}

if ($kubectlInPath) {
    Write-Host "  kubectl: In PATH" -ForegroundColor Green
} else {
    Write-Host "  kubectl: Not in PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Note: If tools are not in PATH, restart PowerShell or use full paths" -ForegroundColor Cyan



