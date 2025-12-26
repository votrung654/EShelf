# Script to test AWS connection and verify credentials
# This script tests various AWS services to ensure everything is working

param(
    [string]$Region = "us-east-1",
    [string]$Profile = ""
)

Write-Host "Testing AWS Connection..." -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

$tests = @()
$passed = 0
$failed = 0

# Test 1: AWS CLI installed
Write-Host "[Test 1] Checking AWS CLI installation..." -ForegroundColor Yellow
try {
    # Use direct path to avoid hanging
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    if (-not (Test-Path $awsPath)) {
        throw "AWS CLI not found"
    }
    
    # Use timeout to prevent hanging
    $job = Start-Job -ScriptBlock {
        param($Path)
        & $Path --version 2>&1 | Select-Object -First 1
    } -ArgumentList $awsPath
    
    $result = Wait-Job $job -Timeout 5
    if ($result) {
        $version = Receive-Job $job
        Remove-Job $job -Force
        Write-Host "  ✓ AWS CLI is installed: $version" -ForegroundColor Green
        $tests += @{Name="AWS CLI Installation"; Status="PASS"; Details=$version}
        $passed++
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        throw "AWS CLI version check timed out"
    }
} catch {
    Write-Host "  ✗ AWS CLI is not installed or not working" -ForegroundColor Red
    Write-Host "    Install: winget install Amazon.AWSCLI" -ForegroundColor Yellow
    Write-Host "    Or run: .\scripts\fix-aws-cli-hang.ps1" -ForegroundColor Yellow
    $tests += @{Name="AWS CLI Installation"; Status="FAIL"; Details="Not installed or hanging"}
    $failed++
}

# Test 2: AWS credentials configured
Write-Host "[Test 2] Checking AWS credentials..." -ForegroundColor Yellow

# Build AWS command with optional profile
$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
$awsCmd = "& `"$awsPath`" sts get-caller-identity --region $Region"
if ($Profile) {
    $awsCmd += " --profile $Profile"
}

try {
    $identity = Invoke-Expression $awsCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        $identityObj = $identity | ConvertFrom-Json
        Write-Host "  ✓ AWS credentials are configured" -ForegroundColor Green
        Write-Host "    Account ID: $($identityObj.Account)" -ForegroundColor Gray
        Write-Host "    User ARN: $($identityObj.Arn)" -ForegroundColor Gray
        if ($Profile) {
            Write-Host "    Using profile: $Profile" -ForegroundColor Gray
        }
        $tests += @{Name="AWS Credentials"; Status="PASS"; Details="Account: $($identityObj.Account)"}
        $passed++
    } else {
        throw "Credentials not configured"
    }
} catch {
    Write-Host "  ✗ AWS credentials are not configured" -ForegroundColor Red
    Write-Host "    Options:" -ForegroundColor Yellow
    Write-Host "    1. Use SSO: aws sso login --profile aws-academy" -ForegroundColor White
    Write-Host "    2. Use access keys: aws configure" -ForegroundColor White
    Write-Host "    3. Run: .\scripts\setup-aws-sso.ps1" -ForegroundColor White
    $tests += @{Name="AWS Credentials"; Status="FAIL"; Details="Not configured"}
    $failed++
}

# Test 3: AWS region access
Write-Host "[Test 3] Testing region access ($Region)..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $regionCmd = "& `"$awsPath`" ec2 describe-regions --region-names $Region --region $Region"
    if ($Profile) {
        $regionCmd += " --profile $Profile"
    }
    $regions = Invoke-Expression $regionCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Region $Region is accessible" -ForegroundColor Green
        $tests += @{Name="Region Access"; Status="PASS"; Details="Region: $Region"}
        $passed++
    } else {
        throw "Region not accessible"
    }
} catch {
    Write-Host "  ✗ Cannot access region $Region" -ForegroundColor Red
    $tests += @{Name="Region Access"; Status="FAIL"; Details="Region: $Region"}
    $failed++
}

# Test 4: EC2 service access
Write-Host "[Test 4] Testing EC2 service access..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $ec2Cmd = "& `"$awsPath`" ec2 describe-instances --region $Region --max-items 1"
    if ($Profile) {
        $ec2Cmd += " --profile $Profile"
    }
    $instances = Invoke-Expression $ec2Cmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ EC2 service is accessible" -ForegroundColor Green
        $tests += @{Name="EC2 Service"; Status="PASS"; Details="Service accessible"}
        $passed++
    } else {
        throw "EC2 service not accessible"
    }
} catch {
    Write-Host "  ✗ Cannot access EC2 service" -ForegroundColor Red
    Write-Host "    This might be normal if you haven't created any instances yet" -ForegroundColor Yellow
    $tests += @{Name="EC2 Service"; Status="WARN"; Details="Service check failed"}
    $failed++
}

# Test 5: VPC access
Write-Host "[Test 5] Testing VPC service access..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $vpcCmd = "& `"$awsPath`" ec2 describe-vpcs --region $Region --max-items 1"
    if ($Profile) {
        $vpcCmd += " --profile $Profile"
    }
    $vpcs = Invoke-Expression $vpcCmd 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ VPC service is accessible" -ForegroundColor Green
        $tests += @{Name="VPC Service"; Status="PASS"; Details="Service accessible"}
        $passed++
    } else {
        throw "VPC service not accessible"
    }
} catch {
    Write-Host "  ✗ Cannot access VPC service" -ForegroundColor Red
    $tests += @{Name="VPC Service"; Status="FAIL"; Details="Service check failed"}
    $failed++
}

# Summary
Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

foreach ($test in $tests) {
    $color = if ($test.Status -eq "PASS") { "Green" } elseif ($test.Status -eq "WARN") { "Yellow" } else { "Red" }
    Write-Host "[$($test.Status)] $($test.Name): $($test.Details)" -ForegroundColor $color
}

Write-Host ""
Write-Host "Results: $passed passed, $failed failed/warnings" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "✓ All tests passed! AWS connection is working." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "⚠ Some tests failed. Please check the errors above." -ForegroundColor Yellow
    exit 1
}

