# Create aliases for AWS CLI and Terraform if not in PATH

Write-Host "Setting up aliases..." -ForegroundColor Cyan

# AWS CLI alias
$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (Test-Path $awsPath) {
    if (-not (Get-Alias aws -ErrorAction SilentlyContinue)) {
        Set-Alias -Name aws -Value $awsPath -Scope Global
        Write-Host "  Created alias: aws -> $awsPath" -ForegroundColor Green
    } else {
        Write-Host "  Alias 'aws' already exists" -ForegroundColor Yellow
    }
} else {
    Write-Host "  AWS CLI not found at: $awsPath" -ForegroundColor Red
}

# Terraform alias
$tfPath = "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe"
if (Test-Path $tfPath) {
    if (-not (Get-Alias terraform -ErrorAction SilentlyContinue)) {
        Set-Alias -Name terraform -Value $tfPath -Scope Global
        Write-Host "  Created alias: terraform -> $tfPath" -ForegroundColor Green
    } else {
        Write-Host "  Alias 'terraform' already exists" -ForegroundColor Yellow
    }
} else {
    Write-Host "  Terraform not found at: $tfPath" -ForegroundColor Red
}

Write-Host ""
Write-Host "Testing aliases..." -ForegroundColor Cyan

# Test
try {
    $awsVersion = aws --version 2>&1
    Write-Host "  AWS CLI: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "  AWS CLI: Failed" -ForegroundColor Red
}

try {
    $tfVersion = terraform version 2>&1 | Select-Object -First 1
    Write-Host "  Terraform: $tfVersion" -ForegroundColor Green
} catch {
    Write-Host "  Terraform: Failed" -ForegroundColor Red
}

Write-Host ""
Write-Host "Aliases are set for this session only." -ForegroundColor Yellow
Write-Host "To make permanent, add to your PowerShell profile:" -ForegroundColor Yellow
Write-Host "  notepad $PROFILE" -ForegroundColor White



