# Helper script to run force-remove-aws-cli.ps1 as Administrator
# Usage: .\scripts\run-as-admin.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "AWS CLI Force Remove - Admin Helper" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if already admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "[OK] Already running as Administrator" -ForegroundColor Green
    Write-Host ""
    Write-Host "Running force-remove-aws-cli.ps1..." -ForegroundColor Yellow
    & "$PSScriptRoot\force-remove-aws-cli.ps1"
} else {
    Write-Host "[INFO] Need Administrator privileges" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Attempting to elevate privileges..." -ForegroundColor Cyan
    
    $scriptPath = Join-Path $PSScriptRoot "force-remove-aws-cli.ps1"
    $projectRoot = Split-Path $PSScriptRoot -Parent
    
    try {
        # Start new PowerShell process as admin
        Start-Process powershell.exe -Verb RunAs -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$scriptPath`""
        ) -WorkingDirectory $projectRoot
        
        Write-Host "[OK] Launched PowerShell as Administrator" -ForegroundColor Green
        Write-Host ""
        Write-Host "Please approve the UAC prompt if it appears" -ForegroundColor Yellow
        Write-Host "The script will run in a new window" -ForegroundColor Gray
    } catch {
        Write-Host "[ERROR] Could not elevate privileges: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual steps:" -ForegroundColor Yellow
        Write-Host "  1. Right-click PowerShell" -ForegroundColor Gray
        Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Gray
        Write-Host "  3. Run: cd D:\github-renewable\eShelf" -ForegroundColor Gray
        Write-Host "  4. Run: .\scripts\force-remove-aws-cli.ps1" -ForegroundColor Gray
    }
}

Write-Host ""

