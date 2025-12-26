# Script tự động cập nhật terraform.tfvars từ AWS resources
# Usage: .\scripts\auto-update-terraform-config.ps1 -Region us-east-1 -TerraformDir infrastructure\terraform\environments\dev

param(
    [string]$Region = "us-east-1",
    [string]$TerraformDir = "infrastructure\terraform\environments\dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Auto Update Terraform Configuration" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Terraform Dir: $TerraformDir" -ForegroundColor Yellow
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

# Check AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "Error: AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Get default VPC
Write-Host "[1/5] Getting default VPC..." -ForegroundColor Cyan
$vpcJson = aws ec2 describe-vpcs --region $Region --filters "Name=isDefault,Values=true" --query 'Vpcs[0]' --output json 2>&1
if ($LASTEXITCODE -ne 0 -or $vpcJson -match "null") {
    Write-Host "Error: Could not find default VPC in region $Region" -ForegroundColor Red
    exit 1
}

$vpc = $vpcJson | ConvertFrom-Json
$vpcId = $vpc.VpcId
$vpcCidr = $vpc.CidrBlock

Write-Host "  Found VPC: $vpcId ($vpcCidr)" -ForegroundColor Green

# Get subnets
Write-Host "[2/5] Getting subnets..." -ForegroundColor Cyan
$subnetsJson = aws ec2 describe-subnets --region $Region --filters "Name=vpc-id,Values=$vpcId" --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]' --output json 2>&1
$subnets = $subnetsJson | ConvertFrom-Json

$publicSubnets = @()
$privateSubnets = @()

foreach ($subnet in $subnets) {
    $subnetId = $subnet[0]
    $az = $subnet[1]
    $cidr = $subnet[2]
    $isPublic = $subnet[3]
    
    if ($isPublic) {
        $publicSubnets += $subnetId
        Write-Host "  Public: $subnetId ($az)" -ForegroundColor Green
    } else {
        $privateSubnets += $subnetId
        Write-Host "  Private: $subnetId ($az)" -ForegroundColor Yellow
    }
}

# If no private subnets, use public subnets as private (default VPC behavior)
if ($privateSubnets.Count -eq 0) {
    Write-Host "  No private subnets found, using public subnets as private" -ForegroundColor Yellow
    $privateSubnets = $publicSubnets[0..([Math]::Min(1, $publicSubnets.Count-1))]
}

# Get security groups
Write-Host "[3/5] Getting security groups..." -ForegroundColor Cyan
$sgsJson = aws ec2 describe-security-groups --region $Region --filters "Name=vpc-id,Values=$vpcId" "Name=group-name,Values=default" --query 'SecurityGroups[0].GroupId' --output text 2>&1
$defaultSgId = $sgsJson.Trim()

if ($defaultSgId -and $defaultSgId -ne "None") {
    Write-Host "  Found default SG: $defaultSgId" -ForegroundColor Green
} else {
    Write-Host "  Warning: Could not find default security group" -ForegroundColor Yellow
    $defaultSgId = ""
}

# Get availability zones
Write-Host "[4/5] Getting availability zones..." -ForegroundColor Cyan
$azs = @()
foreach ($subnet in $subnets) {
    $az = $subnet[1]
    if ($az -notin $azs) {
        $azs += $az
    }
}
$azs = $azs | Sort-Object
Write-Host "  AZs: $($azs -join ', ')" -ForegroundColor Green

# Get AMI ID (latest Amazon Linux 2023)
Write-Host "[5/5] Getting latest AMI ID..." -ForegroundColor Cyan
$amiId = aws ec2 describe-images --region $Region --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=virtualization-type,Values=hvm" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text 2>&1
if ($LASTEXITCODE -eq 0 -and $amiId -and $amiId -ne "None") {
    Write-Host "  Found AMI: $amiId" -ForegroundColor Green
} else {
    Write-Host "  Warning: Could not query AMI (may need permissions). Using existing value." -ForegroundColor Yellow
    $amiId = ""
}

