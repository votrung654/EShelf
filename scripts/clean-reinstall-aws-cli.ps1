# Script to completely remove and reinstall AWS CLI
# Usage: .\scripts\clean-reinstall-aws-cli.ps1

param(
    [switch]$UseMSI,
    [switch]$KeepConfig
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Complete AWS CLI Clean Reinstall" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
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

# Step 3: Remove all AWS CLI directories
Write-Host "`n[Step 3] Removing AWS CLI directories..." -ForegroundColor Yellow
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
            # Try normal delete first
            Remove-Item $dir -Recurse -Force -ErrorAction Stop
            Write-Host "    [OK] Removed successfully" -ForegroundColor Green
        } catch {
            Write-Host "    [WARN] Could not remove: $_" -ForegroundColor Yellow
            Write-Host "    [INFO] Trying with takeown and icacls..." -ForegroundColor Gray
            try {
                # Take ownership
                Start-Process takeown -ArgumentList "/F `"$dir`" /R /D Y" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                # Grant full control
                Start-Process icacls -ArgumentList "`"$dir`" /grant administrators:F /T" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                # Remove again
                Remove-Item $dir -Recurse -Force -ErrorAction Stop
                Write-Host "    [OK] Removed after taking ownership" -ForegroundColor Green
            } catch {
                Write-Host "    [ERROR] Still cannot remove. You may need to:" -ForegroundColor Red
                Write-Host "      - Close all programs using AWS CLI" -ForegroundColor Gray
                Write-Host "      - Restart computer" -ForegroundColor Gray
                Write-Host "      - Manually delete: $dir" -ForegroundColor Gray
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
    $removed = ($currentUserPath -split ';' | Where-Object { 
        $path = $_.Trim()
        foreach ($removePath in $pathsToRemove) {
            if ($path -eq $removePath -or $path -like "*$removePath*") {
                return $true
            }
        }
        return $false
    }) -join ';'
    if ($removed) {
        Write-Host "  [INFO] Removed from PATH: $removed" -ForegroundColor Gray
    }
} else {
    Write-Host "  [OK] PATH already clean" -ForegroundColor Green
}

# Step 5: Backup and remove config files
Write-Host "`n[Step 5] Handling config files..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.aws"
if (Test-Path $configPath) {
    if ($KeepConfig) {
        Write-Host "  [INFO] Keeping config files (--KeepConfig specified)" -ForegroundColor Gray
    } else {
        $backupPath = "$env:USERPROFILE\.aws.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Write-Host "  [INFO] Backing up config to: $backupPath" -ForegroundColor Gray
        try {
            Copy-Item $configPath $backupPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Config backed up" -ForegroundColor Green
            
            Write-Host "  [INFO] Removing config files..." -ForegroundColor Gray
            Remove-Item $configPath -Recurse -Force -ErrorAction Stop
            Write-Host "  [OK] Config files removed" -ForegroundColor Green
        } catch {
            Write-Host "  [WARN] Could not backup/remove config: $_" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  [OK] No config files found" -ForegroundColor Green
}

# Step 6: Clear environment variables
Write-Host "`n[Step 6] Clearing AWS environment variables..." -ForegroundColor Yellow
$awsEnvVars = @("AWS_PROFILE", "AWS_DEFAULT_PROFILE", "AWS_REGION", "AWS_DEFAULT_REGION")
$cleared = @()
foreach ($var in $awsEnvVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        [Environment]::SetEnvironmentVariable($var, $null, "User")
        Remove-Item "Env:$var" -ErrorAction SilentlyContinue
        $cleared += $var
    }
}
if ($cleared.Count -gt 0) {
    Write-Host "  [OK] Cleared variables: $($cleared -join ', ')" -ForegroundColor Green
} else {
    Write-Host "  [OK] No AWS environment variables found" -ForegroundColor Green
}

# Step 7: Wait a bit
Write-Host "`n[Step 7] Waiting for cleanup to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
Write-Host "  [OK] Cleanup complete" -ForegroundColor Green

# Step 8: Reinstall AWS CLI
Write-Host "`n[Step 8] Reinstalling AWS CLI..." -ForegroundColor Yellow

if ($UseMSI) {
    Write-Host "  [INFO] Using MSI installer..." -ForegroundColor Gray
    
    $msiPath = "$env:TEMP\AWSCLIV2.msi"
    $msiUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
    
    try {
        Write-Host "  [INFO] Downloading MSI installer..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing
        Write-Host "  [OK] Downloaded MSI installer" -ForegroundColor Green
        
        Write-Host "  [INFO] Installing AWS CLI (this may take a few minutes)..." -ForegroundColor Gray
        $installProcess = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait -PassThru -NoNewWindow
        
        if ($installProcess.ExitCode -eq 0) {
            Write-Host "  [OK] MSI installation completed successfully" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] MSI installation exit code: $($installProcess.ExitCode)" -ForegroundColor Yellow
        }
        
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

# Step 9: Verify installation
Write-Host "`n[Step 9] Verifying installation..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

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
    
    # Test AWS CLI with timeout
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
            Write-Host "  [WARN] AWS CLI test timed out" -ForegroundColor Yellow
            Write-Host "  [INFO] This might be normal - try after restarting PowerShell" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARN] Could not test AWS CLI: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [ERROR] AWS CLI not found after installation!" -ForegroundColor Red
    Write-Host "  [INFO] Installation may have failed" -ForegroundColor Yellow
    exit 1
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Clean Reinstall Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANT: RESTART PowerShell now!" -ForegroundColor Yellow
Write-Host ""
Write-Host "After restart, test AWS CLI:" -ForegroundColor Cyan
Write-Host "  aws --version" -ForegroundColor Gray
Write-Host ""
Write-Host "If it still hangs:" -ForegroundColor Yellow
Write-Host "  1. Check Windows Event Viewer" -ForegroundColor Gray
Write-Host "  2. Check antivirus/security software" -ForegroundColor Gray
Write-Host "  3. Try running PowerShell as Administrator" -ForegroundColor Gray
Write-Host "  4. Use CloudShell in AWS Console instead" -ForegroundColor Gray
Write-Host ""

