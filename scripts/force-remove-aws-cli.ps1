# Script to force remove AWS CLI with admin privileges
# Run this script as Administrator
# Usage: Right-click PowerShell -> Run as Administrator -> .\scripts\force-remove-aws-cli.ps1

#Requires -RunAsAdministrator

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Force Remove AWS CLI (Admin Mode)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[ERROR] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "To run as Administrator:" -ForegroundColor Yellow
    Write-Host "  1. Right-click PowerShell" -ForegroundColor Gray
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Gray
    Write-Host "  3. Navigate to project directory" -ForegroundColor Gray
    Write-Host "  4. Run: .\scripts\force-remove-aws-cli.ps1" -ForegroundColor Gray
    exit 1
}

Write-Host "[OK] Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Step 1: Kill all AWS processes
Write-Host "[Step 1] Killing all AWS CLI processes..." -ForegroundColor Yellow
$awsProcesses = Get-Process -Name "aws" -ErrorAction SilentlyContinue
if ($awsProcesses) {
    Write-Host "  [INFO] Found $($awsProcesses.Count) process(es), killing..." -ForegroundColor Gray
    $awsProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "  [OK] Killed all AWS processes" -ForegroundColor Green
} else {
    Write-Host "  [OK] No AWS processes running" -ForegroundColor Green
}

# Step 2: Uninstall via winget
Write-Host "`n[Step 2] Uninstalling AWS CLI via winget..." -ForegroundColor Yellow
$wingetFound = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetFound) {
    Write-Host "  [INFO] Running winget uninstall..." -ForegroundColor Gray
    winget uninstall Amazon.AWSCLI --silent 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    Write-Host "  [OK] Winget uninstall completed" -ForegroundColor Green
} else {
    Write-Host "  [WARN] winget not found, skipping..." -ForegroundColor Yellow
}

# Step 3: Force remove all AWS CLI directories
Write-Host "`n[Step 3] Force removing AWS CLI directories..." -ForegroundColor Yellow
$awsDirs = @(
    "C:\Program Files\Amazon\AWSCLIV2",
    "C:\Program Files (x86)\Amazon\AWSCLIV2",
    "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2",
    "$env:APPDATA\Amazon\AWSCLI"
)

foreach ($dir in $awsDirs) {
    if (Test-Path $dir) {
        Write-Host "  [INFO] Removing: $dir" -ForegroundColor Gray
        try {
            # Take ownership first
            Write-Host "    [INFO] Taking ownership..." -ForegroundColor Gray
            $takeownResult = Start-Process takeown -ArgumentList "/F `"$dir`" /R /D Y" -Wait -PassThru -NoNewWindow
            Start-Sleep -Seconds 1
            
            # Grant full control to administrators
            Write-Host "    [INFO] Granting permissions..." -ForegroundColor Gray
            $icaclsResult = Start-Process icacls -ArgumentList "`"$dir`" /grant administrators:F /T" -Wait -PassThru -NoNewWindow
            Start-Sleep -Seconds 1
            
            # Remove directory
            Write-Host "    [INFO] Deleting directory..." -ForegroundColor Gray
            Remove-Item $dir -Recurse -Force -ErrorAction Stop
            Write-Host "    [OK] Removed successfully" -ForegroundColor Green
        } catch {
            Write-Host "    [ERROR] Could not remove: $_" -ForegroundColor Red
            Write-Host "    [INFO] Trying alternative method..." -ForegroundColor Gray
            
            # Alternative: Use robocopy to delete
            try {
                $emptyDir = "$env:TEMP\empty_$(Get-Random)"
                New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
                Start-Process robocopy -ArgumentList "`"$emptyDir`" `"$dir`" /MIR /R:0 /W:0" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                Remove-Item $emptyDir -Force -ErrorAction SilentlyContinue
                Remove-Item $dir -Force -ErrorAction SilentlyContinue
                Write-Host "    [OK] Removed using robocopy method" -ForegroundColor Green
            } catch {
                Write-Host "    [ERROR] All methods failed. Manual deletion required:" -ForegroundColor Red
                Write-Host "      $dir" -ForegroundColor Gray
            }
        }
    }
}

# Step 4: Clean up PATH
Write-Host "`n[Step 4] Cleaning up PATH..." -ForegroundColor Yellow
$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$currentMachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")

$pathsToRemove = @(
    "C:\Program Files\Amazon\AWSCLIV2",
    "C:\Program Files (x86)\Amazon\AWSCLIV2",
    "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2"
)

# Clean user PATH
$newUserPath = ($currentUserPath -split ';' | Where-Object { 
    $path = $_.Trim()
    $shouldKeep = $true
    foreach ($removePath in $pathsToRemove) {
        if ($path -eq $removePath -or $path -like "*$removePath*") {
            $shouldKeep = $false
            break
        }
    }
    $shouldKeep
}) -join ';'

if ($newUserPath -ne $currentUserPath) {
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "  [OK] Cleaned user PATH" -ForegroundColor Green
}

# Clean machine PATH (requires admin)
$newMachinePath = ($currentMachinePath -split ';' | Where-Object { 
    $path = $_.Trim()
    $shouldKeep = $true
    foreach ($removePath in $pathsToRemove) {
        if ($path -eq $removePath -or $path -like "*$removePath*") {
            $shouldKeep = $false
            break
        }
    }
    $shouldKeep
}) -join ';'

if ($newMachinePath -ne $currentMachinePath) {
    [Environment]::SetEnvironmentVariable("Path", $newMachinePath, "Machine")
    Write-Host "  [OK] Cleaned machine PATH" -ForegroundColor Green
}

# Step 5: Remove from registry (if exists)
Write-Host "`n[Step 5] Cleaning registry..." -ForegroundColor Yellow
$regPaths = @(
    "HKLM:\SOFTWARE\Amazon\AWSCLI",
    "HKLM:\SOFTWARE\WOW6432Node\Amazon\AWSCLI",
    "HKCU:\SOFTWARE\Amazon\AWSCLI"
)

foreach ($regPath in $regPaths) {
    if (Test-Path $regPath) {
        try {
            Remove-Item $regPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Removed registry key: $regPath" -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Could not remove registry key: $regPath" -ForegroundColor Yellow
        }
    }
}

# Step 6: Remove shortcuts
Write-Host "`n[Step 6] Removing shortcuts..." -ForegroundColor Yellow
$shortcutPaths = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Amazon Web Services",
    "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\Amazon Web Services"
)

foreach ($shortcutPath in $shortcutPaths) {
    if (Test-Path $shortcutPath) {
        try {
            Remove-Item $shortcutPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Removed shortcuts: $shortcutPath" -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Could not remove shortcuts: $shortcutPath" -ForegroundColor Yellow
        }
    }
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Force Removal Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[OK] AWS CLI has been forcefully removed" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Restart PowerShell" -ForegroundColor Cyan
Write-Host "  2. Reinstall AWS CLI:" -ForegroundColor Cyan
Write-Host "     .\scripts\clean-reinstall-aws-cli.ps1" -ForegroundColor Gray
Write-Host ""