# Read existing terraform.tfvars
$tfvarsPath = Join-Path $TerraformDir "terraform.tfvars"
if (-not (Test-Path $tfvarsPath)) {
    Write-Host "Creating terraform.tfvars from example..." -ForegroundColor Yellow
    $examplePath = Join-Path $TerraformDir "terraform.tfvars.example"
    if (Test-Path $examplePath) {
        Copy-Item $examplePath $tfvarsPath
    } else {
        Write-Host "Error: terraform.tfvars.example not found" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nUpdating terraform.tfvars..." -ForegroundColor Cyan
$content = Get-Content $tfvarsPath -Raw

# Update region
$content = $content -replace '(?m)^aws_region\s*=\s*"[^"]*"', "aws_region = `"$Region`""

# Update VPC
$content = $content -replace '(?m)^existing_vpc_id\s*=\s*"[^"]*"', "existing_vpc_id = `"$vpcId`""
$content = $content -replace '(?m)^vpc_cidr\s*=\s*"[^"]*"', "vpc_cidr = `"$vpcCidr`""

# Update availability zones
$azsString = ($azs | ForEach-Object { "`"$_`"" }) -join ', '
$content = $content -replace '(?m)^availability_zones\s*=\s*\[[^\]]*\]', "availability_zones = [$azsString]"

# Update subnets
$publicSubnetsString = ($publicSubnets | ForEach-Object { "`"$_`"" }) -join ', '
$privateSubnetsString = ($privateSubnets | ForEach-Object { "`"$_`"" }) -join ', '
$content = $content -replace '(?m)^existing_public_subnet_ids\s*=\s*\[[^\]]*\]', "existing_public_subnet_ids = [$publicSubnetsString]"
$content = $content -replace '(?m)^existing_private_subnet_ids\s*=\s*\[[^\]]*\]', "existing_private_subnet_ids = [$privateSubnetsString]"

# Update security groups
if ($defaultSgId) {
    $content = $content -replace '(?m)^existing_bastion_sg_id\s*=\s*"[^"]*"', "existing_bastion_sg_id = `"$defaultSgId`""
    $content = $content -replace '(?m)^existing_app_sg_id\s*=\s*"[^"]*"', "existing_app_sg_id = `"$defaultSgId`""
    $content = $content -replace '(?m)^existing_alb_sg_id\s*=\s*"[^"]*"', "existing_alb_sg_id = `"$defaultSgId`""
    $content = $content -replace '(?m)^existing_k3s_master_sg_id\s*=\s*"[^"]*"', "existing_k3s_master_sg_id = `"$defaultSgId`""
    $content = $content -replace '(?m)^existing_k3s_worker_sg_id\s*=\s*"[^"]*"', "existing_k3s_worker_sg_id = `"$defaultSgId`""
    $content = $content -replace '(?m)^existing_rds_sg_id\s*=\s*"[^"]*"', "existing_rds_sg_id = `"$defaultSgId`""
}

# Update AMI ID if found
if ($amiId) {
    $content = $content -replace '(?m)^ami_id\s*=\s*"[^"]*"', "ami_id = `"$amiId`""
}

# Write back
Set-Content -Path $tfvarsPath -Value $content -NoNewline

Write-Host "`n✅ terraform.tfvars has been updated!" -ForegroundColor Green
Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Region: $Region"
Write-Host "  VPC: $vpcId ($vpcCidr)"
Write-Host "  Public Subnets: $($publicSubnets.Count)"
Write-Host "  Private Subnets: $($privateSubnets.Count)"
Write-Host "  Security Group: $defaultSgId"
if ($amiId) {
    Write-Host "  AMI ID: $amiId"
}
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review terraform.tfvars: notepad $tfvarsPath"
Write-Host "  2. Run: terraform plan"
Write-Host "  3. Run: terraform apply"

