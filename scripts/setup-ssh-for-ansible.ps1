# Script setup SSH cho Ansible
# Usage: .\scripts\setup-ssh-for-ansible.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Setup SSH for Ansible" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

$sshDir = "$env:USERPROFILE\.ssh"
$publicKeyPath = "$sshDir\id_rsa.pub"
$privateKeyPath = "$sshDir\id_rsa"

# Check SSH key
if (-not (Test-Path $publicKeyPath)) {
    Write-Host "Error: SSH public key not found at $publicKeyPath" -ForegroundColor Red
    Write-Host "Please generate SSH key first:" -ForegroundColor Yellow
    Write-Host "  ssh-keygen -t rsa -b 4096 -f $publicKeyPath" -ForegroundColor Gray
    exit 1
}

Write-Host "[1/4] SSH key found" -ForegroundColor Green
$publicKey = Get-Content $publicKeyPath -Raw
Write-Host "  Public key: $($publicKey.Substring(0, [Math]::Min(50, $publicKey.Length)))..." -ForegroundColor Gray

# Get Terraform outputs
Write-Host "[2/4] Getting Terraform outputs..." -ForegroundColor Cyan
$terraformDir = "infrastructure\terraform\environments\$Environment"

if (-not (Test-Path $terraformDir)) {
    Write-Host "Error: Terraform directory not found: $terraformDir" -ForegroundColor Red
    exit 1
}

Push-Location $terraformDir

try {
    $masterIpJson = terraform output -json k3s_master_public_ip 2>&1
    $masterIp = $masterIpJson | ConvertFrom-Json
    
    $workerIpsJson = terraform output -json k3s_worker_private_ips 2>&1
    $workerIps = $workerIpsJson | ConvertFrom-Json
    $worker1Ip = $workerIps[0]
    $worker2Ip = $workerIps[1]
    
    $bastionIpJson = terraform output -json bastion_public_ip 2>&1
    $bastionIp = $bastionIpJson | ConvertFrom-Json
    
    Write-Host "  Master IP: $masterIp" -ForegroundColor Green
    Write-Host "  Worker 1 IP: $worker1Ip" -ForegroundColor Green
    Write-Host "  Worker 2 IP: $worker2Ip" -ForegroundColor Green
    Write-Host "  Bastion IP: $bastionIp" -ForegroundColor Green
    
} catch {
    Write-Host "Error: Could not get Terraform outputs. Make sure terraform apply has been run." -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

# Check if instances have key pair
Write-Host "[3/4] Checking instance key pairs..." -ForegroundColor Cyan
Write-Host "  Note: If instances were created without key pair, you need to:" -ForegroundColor Yellow
Write-Host "    1. Use AWS Systems Manager Session Manager to connect" -ForegroundColor Yellow
Write-Host "    2. Or create a key pair and attach it to instances" -ForegroundColor Yellow
Write-Host ""

# Option 1: Use Systems Manager Session Manager
Write-Host "[4/4] SSH Setup Options:" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Use AWS Systems Manager Session Manager (Recommended)" -ForegroundColor Green
Write-Host "  This doesn't require SSH keys on instances" -ForegroundColor Gray
Write-Host ""
Write-Host "  Install AWS Session Manager Plugin:" -ForegroundColor Yellow
Write-Host "    winget install Amazon.SessionManagerPlugin" -ForegroundColor Gray
Write-Host ""
Write-Host "  Connect to instances:" -ForegroundColor Yellow
Write-Host "    aws ssm start-session --target <instance-id> --region us-east-1" -ForegroundColor Gray
Write-Host ""
Write-Host "  Get instance IDs:" -ForegroundColor Yellow
Write-Host "    aws ec2 describe-instances --region us-east-1 --filters `"Name=tag:Name,Values=eshelf-*`" --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==\`Name\`].Value|[0],State.Name]' --output table" -ForegroundColor Gray
Write-Host ""

# Option 2: Manual SSH key copy
Write-Host "Option 2: Copy SSH key manually (if instances have key pair)" -ForegroundColor Green
Write-Host ""
Write-Host "  Your public key:" -ForegroundColor Yellow
Write-Host "    $publicKey" -ForegroundColor Gray
Write-Host ""
Write-Host "  Copy this key to instances:" -ForegroundColor Yellow
Write-Host "    ssh-copy-id -i $publicKeyPath ec2-user@$masterIp" -ForegroundColor Gray
Write-Host "    ssh-copy-id -i $publicKeyPath ec2-user@$worker1Ip" -ForegroundColor Gray
Write-Host "    ssh-copy-id -i $publicKeyPath ec2-user@$worker2Ip" -ForegroundColor Gray
Write-Host ""

# Option 3: Use Ansible with Systems Manager
Write-Host "Option 3: Configure Ansible to use Systems Manager" -ForegroundColor Green
Write-Host ""
Write-Host "  Update ansible.cfg to use AWS SSM:" -ForegroundColor Yellow
Write-Host "    [defaults]" -ForegroundColor Gray
Write-Host "    host_key_checking = False" -ForegroundColor Gray
Write-Host "    [inventory]" -ForegroundColor Gray
Write-Host "    enable_plugins = aws_ec2" -ForegroundColor Gray
Write-Host ""

Write-Host "✅ Setup instructions displayed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Choose one of the options above" -ForegroundColor White
Write-Host "  2. Test connection to one instance" -ForegroundColor White
Write-Host "  3. Run Ansible playbook: cd infrastructure\ansible && ansible-playbook -i inventory\$Environment.ini playbooks\setup-cluster.yml" -ForegroundColor White



