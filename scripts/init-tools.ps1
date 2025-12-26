# Script to initialize AWS CLI and Terraform in current PowerShell session
# Run this in your PowerShell: . .\scripts\init-tools.ps1

Write-Host "Initializing tools for current session..." -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$machinePath = [System.Environment]::GetEnvironmentVariable('Path','Machine')
$userPath = [System.Environment]::GetEnvironmentVariable('Path','User')
$env:Path = "$machinePath;$userPath"

# Add AWS CLI to PATH if not already there
$awsPath = "C:\Program Files\Amazon\AWSCLIV2"
if ($env:Path -notlike "*$awsPath*") {
    $env:Path += ";$awsPath"
    Write-Host "  Added AWS CLI to PATH" -ForegroundColor Green
}

# Add Terraform to PATH if not already there
$tfPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe"
if ($env:Path -notlike "*$tfPath*") {
    $env:Path += ";$tfPath"
    Write-Host "  Added Terraform to PATH" -ForegroundColor Green
}

# Create aliases as backup
$awsExe = "$awsPath\aws.exe"
$tfExe = "$tfPath\terraform.exe"

if (Test-Path $awsExe) {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Set-Alias -Name aws -Value $awsExe -Scope Global -ErrorAction SilentlyContinue
        Write-Host "  Created alias: aws" -ForegroundColor Green
    }
}

if (Test-Path $tfExe) {
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Set-Alias -Name terraform -Value $tfExe -Scope Global -ErrorAction SilentlyContinue
        Write-Host "  Created alias: terraform" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Testing tools..." -ForegroundColor Cyan

# Test AWS CLI
try {
    $awsVersion = aws --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  AWS CLI: $awsVersion" -ForegroundColor Green
    } else {
        throw "Failed"
    }
} catch {
    Write-Host "  AWS CLI: Not found (try: & '$awsExe' --version)" -ForegroundColor Red
}

# Test Terraform
try {
    $tfVersion = terraform version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Terraform: $tfVersion" -ForegroundColor Green
    } else {
        throw "Failed"
    }
} catch {
    Write-Host "  Terraform: Not found (try: & '$tfExe' version)" -ForegroundColor Red
}

# Test kubectl
try {
    $kubectlVersion = kubectl version --client 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  kubectl: $kubectlVersion" -ForegroundColor Green
    } else {
        throw "Failed"
    }
} catch {
    Write-Host "  kubectl: Not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Done! Tools are ready to use in this session." -ForegroundColor Green
Write-Host ""
Write-Host "Note: To use in new sessions, either:" -ForegroundColor Yellow
Write-Host "  1. Run this script again: . .\scripts\init-tools.ps1" -ForegroundColor White
Write-Host "  2. Or restart PowerShell (PATH is already saved)" -ForegroundColor White



