# Script to refresh PATH in current PowerShell session

Write-Host "Refreshing PATH..." -ForegroundColor Cyan

# Get current PATH from environment
$machinePath = [System.Environment]::GetEnvironmentVariable('Path','Machine')
$userPath = [System.Environment]::GetEnvironmentVariable('Path','User')

# Combine and set
$env:Path = "$machinePath;$userPath"

Write-Host "PATH refreshed!" -ForegroundColor Green
Write-Host ""

# Test AWS CLI
Write-Host "Testing AWS CLI..." -ForegroundColor Yellow
try {
    $awsVersion = aws --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  AWS CLI: $awsVersion" -ForegroundColor Green
    } else {
        throw "AWS CLI not found"
    }
} catch {
    Write-Host "  AWS CLI: Not found in PATH" -ForegroundColor Red
    Write-Host "  Location: C:\Program Files\Amazon\AWSCLIV2\aws.exe" -ForegroundColor Gray
    Write-Host "  Try: Restart PowerShell or use full path" -ForegroundColor Yellow
}

# Test Terraform
Write-Host "Testing Terraform..." -ForegroundColor Yellow
try {
    $tfVersion = terraform version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Terraform: $tfVersion" -ForegroundColor Green
    } else {
        throw "Terraform not found"
    }
} catch {
    Write-Host "  Terraform: Not found in PATH" -ForegroundColor Red
    Write-Host "  Location: C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe" -ForegroundColor Gray
    Write-Host "  Try: Restart PowerShell or use full path" -ForegroundColor Yellow
}

# Test kubectl
Write-Host "Testing kubectl..." -ForegroundColor Yellow
try {
    $kubectlVersion = kubectl version --client 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  kubectl: $kubectlVersion" -ForegroundColor Green
    } else {
        throw "kubectl not found"
    }
} catch {
    Write-Host "  kubectl: Not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "If tools still not found, restart PowerShell or run:" -ForegroundColor Cyan
Write-Host "  . .\scripts\refresh-path.ps1" -ForegroundColor White



