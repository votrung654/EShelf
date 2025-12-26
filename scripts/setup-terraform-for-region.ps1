# Script to setup Terraform for current AWS region
# Usage: .\scripts\setup-terraform-for-region.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Setup Terraform for Current Region" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get current region from AWS CLI
$currentRegion = aws configure get region
Write-Host "Current AWS region: $currentRegion" -ForegroundColor Green

# Get availability zones for current region
Write-Host "`nGetting availability zones for $currentRegion..." -ForegroundColor Cyan
$azsJson = aws ec2 describe-availability-zones --region $currentRegion --query "AvailabilityZones[*].ZoneName" --output json 2>&1
$azs = $azsJson | ConvertFrom-Json

if ($azs.Count -lt 2) {
    Write-Host "  ⚠️  Warning: Less than 2 availability zones found" -ForegroundColor Yellow
} else {
    Write-Host "  ✅ Found $($azs.Count) availability zones" -ForegroundColor Green
    $selectedAzs = $azs[0..1]
    Write-Host "  Using: $($selectedAzs -join ', ')" -ForegroundColor White
}

# Terraform directory
$terraformDir = "infrastructure\terraform\environments\$Environment"
$tfvarsExample = "$terraformDir\terraform.tfvars.example"
$tfvars = "$terraformDir\terraform.tfvars"

# Check if terraform.tfvars exists
if (Test-Path $tfvars) {
    Write-Host "`n⚠️  terraform.tfvars already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to update it? (y/n)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "  Keeping existing terraform.tfvars" -ForegroundColor Gray
        exit 0
    }
} else {
    # Copy from example
    if (Test-Path $tfvarsExample) {
        Copy-Item $tfvarsExample $tfvars
        Write-Host "`n✅ Created terraform.tfvars from example" -ForegroundColor Green
    } else {
        Write-Host "`n❌ terraform.tfvars.example not found at: $tfvarsExample" -ForegroundColor Red
        exit 1
    }
}

# Read current terraform.tfvars
$tfvarsContent = Get-Content $tfvars -Raw

# Update region
$tfvarsContent = $tfvarsContent -replace 'aws_region\s*=\s*"[^"]*"', "aws_region = `"$currentRegion`""

# Update availability zones
if ($selectedAzs) {
    $azsString = "[`"$($selectedAzs[0])`", `"$($selectedAzs[1])`"]"
    $tfvarsContent = $tfvarsContent -replace 'availability_zones\s*=\s*\[[^\]]*\]', "availability_zones = $azsString"
}

# Update subnet CIDRs based on region (to avoid conflicts)
$regionNumber = switch ($currentRegion) {
    "us-east-1" { "0" }
    "us-west-2" { "1" }
    "ap-southeast-1" { "2" }
    "ap-southeast-2" { "3" }
    "eu-west-1" { "4" }
    default { "0" }
}

$tfvarsContent = $tfvarsContent -replace 'vpc_cidr\s*=\s*"[^"]*"', "vpc_cidr = `"10.$regionNumber.0.0/16`""
$tfvarsContent = $tfvarsContent -replace 'public_subnet_cidrs\s*=\s*\[[^\]]*\]', "public_subnet_cidrs = [`"10.$regionNumber.1.0/24`", `"10.$regionNumber.2.0/24`"]"
$tfvarsContent = $tfvarsContent -replace 'private_subnet_cidrs\s*=\s*\[[^\]]*\]', "private_subnet_cidrs = [`"10.$regionNumber.10.0/24`", `"10.$regionNumber.11.0/24`"]"

# Write updated content
Set-Content -Path $tfvars -Value $tfvarsContent -NoNewline

Write-Host "`n✅ Updated terraform.tfvars:" -ForegroundColor Green
Write-Host "  - Region: $currentRegion" -ForegroundColor White
Write-Host "  - Availability Zones: $($selectedAzs -join ', ')" -ForegroundColor White
Write-Host "  - VPC CIDR: 10.$regionNumber.0.0/16" -ForegroundColor White

Write-Host "`n📋 Next steps:" -ForegroundColor Cyan
Write-Host "  1. Review terraform.tfvars:" -ForegroundColor White
Write-Host "     notepad $tfvars" -ForegroundColor Gray
Write-Host "  2. Get AMI ID for region:" -ForegroundColor White
$amiCmd = ".\scripts\get-ami-id.ps1 -Region $currentRegion"
Write-Host "     $amiCmd" -ForegroundColor Gray
Write-Host "  3. Initialize Terraform:" -ForegroundColor White
Write-Host "     cd $terraformDir" -ForegroundColor Gray
Write-Host "     terraform init" -ForegroundColor Gray
Write-Host "  4. Plan and Apply:" -ForegroundColor White
Write-Host "     terraform plan" -ForegroundColor Gray
Write-Host '     terraform apply' -ForegroundColor Gray

