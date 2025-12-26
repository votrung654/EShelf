# Script to create EC2 instances using AWS CLI
# This bypasses Terraform AMI validation when you don't have ec2:DescribeImages permission

param(
    [string]$Region = "us-east-1",
    [string]$AmiId = "ami-012face341cb74b64",
    [string]$SecurityGroupId = "sg-01673021793fa3d71",
    [string]$PublicSubnet1 = "subnet-0d349fe7cfcedf874",
    [string]$PublicSubnet2 = "subnet-0366235c9bad48f6c",
    [string]$PrivateSubnet1 = "subnet-00216db7520aa91c5",
    [string]$PrivateSubnet2 = "subnet-0c65965a71e2e79b8",
    [string]$KeyName = "",
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Creating EC2 Instances with AWS CLI" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check AWS CLI
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

# Test AWS credentials
Write-Host "Testing AWS credentials..." -ForegroundColor Yellow
$testResult = aws sts get-caller-identity --region $Region 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: AWS credentials not configured. Run 'aws configure' first." -ForegroundColor Red
    exit 1
}
Write-Host "AWS credentials OK" -ForegroundColor Green
Write-Host ""

# User data scripts
$bastionUserData = "IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQp5dW0gaW5zdGFsbCAteSBkb2NrZXIKc3lzdGVtY3RsIHN0YXJ0IGRvY2tlcgpzeXN0ZW1jdGwgZW5hYmxlIGRvY2tlcgp1c2VybW9kIC1hR2RvY2tlciBlYzItdXNlcg=="
$k3sUserData = "IyEvYmluL2Jhc2gKeXVtIHVwZGF0ZSAteQo="

# Function to create instance
function Create-EC2Instance {
    param(
        [string]$Name,
        [string]$InstanceType,
        [string]$SubnetId,
        [string]$UserDataBase64,
        [bool]$AssociatePublicIp = $true,
        [int]$VolumeSize = 20
    )
    
    Write-Host "Creating instance: $Name" -ForegroundColor Yellow
    Write-Host "  Type: $InstanceType" -ForegroundColor Gray
    Write-Host "  Subnet: $SubnetId" -ForegroundColor Gray
    
    # Create temp JSON files
    $tempDir = $env:TEMP
    $tagsFile = Join-Path $tempDir "tags-$([System.Guid]::NewGuid().ToString()).json"
    $blockDeviceFile = Join-Path $tempDir "blockdevice-$([System.Guid]::NewGuid().ToString()).json"
    
    # Tags JSON
    $tagsJson = @"
[{"Key":"Project","Value":"eShelf"},{"Key":"Environment","Value":"dev"},{"Key":"ManagedBy","Value":"AWS-CLI"},{"Key":"Name","Value":"$Name"}]
"@
    $tagsJson | Out-File -FilePath $tagsFile -Encoding utf8 -NoNewline
    
    # Block device JSON
    $blockDeviceJson = @"
[{"DeviceName":"/dev/xvda","Ebs":{"VolumeType":"gp3","VolumeSize":$VolumeSize,"DeleteOnTermination":true,"Encrypted":true}}]
"@
    $blockDeviceJson | Out-File -FilePath $blockDeviceFile -Encoding utf8 -NoNewline
    
    # Build AWS CLI command as string
    $cmd = "aws ec2 run-instances --region $Region --image-id $AmiId --instance-type $InstanceType --subnet-id $SubnetId --security-group-ids $SecurityGroupId --user-data $UserDataBase64 --tag-specifications `"ResourceType=instance,Tags=file://$tagsFile`" --tag-specifications `"ResourceType=volume,Tags=file://$tagsFile`" --block-device-mappings file://$blockDeviceFile"
    
    if ($AssociatePublicIp) {
        $cmd += " --associate-public-ip-address"
    }
    
    if ($KeyName -ne "") {
        $cmd += " --key-name $KeyName"
    }
    
    if ($DryRun) {
        $cmd += " --dry-run"
        Write-Host "  [DRY RUN] Would create instance" -ForegroundColor Cyan
        Remove-Item -Path $tagsFile -ErrorAction SilentlyContinue
        Remove-Item -Path $blockDeviceFile -ErrorAction SilentlyContinue
        return $null
    }
    
    try {
        Write-Host "  Running command..." -ForegroundColor Gray
        $ErrorActionPreference = "Continue"
        $output = Invoke-Expression $cmd 2>&1
        $allOutput = $output | Out-String
        
        # Check for errors first
        if ($allOutput -match 'Error|error|Exception|UnauthorizedOperation') {
            Write-Host "  Error details:" -ForegroundColor Red
            Write-Host $allOutput -ForegroundColor Red
            return $null
        }
        
        if ($allOutput -match '"InstanceId"\s*:\s*"([^"]+)"') {
            $instanceId = $matches[1]
            Write-Host "  Created: $instanceId" -ForegroundColor Green
            
            Start-Sleep -Seconds 3
            
            # Get instance details
            $detailsJson = aws ec2 describe-instances --region $Region --instance-ids $instanceId --query 'Reservations[0].Instances[0]' 2>&1
            if ($LASTEXITCODE -eq 0) {
                $details = $detailsJson | ConvertFrom-Json
                Write-Host "  Private IP: $($details.PrivateIpAddress)" -ForegroundColor Gray
                if ($details.PublicIpAddress) {
                    Write-Host "  Public IP: $($details.PublicIpAddress)" -ForegroundColor Gray
                }
                
                return [PSCustomObject]@{
                    Name = $Name
                    InstanceId = $instanceId
                    InstanceType = $InstanceType
                    PrivateIp = $details.PrivateIpAddress
                    PublicIp = $details.PublicIpAddress
                    State = $details.State.Name
                }
            } else {
                Write-Host "  Warning: Could not get instance details" -ForegroundColor Yellow
                return [PSCustomObject]@{
                    Name = $Name
                    InstanceId = $instanceId
                    InstanceType = $InstanceType
                    PrivateIp = "N/A"
                    PublicIp = "N/A"
                    State = "pending"
                }
            }
        } else {
            Write-Host "  Error creating instance:" -ForegroundColor Red
            Write-Host $allOutput -ForegroundColor Red
            return $null
        }
    } finally {
        Remove-Item -Path $tagsFile -ErrorAction SilentlyContinue
        Remove-Item -Path $blockDeviceFile -ErrorAction SilentlyContinue
    }
}

