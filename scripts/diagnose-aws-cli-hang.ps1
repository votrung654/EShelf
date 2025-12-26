# Diagnostic script to find root cause of AWS CLI hang
# Usage: .\scripts\diagnose-aws-cli-hang.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "AWS CLI Hang Diagnostic Tool" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$issues = @()
$fixes = @()

# Check 1: AWS CLI Installation
Write-Host "[Check 1] AWS CLI Installation..." -ForegroundColor Yellow
$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$awsPathAlt = "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe"

if (Test-Path $awsPath) {
    Write-Host "  [OK] Found at: $awsPath" -ForegroundColor Green
    $actualPath = $awsPath
} elseif (Test-Path $awsPathAlt) {
    Write-Host "  [OK] Found at: $awsPathAlt" -ForegroundColor Green
    $actualPath = $awsPathAlt
} else {
    Write-Host "  [ERROR] AWS CLI not found at standard locations" -ForegroundColor Red
    $issues += "AWS CLI not found"
    exit 1
}

# Check 2: PATH Configuration
Write-Host "`n[Check 2] PATH Configuration..." -ForegroundColor Yellow
$awsInPath = Get-Command aws -ErrorAction SilentlyContinue
if ($awsInPath) {
    Write-Host "  [OK] AWS CLI is in PATH: $($awsInPath.Source)" -ForegroundColor Green
    if ($awsInPath.Source -ne $actualPath) {
        Write-Host "  [WARN] PATH points to different location!" -ForegroundColor Yellow
        $issues += "PATH mismatch"
        $fixes += "Update PATH to point to: $actualPath"
    }
} else {
    Write-Host "  [WARN] AWS CLI not in PATH" -ForegroundColor Yellow
    $issues += "AWS CLI not in PATH"
    $fixes += "Add to PATH: $actualPath"
}

# Check 3: Config Files
Write-Host "`n[Check 3] AWS Config Files..." -ForegroundColor Yellow
$configPath = "$env:USERPROFILE\.aws\config"
$credentialsPath = "$env:USERPROFILE\.aws\credentials"

if (Test-Path $configPath) {
    Write-Host "  [OK] Config file exists" -ForegroundColor Green
    try {
        $configContent = Get-Content $configPath -ErrorAction Stop
        Write-Host "  [OK] Config file is readable" -ForegroundColor Green
        
        # Check for problematic settings
        if ($configContent -match "cli_pager") {
            Write-Host "  [INFO] Found cli_pager setting" -ForegroundColor Gray
        }
        if ($configContent -match "cli_read_timeout") {
            Write-Host "  [INFO] Found cli_read_timeout setting" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [ERROR] Config file cannot be read: $_" -ForegroundColor Red
        $issues += "Config file locked or corrupted"
        $fixes += "Check file permissions or delete and recreate: $configPath"
    }
} else {
    Write-Host "  [INFO] Config file not found (will be created on first use)" -ForegroundColor Gray
}

if (Test-Path $credentialsPath) {
    Write-Host "  [OK] Credentials file exists" -ForegroundColor Green
    try {
        $credsContent = Get-Content $credentialsPath -ErrorAction Stop
        Write-Host "  [OK] Credentials file is readable" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Credentials file cannot be read: $_" -ForegroundColor Red
        $issues += "Credentials file locked or corrupted"
        $fixes += "Check file permissions or delete and recreate: $credentialsPath"
    }
} else {
    Write-Host "  [INFO] Credentials file not found (will be created on first use)" -ForegroundColor Gray
}

# Check 4: Environment Variables
Write-Host "`n[Check 4] Environment Variables..." -ForegroundColor Yellow
$envVars = @("AWS_PROFILE", "AWS_DEFAULT_PROFILE", "AWS_REGION", "AWS_DEFAULT_REGION", "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY")
$foundVars = @()
foreach ($var in $envVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        $foundVars += $var
        if ($var -match "KEY|SECRET") {
            Write-Host "  [INFO] $var is set (hidden)" -ForegroundColor Gray
        } else {
            Write-Host "  [INFO] $var = $value" -ForegroundColor Gray
        }
    }
}
if ($foundVars.Count -eq 0) {
    Write-Host "  [OK] No problematic environment variables found" -ForegroundColor Green
}

# Check 5: Process Locks
Write-Host "`n[Check 5] Process Locks..." -ForegroundColor Yellow
$awsProcesses = Get-Process -Name "aws" -ErrorAction SilentlyContinue
if ($awsProcesses) {
    Write-Host "  [WARN] Found $($awsProcesses.Count) AWS CLI process(es) running" -ForegroundColor Yellow
    foreach ($proc in $awsProcesses) {
        Write-Host "    PID: $($proc.Id), Started: $($proc.StartTime)" -ForegroundColor Gray
    }
    $issues += "AWS CLI processes already running"
    $fixes += "Kill hanging processes: Get-Process -Name aws | Stop-Process -Force"
} else {
    Write-Host "  [OK] No AWS CLI processes running" -ForegroundColor Green
}

