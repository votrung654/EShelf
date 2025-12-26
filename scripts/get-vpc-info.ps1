# Script to get VPC information for Terraform configuration
# Usage: .\scripts\get-vpc-info.ps1 -VpcId vpc-0a5f3fddad683a720

param(
    [Parameter(Mandatory=$true)]
    [string]$VpcId
)

Write-Host "Getting VPC information for: $VpcId" -ForegroundColor Cyan

try {
    # Get VPC details
    $vpc = Get-EC2Vpc -VpcId $VpcId -ErrorAction Stop
    
    Write-Host "`n=== VPC Information ===" -ForegroundColor Green
    Write-Host "VPC ID: $($vpc.VpcId)"
    Write-Host "CIDR Block: $($vpc.CidrBlock)"
    Write-Host "State: $($vpc.State)"
    
    # Get Internet Gateways
    Write-Host "`n=== Internet Gateways ===" -ForegroundColor Green
    $igws = Get-EC2InternetGateway -Filter @{Name="attachment.vpc-id";Values=$VpcId}
    if ($igws) {
        foreach ($igw in $igws) {
            Write-Host "IGW ID: $($igw.InternetGatewayId)"
            Write-Host "  State: $($igw.Attachments[0].State)"
        }
    } else {
        Write-Host "No Internet Gateway found attached to this VPC" -ForegroundColor Yellow
    }
    
    # Get existing subnets
    Write-Host "`n=== Existing Subnets ===" -ForegroundColor Green
    $subnets = Get-EC2Subnet -Filter @{Name="vpc-id";Values=$VpcId}
    if ($subnets) {
        foreach ($subnet in $subnets) {
            Write-Host "Subnet ID: $($subnet.SubnetId)"
            Write-Host "  CIDR: $($subnet.CidrBlock)"
            Write-Host "  AZ: $($subnet.AvailabilityZone)"
            Write-Host "  Tags: $($subnet.Tags | Where-Object {$_.Key -eq 'Name'} | Select-Object -ExpandProperty Value)"
        }
    } else {
        Write-Host "No subnets found in this VPC" -ForegroundColor Yellow
    }
    
    # Get Key Pairs
    Write-Host "`n=== Available Key Pairs ===" -ForegroundColor Green
    $keyPairs = Get-EC2KeyPair
    if ($keyPairs) {
        foreach ($kp in $keyPairs) {
            Write-Host "Key Name: $($kp.KeyName)"
            Write-Host "  Fingerprint: $($kp.KeyFingerprint)"
        }
    } else {
        Write-Host "No key pairs found in this region" -ForegroundColor Yellow
        Write-Host "You can create instances without key pairs (use Systems Manager Session Manager to connect)" -ForegroundColor Cyan
    }
    
    Write-Host "`n=== Terraform Configuration ===" -ForegroundColor Green
    Write-Host "Add this to your terraform.tfvars:"
    Write-Host "use_existing_vpc = true"
    Write-Host "vpc_cidr = `"$($vpc.CidrBlock)`""
    Write-Host "existing_vpc_id = `"$VpcId`""
    if ($igws) {
        Write-Host "existing_igw_id = `"$($igws[0].InternetGatewayId)`""
    } else {
        Write-Host "existing_igw_id = `"`"  # No IGW found, Terraform will try to create one"
    }
    if ($keyPairs) {
        Write-Host "create_key_pair = false"
        Write-Host "key_name = `"$($keyPairs[0].KeyName)`"  # Or use another key pair name"
    } else {
        Write-Host "create_key_pair = false"
        Write-Host "key_name = `"`"  # No key pair available, instances will be created without key pair"
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Make sure you have AWS credentials configured and the VPC ID is correct" -ForegroundColor Yellow
    exit 1
}