# Create instances
Write-Host "Creating EC2 instances..." -ForegroundColor Cyan
Write-Host ""

$instances = @()

# 1. Bastion
$bastion = Create-EC2Instance -Name "eshelf-bastion-dev" -InstanceType "t3.micro" -SubnetId $PublicSubnet1 -UserDataBase64 $bastionUserData -AssociatePublicIp $true -VolumeSize 20
if ($bastion) { $instances += $bastion }
Write-Host ""

# 2. K3s Master
$k3sMaster = Create-EC2Instance -Name "eshelf-k3s-master-dev" -InstanceType "t3.medium" -SubnetId $PublicSubnet1 -UserDataBase64 $k3sUserData -AssociatePublicIp $true -VolumeSize 30
if ($k3sMaster) { $instances += $k3sMaster }
Write-Host ""

# 3. K3s Worker 1
$k3sWorker1 = Create-EC2Instance -Name "eshelf-k3s-worker-1-dev" -InstanceType "t3.small" -SubnetId $PrivateSubnet1 -UserDataBase64 $k3sUserData -AssociatePublicIp $false -VolumeSize 30
if ($k3sWorker1) { $instances += $k3sWorker1 }
Write-Host ""

# 4. K3s Worker 2
$k3sWorker2 = Create-EC2Instance -Name "eshelf-k3s-worker-2-dev" -InstanceType "t3.small" -SubnetId $PrivateSubnet2 -UserDataBase64 $k3sUserData -AssociatePublicIp $false -VolumeSize 30
if ($k3sWorker2) { $instances += $k3sWorker2 }

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($instances.Count -gt 0) {
    $instances | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "Instance IDs:" -ForegroundColor Yellow
    foreach ($inst in $instances) {
        Write-Host "  $($inst.Name): $($inst.InstanceId)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "To check status:" -ForegroundColor Yellow
    $ids = ($instances.InstanceId) -join ' '
    Write-Host "  aws ec2 describe-instances --region $Region --instance-ids $ids" -ForegroundColor Gray
    
    if ($bastion -and $bastion.PublicIp) {
        Write-Host ""
        Write-Host "To connect to bastion:" -ForegroundColor Yellow
        if ($KeyName -ne "") {
            Write-Host "  ssh -i ~/.ssh/$KeyName.pem ec2-user@$($bastion.PublicIp)" -ForegroundColor Gray
        } else {
            Write-Host "  aws ssm start-session --target $($bastion.InstanceId) --region $Region" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "No instances were created." -ForegroundColor Red
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
