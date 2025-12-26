# Script to fix AWS CLI hanging issue in PowerShell
# Usage: .\scripts\fix-aws-cli-hang.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Fixing AWS CLI Hang Issue" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Function to get AWS CLI path
function Get-AWSCLIPath {
    $possiblePaths = @(
        "C:\Program Files\Amazon\AWSCLIV2\aws.exe",
        "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe",
        "$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2\aws.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Try to find in PATH
    $awsCmd = Get-Command aws -ErrorAction SilentlyContinue
    if ($awsCmd) {
        return $awsCmd.Source
    }
    
    return $null
}

# Function to check AWS version with timeout
function Get-AWSVersion {
    param(
        [string]$AWSPath
    )
    
    try {
        # Use Start-Job with timeout to prevent hanging
        $job = Start-Job -ScriptBlock {
            param($Path)
            & $Path --version 2>&1 | Select-Object -First 1
        } -ArgumentList $AWSPath
        
        # Wait with timeout (5 seconds)
        $result = Wait-Job $job -Timeout 5
        
        if ($result) {
            $output = Receive-Job $job
            Remove-Job $job -Force
            return $output
        } else {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force
            return $null
        }
    } catch {
        return $null
    }
}

# Step 1: Find AWS CLI
Write-Host "[Step 1] Finding AWS CLI installation..." -ForegroundColor Yellow
$awsPath = Get-AWSCLIPath

if (-not $awsPath) {
    Write-Host "  [ERROR] AWS CLI not found!" -ForegroundColor Red
    Write-Host "  Please install AWS CLI first:" -ForegroundColor Yellow
    Write-Host "    winget install Amazon.AWSCLI" -ForegroundColor Cyan
    exit 1
}

Write-Host "  [OK] Found AWS CLI at: $awsPath" -ForegroundColor Green

# Step 2: Test with direct path
Write-Host "`n[Step 2] Testing AWS CLI with direct path..." -ForegroundColor Yellow
$version = Get-AWSVersion -AWSPath $awsPath

if ($version) {
    Write-Host "  [OK] AWS CLI works with direct path: $version" -ForegroundColor Green
} else {
    Write-Host "  [WARN] AWS CLI still hangs even with direct path" -ForegroundColor Yellow
    Write-Host "  This might indicate a deeper issue (corrupted config, etc.)" -ForegroundColor Yellow
}

# Step 3: Check AWS config files
Write-Host "`n[Step 3] Checking AWS config files..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.aws\config"
$credentialsPath = "$env:USERPROFILE\.aws\credentials"

if (Test-Path $configPath) {
    Write-Host "  [OK] Config file exists: $configPath" -ForegroundColor Gray
    try {
        $configContent = Get-Content $configPath -ErrorAction Stop
        Write-Host "  [OK] Config file is readable" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Config file might be locked or corrupted" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [INFO] Config file not found (this is OK if not configured yet)" -ForegroundColor Gray
}

if (Test-Path $credentialsPath) {
    Write-Host "  [OK] Credentials file exists: $credentialsPath" -ForegroundColor Gray
    try {
        $credsContent = Get-Content $credentialsPath -ErrorAction Stop
        Write-Host "  [OK] Credentials file is readable" -ForegroundColor Green
    } catch {
        Write-Host "  [WARN] Credentials file might be locked or corrupted" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [INFO] Credentials file not found (this is OK if not configured yet)" -ForegroundColor Gray
}

# Step 4: Create a simple test script
Write-Host "`n[Step 4] Creating test script..." -ForegroundColor Yellow

$testScriptContent = @'
# Quick test for AWS CLI version (safe version with timeout)
param(
    [string]$AWSPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
)

if (Test-Path $AWSPath) {
    Write-Host "Testing AWS CLI..." -ForegroundColor Cyan
    $job = Start-Job -ScriptBlock {
        param($Path)
        & $Path --version 2>&1 | Select-Object -First 1
    } -ArgumentList $AWSPath
    
    $result = Wait-Job $job -Timeout 5
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        Write-Host $output -ForegroundColor Green
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Write-Host "AWS CLI command timed out!" -ForegroundColor Red
    }
} else {
    Write-Host "AWS CLI not found at: $AWSPath" -ForegroundColor Red
}
'@

$testScriptPath = "scripts\test-aws-version-safe.ps1"
try {
    Set-Content -Path $testScriptPath -Value $testScriptContent -ErrorAction Stop
    Write-Host "  [OK] Created test script: $testScriptPath" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Could not create test script: $_" -ForegroundColor Yellow
}

# Step 5: Create PowerShell function file
Write-Host "`n[Step 5] Creating AWS wrapper function file..." -ForegroundColor Yellow

$functionContent = @"
# AWS CLI wrapper function to prevent hanging
# Source this file in your PowerShell profile or run: . .\scripts\aws-wrapper.ps1

function aws {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$Arguments
    )
    
    `$awsPath = "$awsPath"
    
    if (-not (Test-Path `$awsPath)) {
        Write-Error "AWS CLI not found at `$awsPath"
        return
    }
    
    # For --version, use timeout
    if (`$Arguments -contains "--version") {
        try {
            `$job = Start-Job -ScriptBlock {
                param(`$Path)
                & `$Path --version 2>&1 | Select-Object -First 1
            } -ArgumentList `$awsPath
            
            `$result = Wait-Job `$job -Timeout 5
            if (`$result) {
                Receive-Job `$job
                Remove-Job `$job -Force
            } else {
                Stop-Job `$job -ErrorAction SilentlyContinue
                Remove-Job `$job -Force
                Write-Error "AWS CLI command timed out"
            }
        } catch {
            Write-Error "Error running AWS CLI: `$_"
        }
    } else {
        # For other commands, use direct path
        & `$awsPath @Arguments
    }
}
"@

$functionPath = "scripts\aws-wrapper.ps1"
try {
    Set-Content -Path $functionPath -Value $functionContent -ErrorAction Stop
    Write-Host "  [OK] Created wrapper function: $functionPath" -ForegroundColor Green
    Write-Host "  To use: . .\scripts\aws-wrapper.ps1" -ForegroundColor Cyan
} catch {
    Write-Host "  [WARN] Could not create wrapper function: $_" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[OK] AWS CLI found at: $awsPath" -ForegroundColor Green
Write-Host ""
Write-Host "To use AWS CLI without hanging:" -ForegroundColor Yellow
Write-Host "  1. Use direct path: & '$awsPath' --version" -ForegroundColor Cyan
Write-Host "  2. Use test script: .\scripts\test-aws-version-safe.ps1" -ForegroundColor Cyan
Write-Host "  3. Load wrapper function: . .\scripts\aws-wrapper.ps1" -ForegroundColor Cyan
Write-Host "     Then you can use: aws --version" -ForegroundColor Gray
Write-Host ""
Write-Host "If the issue persists:" -ForegroundColor Yellow
Write-Host "  - Check if AWS config files are corrupted" -ForegroundColor Gray
Write-Host "  - Try reinstalling AWS CLI: winget install Amazon.AWSCLI" -ForegroundColor Gray
Write-Host "  - Check Windows Event Viewer for errors" -ForegroundColor Gray
Write-Host ""
