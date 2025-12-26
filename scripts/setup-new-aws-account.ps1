# Script to setup new AWS account (Free Tier)
# Usage: .\scripts\setup-new-aws-account.ps1

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Setup New AWS Account (Free Tier)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Configure AWS CLI
Write-Host "[1/4] Configuring AWS CLI..." -ForegroundColor Cyan
Write-Host "  Please run: aws configure" -ForegroundColor Yellow
Write-Host "  You will need:" -ForegroundColor Yellow
Write-Host "    - AWS Access Key ID" -ForegroundColor White
Write-Host "    - AWS Secret Access Key" -ForegroundColor White
Write-Host "    - Default region: us-east-1" -ForegroundColor White
Write-Host "    - Default output format: json" -ForegroundColor White
Write-Host ""

$configure = Read-Host "Have you configured AWS CLI? (y/n)"
if ($configure -ne "y" -and $configure -ne "Y") {
    Write-Host "  Please configure AWS CLI first:" -ForegroundColor Yellow
    Write-Host "    aws configure" -ForegroundColor Gray
    Write-Host "  Then run this script again." -ForegroundColor Yellow
    exit 1
}

# Step 2: Test AWS connection
Write-Host "`n[2/4] Testing AWS connection..." -ForegroundColor Cyan
$identity = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ AWS account connected!" -ForegroundColor Green
    Write-Host $identity -ForegroundColor White
    
    $accountId = ($identity | ConvertFrom-Json).Account
    Write-Host "  Account ID: $accountId" -ForegroundColor Green
} else {
    Write-Host "  ❌ Cannot connect to AWS:" -ForegroundColor Red
    Write-Host $identity -ForegroundColor Yellow
    Write-Host "  Please check your credentials and try again." -ForegroundColor Yellow
    exit 1
}

# Step 3: Check existing infrastructure
Write-Host "`n[3/4] Checking existing infrastructure..." -ForegroundColor Cyan
$instances = aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=eshelf-*" --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" --output table 2>&1

if ($LASTEXITCODE -eq 0 -and $instances -match "InstanceId") {
    Write-Host "  ⚠️  Found existing eShelf instances:" -ForegroundColor Yellow
    Write-Host $instances -ForegroundColor White
    Write-Host ""
    $destroy = Read-Host "Do you want to destroy old infrastructure and start fresh? (y/n)"
    
    if ($destroy -eq "y" -or $destroy -eq "Y") {
        Write-Host "  Destroying old infrastructure..." -ForegroundColor Yellow
        cd infrastructure\terraform\environments\dev
        terraform destroy -auto-approve 2>&1 | Out-Null
        cd ..\..\..\..
        Write-Host "  ✅ Old infrastructure destroyed" -ForegroundColor Green
    } else {
        Write-Host "  Keeping existing infrastructure. You can continue from Step 4." -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✅ No existing eShelf infrastructure found" -ForegroundColor Green
    Write-Host "  Ready to create new infrastructure" -ForegroundColor Green
}

# Step 4: Check Terraform state
Write-Host "`n[4/4] Checking Terraform state..." -ForegroundColor Cyan
$terraformState = "infrastructure\terraform\environments\dev\terraform.tfstate"
if (Test-Path $terraformState) {
    Write-Host "  ⚠️  Found existing Terraform state file" -ForegroundColor Yellow
    $backup = Read-Host "Do you want to backup and remove old state? (y/n)"
    
    if ($backup -eq "y" -or $backup -eq "Y") {
        $backupPath = "$terraformState.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $terraformState $backupPath
        Write-Host "  ✅ State backed up to: $backupPath" -ForegroundColor Green
        Write-Host "  Removing old state file..." -ForegroundColor Yellow
        Remove-Item $terraformState -Force
        Write-Host "  ✅ Old state removed. Ready for fresh start." -ForegroundColor Green
    }
} else {
    Write-Host "  ✅ No existing Terraform state. Ready for fresh start." -ForegroundColor Green
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review terraform.tfvars:" -ForegroundColor White
Write-Host "     cd infrastructure\terraform\environments\dev" -ForegroundColor Gray
Write-Host "     notepad terraform.tfvars" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Initialize and apply Terraform:" -ForegroundColor White
Write-Host "     terraform init" -ForegroundColor Gray
Write-Host "     terraform plan" -ForegroundColor Gray
Write-Host "     terraform apply" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Deploy K3s cluster:" -ForegroundColor White
Write-Host "     .\scripts\deploy-k3s-simple.ps1 -Environment dev" -ForegroundColor Gray
Write-Host ""
Write-Host "  4. Deploy applications:" -ForegroundColor White
Write-Host "     .\scripts\deploy-applications.ps1 -Environment dev" -ForegroundColor Gray



