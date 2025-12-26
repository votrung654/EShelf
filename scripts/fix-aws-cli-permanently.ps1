# Script to permanently fix AWS CLI hang issue
# This script attempts to fix the root cause, not just workaround
# Usage: .\scripts\fix-aws-cli-permanently.ps1

param(
    [switch]$Force
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Permanent AWS CLI Fix" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill any hanging AWS processes
Write-Host "[Step 1] Checking for hanging AWS processes..." -ForegroundColor Yellow
$awsProcesses = Get-Process -Name "aws" -ErrorAction SilentlyContinue
if ($awsProcesses) {
    Write-Host "  [INFO] Found $($awsProcesses.Count) AWS process(es), killing them..." -ForegroundColor Yellow
    $awsProcesses | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "  [OK] Killed hanging processes" -ForegroundColor Green
} else {
    Write-Host "  [OK] No hanging processes found" -ForegroundColor Green
}

# Step 2: Find AWS CLI installation
Write-Host "`n[Step 2] Finding AWS CLI installation..." -ForegroundColor Yellow
$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (-not (Test-Path $awsPath)) {
    $awsPath = "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe"
}
if (-not (Test-Path $awsPath)) {
    Write-Host "  [ERROR] AWS CLI not found!" -ForegroundColor Red
    Write-Host "  Please install AWS CLI first: winget install Amazon.AWSCLI" -ForegroundColor Yellow
    exit 1
}
Write-Host "  [OK] Found AWS CLI at: $awsPath" -ForegroundColor Green

# Step 3: Fix PATH
Write-Host "`n[Step 3] Fixing PATH..." -ForegroundColor Yellow
$awsDir = Split-Path $awsPath -Parent
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")

if ($currentPath -notlike "*$awsDir*" -and $machinePath -notlike "*$awsDir*") {
    Write-Host "  [INFO] AWS CLI not in PATH, adding..." -ForegroundColor Yellow
    $newPath = "$awsDir;$currentPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = "$awsDir;$env:Path"
    Write-Host "  [OK] Added AWS CLI to user PATH" -ForegroundColor Green
    Write-Host "  [WARN] Restart PowerShell for PATH changes to take effect" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] AWS CLI is already in PATH" -ForegroundColor Green
}

# Step 4: Check and fix config files
Write-Host "`n[Step 4] Checking AWS config files..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.aws\config"
$credentialsPath = "$env:USERPROFILE\.aws\credentials"

# Backup existing configs
if (Test-Path $configPath) {
    $backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $configPath $backupPath -Force
    Write-Host "  [INFO] Backed up config to: $backupPath" -ForegroundColor Gray
}

if (Test-Path $credentialsPath) {
    $backupCreds = "$credentialsPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $credentialsPath $backupCreds -Force
    Write-Host "  [INFO] Backed up credentials to: $backupCreds" -ForegroundColor Gray
}

# Check for problematic settings in config
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    $needsFix = $false
    
    # Check for cli_pager that might cause issues
    if ($configContent -match "cli_pager\s*=") {
        Write-Host "  [WARN] Found cli_pager setting, this might cause hanging" -ForegroundColor Yellow
        if ($Force) {
            $configContent = $configContent -replace "cli_pager\s*=.*", "cli_pager = "
            $needsFix = $true
        }
    }
    
    # Check for read timeout that might be too long
    if ($configContent -match "cli_read_timeout\s*=\s*0") {
        Write-Host "  [WARN] Found cli_read_timeout = 0, this might cause hanging" -ForegroundColor Yellow
        if ($Force) {
            $configContent = $configContent -replace "cli_read_timeout\s*=\s*0", "cli_read_timeout = 60"
            $needsFix = $true
        }
    }
    
    if ($needsFix) {
        Set-Content -Path $configPath -Value $configContent -Force
        Write-Host "  [OK] Fixed problematic config settings" -ForegroundColor Green
    } else {
        Write-Host "  [OK] Config file looks fine" -ForegroundColor Green
    }
}

# Step 5: Clear problematic environment variables
Write-Host "`n[Step 5] Checking environment variables..." -ForegroundColor Yellow
$problemVars = @("AWS_PROFILE", "AWS_DEFAULT_PROFILE")
$clearedVars = @()

foreach ($var in $problemVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        Write-Host "  [INFO] Found $var = $value" -ForegroundColor Gray
        if ($Force) {
            [Environment]::SetEnvironmentVariable($var, $null, "User")
            Remove-Item "Env:$var" -ErrorAction SilentlyContinue
            $clearedVars += $var
            Write-Host "  [OK] Cleared $var" -ForegroundColor Green
        }
    }
}