# Check 6: PowerShell Execution Policy
Write-Host "`n[Check 6] PowerShell Execution Policy..." -ForegroundColor Yellow
$execPolicy = Get-ExecutionPolicy
Write-Host "  [INFO] Current execution policy: $execPolicy" -ForegroundColor Gray
if ($execPolicy -eq "Restricted") {
    Write-Host "  [WARN] Execution policy is Restricted" -ForegroundColor Yellow
    $issues += "Execution policy too restrictive"
    $fixes += "Set execution policy: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
}

# Check 7: Test with different methods
Write-Host "`n[Check 7] Testing AWS CLI with different methods..." -ForegroundColor Yellow

# Method 1: Direct path
Write-Host "  [Test 1] Direct path execution..." -ForegroundColor Cyan
try {
    $job = Start-Job -ScriptBlock {
        param($Path)
        $env:Path = "C:\Program Files\Amazon\AWSCLIV2;$env:Path"
        & $Path --version 2>&1 | Select-Object -First 1
    } -ArgumentList $actualPath
    
    $result = Wait-Job $job -Timeout 3
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        Write-Host "    [OK] Direct path works: $output" -ForegroundColor Green
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Write-Host "    [ERROR] Direct path also hangs!" -ForegroundColor Red
        $issues += "Direct path execution hangs"
    }
} catch {
    Write-Host "    [ERROR] Direct path test failed: $_" -ForegroundColor Red
    $issues += "Direct path test exception"
}

# Method 2: With clean environment
Write-Host "  [Test 2] Clean environment execution..." -ForegroundColor Cyan
try {
    $job = Start-Job -ScriptBlock {
        param($Path)
        # Clean environment
        Remove-Item Env:AWS_PROFILE -ErrorAction SilentlyContinue
        Remove-Item Env:AWS_DEFAULT_PROFILE -ErrorAction SilentlyContinue
        Remove-Item Env:AWS_CONFIG_FILE -ErrorAction SilentlyContinue
        Remove-Item Env:AWS_SHARED_CREDENTIALS_FILE -ErrorAction SilentlyContinue
        
        & $Path --version 2>&1 | Select-Object -First 1
    } -ArgumentList $actualPath
    
    $result = Wait-Job $job -Timeout 3
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        Write-Host "    [OK] Clean environment works: $output" -ForegroundColor Green
        if ($issues -contains "Direct path execution hangs") {
            $fixes += "The issue might be with config files or environment variables"
        }
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Write-Host "    [ERROR] Clean environment also hangs!" -ForegroundColor Red
        $issues += "Clean environment execution hangs"
    }
} catch {
    Write-Host "    [ERROR] Clean environment test failed: $_" -ForegroundColor Red
}

# Method 3: Check if it's a PATH issue
Write-Host "  [Test 3] PATH resolution test..." -ForegroundColor Cyan
try {
    $env:Path = "C:\Program Files\Amazon\AWSCLIV2;$env:Path"
    $job = Start-Job -ScriptBlock {
        aws --version 2>&1 | Select-Object -First 1
    }
    
    $result = Wait-Job $job -Timeout 3
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        Write-Host "    [OK] PATH resolution works: $output" -ForegroundColor Green
        if ($issues -contains "AWS CLI not in PATH") {
            $fixes += "Add AWS CLI to PATH permanently"
        }
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Write-Host "    [ERROR] PATH resolution hangs!" -ForegroundColor Red
        $issues += "PATH resolution hangs"
    }
} catch {
    Write-Host "    [ERROR] PATH resolution test failed: $_" -ForegroundColor Red
}

# Check 8: AWS CLI Python dependencies
Write-Host "`n[Check 8] AWS CLI Dependencies..." -ForegroundColor Yellow
$awsDistPath = Split-Path $actualPath -Parent
$pythonDll = Join-Path $awsDistPath "python.exe"
if (Test-Path $pythonDll) {
    Write-Host "  [OK] Python runtime found" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Python runtime not found in AWS CLI directory" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Diagnostic Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($issues.Count -eq 0) {
    Write-Host "[OK] No obvious issues found" -ForegroundColor Green
    Write-Host ""
    Write-Host "Possible solutions:" -ForegroundColor Yellow
    Write-Host "  1. Reinstall AWS CLI:" -ForegroundColor Cyan
    Write-Host "     winget uninstall Amazon.AWSCLI" -ForegroundColor Gray
    Write-Host "     winget install Amazon.AWSCLI" -ForegroundColor Gray
    Write-Host "     (Restart PowerShell after installation)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Clear AWS config and recreate:" -ForegroundColor Cyan
    Write-Host "     Remove-Item `$env:USERPROFILE\.aws\* -Force" -ForegroundColor Gray
    Write-Host "     aws configure" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Use AWS CLI v2 MSI installer instead of winget" -ForegroundColor Cyan
    Write-Host "     Download from: https://awscli.amazonaws.com/AWSCLIV2.msi" -ForegroundColor Gray
} else {
    Write-Host "[ISSUES FOUND] $($issues.Count) issue(s) detected:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Suggested fixes:" -ForegroundColor Yellow
    foreach ($fix in $fixes) {
        Write-Host "  - $fix" -ForegroundColor Cyan
    }
}

Write-Host ""

