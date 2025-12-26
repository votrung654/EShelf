# Script to reinstall AWS CLI to fix hanging issue
# Usage: .\scripts\reinstall-aws-cli.ps1

param(
    [switch]$UseMSI
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "AWS CLI Reinstallation" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Uninstall existing AWS CLI
Write-Host "[Step 1] Uninstalling existing AWS CLI..." -ForegroundColor Yellow

# Try winget uninstall
$wingetFound = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetFound) {
    Write-Host "  [INFO] Uninstalling via winget..." -ForegroundColor Gray
    winget uninstall Amazon.AWSCLI --silent 2>&1 | Out-Null
    Start-Sleep -Seconds 3
}

# Also try to remove manually if still exists
$awsPath = "C:\Program Files\Amazon\AWSCLIV2"
if (Test-Path $awsPath) {
    Write-Host "  [INFO] Removing remaining files..." -ForegroundColor Gray
    try {
        Remove-Item $awsPath -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] Removed AWS CLI directory" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Could not remove directory: $_" -ForegroundColor Yellow
        Write-Host "  [INFO] You may need to close any programs using AWS CLI" -ForegroundColor Gray
    }
}

# Step 2: Clean up PATH
Write-Host "`n[Step 2] Cleaning up PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")

$pathsToRemove = @(
    "C:\Program Files\Amazon\AWSCLIV2",
    "C:\Program Files (x86)\Amazon\AWSCLIV2",
    "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2"
)

$newUserPath = $currentPath
$newMachinePath = $machinePath

foreach ($path in $pathsToRemove) {
    $newUserPath = ($newUserPath -split ';' | Where-Object { $_ -ne $path }) -join ';'
    $newMachinePath = ($newMachinePath -split ';' | Where-Object { $_ -ne $path }) -join ';'
}

if ($newUserPath -ne $currentPath) {
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "  [OK] Cleaned user PATH" -ForegroundColor Green
}

# Step 3: Reinstall AWS CLI
Write-Host "`n[Step 3] Reinstalling AWS CLI..." -ForegroundColor Yellow

if ($UseMSI) {
    Write-Host "  [INFO] Using MSI installer method..." -ForegroundColor Gray
    Write-Host "  [INFO] Downloading AWS CLI MSI installer..." -ForegroundColor Gray
    
    $msiPath = "$env:TEMP\AWSCLIV2.msi"
    $msiUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    
    try {
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
        Write-Host "  [OK] Downloaded MSI installer" -ForegroundColor Green
        
        Write-Host "  [INFO] Installing AWS CLI (this may take a few minutes)..." -ForegroundColor Gray
        Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait -NoNewWindow
        Write-Host "  [OK] MSI installation completed" -ForegroundColor Green
        
        Remove-Item $msiPath -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  [ERROR] MSI installation failed: $_" -ForegroundColor Red
        Write-Host "  [INFO] Falling back to winget..." -ForegroundColor Yellow
        $UseMSI = $false
    }
}

if (-not $UseMSI) {
    if ($wingetFound) {
        Write-Host "  [INFO] Installing via winget..." -ForegroundColor Gray
        winget install Amazon.AWSCLI --silent --accept-package-agreements --accept-source-agreements
        Start-Sleep -Seconds 5
        Write-Host "  [OK] Winget installation completed" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] winget not found!" -ForegroundColor Red
        Write-Host "  [INFO] Please install AWS CLI manually:" -ForegroundColor Yellow
        Write-Host "    1. Download from: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor Gray
        Write-Host "    2. Run the installer" -ForegroundColor Gray
        exit 1
    }
}

# Step 4: Verify installation
Write-Host "`n[Step 4] Verifying installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (-not (Test-Path $awsPath)) {
    $awsPath = "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe"
}

if (Test-Path $awsPath) {
    Write-Host "  [OK] AWS CLI installed at: $awsPath" -ForegroundColor Green
    
    # Add to PATH
    $awsDir = Split-Path $awsPath -Parent
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$awsDir*") {
        $newPath = "$awsDir;$currentPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        $env:Path = "$awsDir;$env:Path"
        Write-Host "  [OK] Added to PATH" -ForegroundColor Green
    }
    
    # Test AWS CLI
    Write-Host "  [INFO] Testing AWS CLI..." -ForegroundColor Gray
    try {
        $job = Start-Job -ScriptBlock {
            param($Path)
            & $Path --version 2>&1 | Select-Object -First 1
        } -ArgumentList $awsPath
        
        $result = Wait-Job $job -Timeout 10
        if ($result) {
            $output = Receive-Job $job
            Remove-Job $job -Force
            Write-Host "  [OK] AWS CLI works: $output" -ForegroundColor Green
        } else {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force
            Write-Host "  [WARN] AWS CLI still hangs, but installation is complete" -ForegroundColor Yellow
            Write-Host "  [INFO] Try restarting PowerShell and test again" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARN] Could not test AWS CLI: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [ERROR] AWS CLI not found after installation!" -ForegroundColor Red
    exit 1
}

# Step 5: Restore config files if they exist
Write-Host "`n[Step 5] Checking for config backups..." -ForegroundColor Yellow
$configBackups = Get-ChildItem "$env:USERPROFILE\.aws\*.backup.*" -ErrorAction SilentlyContinue
if ($configBackups) {
    Write-Host "  [INFO] Found $($configBackups.Count) backup file(s)" -ForegroundColor Gray
    $latestConfig = $configBackups | Where-Object { $_.Name -like "config.backup.*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $latestCreds = $configBackups | Where-Object { $_.Name -like "credentials.backup.*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    
    if ($latestConfig) {
        $restore = Read-Host "  Restore config file from backup? (y/n)"
        if ($restore -eq "y") {
            Copy-Item $latestConfig.FullName "$env:USERPROFILE\.aws\config" -Force
            Write-Host "  [OK] Restored config file" -ForegroundColor Green
        }
    }
    
    if ($latestCreds) {
        $restore = Read-Host "  Restore credentials file from backup? (y/n)"
        if ($restore -eq "y") {
            Copy-Item $latestCreds.FullName "$env:USERPROFILE\.aws\credentials" -Force
            Write-Host "  [OK] Restored credentials file" -ForegroundColor Green
        }
    }
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Reinstallation Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Important: RESTART PowerShell now!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart, test AWS CLI:" -ForegroundColor Cyan
Write-Host "  aws --version" -ForegroundColor Gray
Write-Host ""
Write-Host "If it still hangs after restart:" -ForegroundColor Yellow
Write-Host "  1. Check Windows Event Viewer for errors" -ForegroundColor Gray
Write-Host "  2. Try MSI installer: .\scripts\reinstall-aws-cli.ps1 -UseMSI" -ForegroundColor Gray
Write-Host "  3. Check antivirus/security software" -ForegroundColor Gray
Write-Host ""