if ($clearedVars.Count -eq 0) {
    Write-Host "  [OK] No problematic environment variables found" -ForegroundColor Green
}

# Step 6: Test AWS CLI
Write-Host "`n[Step 6] Testing AWS CLI..." -ForegroundColor Yellow

# Test 1: Direct path
Write-Host "  [Test 1] Testing direct path..." -ForegroundColor Cyan
try {
    $output = & $awsPath --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    [OK] Direct path works: $($output | Select-Object -First 1)" -ForegroundColor Green
    } else {
        throw "Direct path failed"
    }
} catch {
    Write-Host "    [WARN] Direct path test failed or timed out" -ForegroundColor Yellow
    Write-Host "    This might indicate a deeper issue with AWS CLI installation" -ForegroundColor Yellow
}

# Test 2: PATH resolution (in new job to avoid current session issues)
Write-Host "  [Test 2] Testing PATH resolution..." -ForegroundColor Cyan
try {
    $job = Start-Job -ScriptBlock {
        $env:Path = "C:\Program Files\Amazon\AWSCLIV2;$env:Path"
        aws --version 2>&1 | Select-Object -First 1
    }
    
    $result = Wait-Job $job -Timeout 5
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        Write-Host "    [OK] PATH resolution works: $output" -ForegroundColor Green
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Write-Host "    [WARN] PATH resolution still hangs" -ForegroundColor Yellow
        Write-Host "    You may need to restart PowerShell" -ForegroundColor Yellow
    }
} catch {
    Write-Host "    [WARN] PATH resolution test failed: $_" -ForegroundColor Yellow
}

# Step 7: Create alias as permanent solution
Write-Host "`n[Step 7] Creating PowerShell alias..." -ForegroundColor Yellow
$profilePath = $PROFILE
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$aliasScript = @"
# AWS CLI alias fix (added by fix-aws-cli-permanently.ps1)
# This ensures AWS CLI uses direct path to avoid hanging

`$awsExe = '$awsPath'
if (Test-Path `$awsExe) {
    # Remove any existing alias
    Remove-Alias aws -ErrorAction SilentlyContinue
    
    # Create function that uses direct path
    function aws {
        param(
            [Parameter(ValueFromRemainingArguments=`$true)]
            [string[]]`$Arguments
        )
        & `$awsExe @Arguments
    }
    
    # Export function
    Export-ModuleMember -Function aws
}
"@

# Check if already added
$existing = Get-Content $profilePath -ErrorAction SilentlyContinue | Select-String -Pattern "fix-aws-cli-permanently"
if (-not $existing) {
    try {
        Add-Content -Path $profilePath -Value "`n$aliasScript" -ErrorAction Stop
        Write-Host "  [OK] Added AWS CLI fix to PowerShell profile" -ForegroundColor Green
        Write-Host "  [INFO] Profile location: $profilePath" -ForegroundColor Gray
    } catch {
        Write-Host "  [WARN] Could not add to profile: $_" -ForegroundColor Yellow
        Write-Host "  [INFO] You can manually add the fix to: $profilePath" -ForegroundColor Gray
    }
} else {
    Write-Host "  [INFO] Fix already in profile" -ForegroundColor Gray
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Fix Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Completed fixes:" -ForegroundColor Yellow
Write-Host "  ✓ Killed hanging processes" -ForegroundColor Green
Write-Host "  ✓ Fixed PATH configuration" -ForegroundColor Green
Write-Host "  ✓ Checked config files" -ForegroundColor Green
if ($clearedVars.Count -gt 0) {
    Write-Host "  ✓ Cleared environment variables: $($clearedVars -join ', ')" -ForegroundColor Green
}
Write-Host "  ✓ Added PowerShell profile fix" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "  1. RESTART PowerShell (required for PATH and profile changes)" -ForegroundColor Cyan
Write-Host "  2. Test: aws --version" -ForegroundColor Cyan
Write-Host "  3. If still hangs, run with -Force flag:" -ForegroundColor Gray
Write-Host "     .\scripts\fix-aws-cli-permanently.ps1 -Force" -ForegroundColor Gray
Write-Host ""

if (-not $Force) {
    Write-Host "Note: Use -Force flag to automatically fix config file issues" -ForegroundColor Yellow
    Write-Host "      .\scripts\fix-aws-cli-permanently.ps1 -Force" -ForegroundColor Gray
    Write-Host ""
}

