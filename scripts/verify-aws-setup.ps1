# Script to verify AWS account setup
# Usage: .\scripts\verify-aws-setup.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Verify AWS Account Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true
$tests = @()

# Test 1: AWS CLI installed
Write-Host "[Test 1] Checking AWS CLI..." -ForegroundColor Yellow
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
        $awsVersion = Receive-Job $job
        Remove-Job $job -Force
        Write-Host "  AWS CLI installed: $awsVersion" -ForegroundColor Green
        $tests += @{Name="AWS CLI"; Status="PASS"; Details=$awsVersion}
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        throw "AWS CLI version check timed out"
    }
} catch {
    Write-Host "  AWS CLI not installed or not working" -ForegroundColor Red
    Write-Host "    Install: winget install Amazon.AWSCLI" -ForegroundColor Yellow
    Write-Host "    Or run: .\scripts\fix-aws-cli-hang.ps1" -ForegroundColor Yellow
    $tests += @{Name="AWS CLI"; Status="FAIL"; Details="Not installed or hanging"}
    $allPassed = $false
}

# Test 2: AWS credentials configured
Write-Host "`n[Test 2] Checking AWS credentials..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $identity = & $awsPath sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        $identityObj = $identity | ConvertFrom-Json
        Write-Host "  ✅ AWS credentials configured" -ForegroundColor Green
        Write-Host "    Account ID: $($identityObj.Account)" -ForegroundColor Gray
        Write-Host "    User ARN: $($identityObj.Arn)" -ForegroundColor Gray
        $tests += @{Name="AWS Credentials"; Status="PASS"; Details="Account: $($identityObj.Account)"}
    } else {
        throw "Credentials not configured"
    }
} catch {
    Write-Host "  ❌ AWS credentials not configured" -ForegroundColor Red
    Write-Host "    Run: aws configure" -ForegroundColor Yellow
    $tests += @{Name="AWS Credentials"; Status="FAIL"; Details="Not configured"}
    $allPassed = $false
}

# Test 3: EC2 service access
Write-Host "`n[Test 3] Testing EC2 service access..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $regions = & $awsPath ec2 describe-regions --region-names us-east-1 --region us-east-1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ EC2 service accessible" -ForegroundColor Green
        $tests += @{Name="EC2 Service"; Status="PASS"; Details="Service accessible"}
    } else {
        throw "EC2 service not accessible"
    }
} catch {
    Write-Host "  ❌ Cannot access EC2 service" -ForegroundColor Red
    Write-Host "    Check IAM permissions" -ForegroundColor Yellow
    $tests += @{Name="EC2 Service"; Status="FAIL"; Details="Access denied"}
    $allPassed = $false
}

# Test 4: VPC access
Write-Host "`n[Test 4] Testing VPC access..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $vpcs = & $awsPath ec2 describe-vpcs --region us-east-1 --max-items 1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ VPC service accessible" -ForegroundColor Green
        $tests += @{Name="VPC Service"; Status="PASS"; Details="Service accessible"}
    } else {
        throw "VPC service not accessible"
    }
} catch {
    Write-Host "  ❌ Cannot access VPC service" -ForegroundColor Red
    Write-Host "    Check IAM permissions" -ForegroundColor Yellow
    $tests += @{Name="VPC Service"; Status="FAIL"; Details="Access denied"}
    $allPassed = $false
}

# Test 5: SSM access (for Session Manager)
Write-Host "`n[Test 5] Testing SSM service access..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $ssm = & $awsPath ssm get-parameter --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ SSM service accessible" -ForegroundColor Green
        $tests += @{Name="SSM Service"; Status="PASS"; Details="Service accessible"}
    } else {
        Write-Host "  ⚠️  SSM service may need setup" -ForegroundColor Yellow
        Write-Host "    This is optional, but needed for SSM Session Manager" -ForegroundColor Gray
        $tests += @{Name="SSM Service"; Status="WARN"; Details="May need setup"}
    }
} catch {
    Write-Host "  ⚠️  SSM service not accessible (optional)" -ForegroundColor Yellow
    $tests += @{Name="SSM Service"; Status="WARN"; Details="Optional"}
}

# Test 6: Check default VPC
Write-Host "`n[Test 6] Checking default VPC..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $defaultVpc = & $awsPath ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region us-east-1 --query "Vpcs[0].VpcId" --output text 2>&1
    if ($defaultVpc -and $defaultVpc -ne "None") {
        Write-Host "  ✅ Default VPC found: $defaultVpc" -ForegroundColor Green
        $tests += @{Name="Default VPC"; Status="PASS"; Details="VPC ID: $defaultVpc"}
    } else {
        Write-Host "  ⚠️  No default VPC (Terraform will create one)" -ForegroundColor Yellow
        $tests += @{Name="Default VPC"; Status="INFO"; Details="Will be created by Terraform"}
    }
} catch {
    Write-Host "  ⚠️  Could not check VPC" -ForegroundColor Yellow
    $tests += @{Name="Default VPC"; Status="WARN"; Details="Check failed"}
}

# Test 7: Check IAM permissions
Write-Host "`n[Test 7] Checking IAM permissions..." -ForegroundColor Yellow
try {
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    $userArn = & $awsPath sts get-caller-identity --query 'Arn' --output text 2>&1
    $userName = ($userArn -split '/')[1]
    $policies = & $awsPath iam list-attached-user-policies --user-name $userName 2>&1
    if ($LASTEXITCODE -eq 0) {
        $policyCount = ($policies | ConvertFrom-Json).AttachedPolicies.Count
        Write-Host "  ✅ IAM user has $policyCount attached policy/policies" -ForegroundColor Green
        $tests += @{Name="IAM Permissions"; Status="PASS"; Details="$policyCount policies attached"}
    } else {
        Write-Host "  ⚠️  Could not check IAM policies" -ForegroundColor Yellow
        $tests += @{Name="IAM Permissions"; Status="WARN"; Details="Check failed"}
    }
} catch {
    Write-Host "  ⚠️  Could not check IAM permissions" -ForegroundColor Yellow
    $tests += @{Name="IAM Permissions"; Status="WARN"; Details="Check failed"}
}

# Summary
Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($test in $tests) {
    $statusColor = switch ($test.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        default { "Yellow" }
    }
    $statusIcon = switch ($test.Status) {
        "PASS" { "✅" }
        "FAIL" { "❌" }
        default { "⚠️ " }
    }
    Write-Host "$statusIcon $($test.Name): $($test.Status)" -ForegroundColor $statusColor
    if ($test.Details) {
        Write-Host "    $($test.Details)" -ForegroundColor Gray
    }
}

Write-Host ""

if ($allPassed) {
    Write-Host "✅ All critical tests passed! Ready to proceed." -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Review terraform.tfvars" -ForegroundColor White
    Write-Host "  2. Run: cd infrastructure\terraform\environments\dev" -ForegroundColor Gray
    Write-Host "  3. Run: terraform init && terraform apply" -ForegroundColor Gray
} else {
    Write-Host "❌ Some tests failed. Please fix the issues above." -ForegroundColor Red
    Write-Host "`nSee: docs\AWS_FREE_TIER_SETUP_GUIDE.md for detailed setup instructions." -ForegroundColor Yellow
}
