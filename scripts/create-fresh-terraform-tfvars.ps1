# Script to create fresh terraform.tfvars for new AWS account
# Usage: .\scripts\create-fresh-terraform-tfvars.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Create Fresh terraform.tfvars" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$terraformDir = "infrastructure\terraform\environments\$Environment"
$tfvars = "$terraformDir\terraform.tfvars"

# Get current region
$currentRegion = aws configure get region
Write-Host "Current region: $currentRegion" -ForegroundColor Green

# Get availability zones
$azsJson = aws ec2 describe-availability-zones --region $currentRegion --query "AvailabilityZones[*].ZoneName" --output json 2>&1
$azs = $azsJson | ConvertFrom-Json
$selectedAzs = $azs[0..1]

# Get default VPC info
$vpcInfo = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --region $currentRegion --query "Vpcs[0].[VpcId,CidrBlock]" --output text 2>&1
$vpcParts = $vpcInfo -split "`t"
$defaultVpcId = $vpcParts[0]
$defaultVpcCidr = $vpcParts[1]

Write-Host "Default VPC ID: $defaultVpcId" -ForegroundColor Green
Write-Host "Default VPC CIDR: $defaultVpcCidr" -ForegroundColor Green

# Get AMI ID
Write-Host "`nGetting AMI ID..." -ForegroundColor Cyan
$amiId = aws ec2 describe-images --region $currentRegion --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=virtualization-type,Values=hvm" --query "sort_by(Images, &CreationDate)[-1].[ImageId]" --output text 2>&1

if ($LASTEXITCODE -eq 0 -and $amiId -match "^ami-") {
    Write-Host "  ✅ AMI ID: $amiId" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Could not get AMI ID automatically" -ForegroundColor Yellow
    $amiId = ""  # User will need to fill this
}

# Create terraform.tfvars content
$tfvarsContent = @"
# Development Environment Variables
# Generated for AWS Free Tier account
# Region: $currentRegion

aws_region = "$currentRegion"

# VPC Configuration
# Using default VPC for Free Tier account
use_existing_vpc = true
existing_vpc_id = "$defaultVpcId"
existing_igw_id = ""  # Will be auto-detected

vpc_cidr = "$defaultVpcCidr"

availability_zones = ["$($selectedAzs[0])", "$($selectedAzs[1])"]

# Get existing subnets from default VPC
# Run: aws ec2 describe-subnets --filters "Name=vpc-id,Values=$defaultVpcId" --region $currentRegion --query "Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]" --output table
use_existing_subnets = true
existing_public_subnet_ids = []  # TODO: Fill with 2 public subnet IDs
existing_private_subnet_ids = []  # TODO: Fill with 2 private subnet IDs

# Subnet CIDRs (if creating new subnets)
public_subnet_cidrs = ["10.3.1.0/24", "10.3.2.0/24"]
private_subnet_cidrs = ["10.3.10.0/24", "10.3.11.0/24"]

enable_nat_gateway = false  # Set to false for default VPC (no NAT needed)

# SSH access
allowed_ssh_cidrs = ["0.0.0.0/0"]  # Change to your IP for security: ["YOUR_IP/32"]

# Security Groups
# For Free Tier, we'll create new security groups
use_existing_security_groups = false
existing_bastion_sg_id = ""
existing_app_sg_id = ""
existing_alb_sg_id = ""
existing_k3s_master_sg_id = ""
existing_k3s_worker_sg_id = ""
existing_rds_sg_id = ""

# EC2 Key Pair
create_key_pair = true
public_key = ""  # TODO: Paste your SSH public key here (or leave empty to use SSM)

# Instance types (Free Tier eligible)
bastion_instance_type = "t3.micro"
app_instance_type = "t3.micro"  # Changed to t3.micro for Free Tier
app_instance_count = 2

# K3s Cluster
create_k3s_cluster = true
k3s_master_instance_type = "t3.small"  # Free Tier: 750 hours/month
k3s_worker_instance_type = "t3.micro"  # Free Tier: 750 hours/month
k3s_worker_count = 2

# AMI ID
ami_id = "$amiId"  # Amazon Linux 2023 for $currentRegion

"@

# Backup existing file if exists
if (Test-Path $tfvars) {
    $backupPath = "$tfvars.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $tfvars $backupPath
    Write-Host "`n✅ Backed up existing terraform.tfvars to:" -ForegroundColor Green
    Write-Host "  $backupPath" -ForegroundColor Gray
}

# Write new file
Set-Content -Path $tfvars -Value $tfvarsContent

Write-Host "`n✅ Created fresh terraform.tfvars" -ForegroundColor Green
Write-Host "`n⚠️  TODO - You need to fill in:" -ForegroundColor Yellow
Write-Host "  1. existing_public_subnet_ids - Get from:" -ForegroundColor White
Write-Host "     aws ec2 describe-subnets --filters `"Name=vpc-id,Values=$defaultVpcId`" --region $currentRegion --query `"Subnets[?MapPublicIpOnLaunch==\`true\`].SubnetId`" --output text" -ForegroundColor Gray
Write-Host "  2. existing_private_subnet_ids - Get from:" -ForegroundColor White
Write-Host "     aws ec2 describe-subnets --filters `"Name=vpc-id,Values=$defaultVpcId`" --region $currentRegion --query `"Subnets[?MapPublicIpOnLaunch==\`false\`].SubnetId`" --output text" -ForegroundColor Gray
Write-Host "  3. public_key (optional) - Your SSH public key" -ForegroundColor White
Write-Host "`nFile location: $tfvars" -ForegroundColor Cyan



