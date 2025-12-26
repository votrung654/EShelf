# Script tự động cập nhật Ansible inventory từ Terraform output
# Usage: .\scripts\update-ansible-inventory.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Update Ansible Inventory from Terraform" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

$terraformDir = "infrastructure\terraform\environments\$Environment"
$inventoryPath = "infrastructure\ansible\inventory\$Environment.ini"

# Check if terraform directory exists
if (-not (Test-Path $terraformDir)) {
    Write-Host "Error: Terraform directory not found: $terraformDir" -ForegroundColor Red
    exit 1
}

# Change to terraform directory
Push-Location $terraformDir

try {
    # Get Terraform outputs
    Write-Host "[1/3] Getting Terraform outputs..." -ForegroundColor Cyan
    
    $masterIpJson = terraform output -json k3s_master_public_ip 2>&1
    $masterIp = $masterIpJson | ConvertFrom-Json
    
    $workerIpsJson = terraform output -json k3s_worker_private_ips 2>&1
    $workerIps = $workerIpsJson | ConvertFrom-Json
    $worker1Ip = $workerIps[0]
    $worker2Ip = $workerIps[1]
    
    if ($LASTEXITCODE -ne 0 -or -not $masterIp) {
        Write-Host "Error: Could not get Terraform outputs. Make sure terraform apply has been run." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "  Master IP: $masterIp" -ForegroundColor Green
    Write-Host "  Worker 1 IP: $worker1Ip" -ForegroundColor Green
    Write-Host "  Worker 2 IP: $worker2Ip" -ForegroundColor Green
    
    # Create inventory content
    Write-Host "[2/3] Creating Ansible inventory..." -ForegroundColor Cyan
    
    $inventoryContent = @"
[master]
k3s-master ansible_host=$masterIp ansible_user=ec2-user

[workers]
k3s-worker-1 ansible_host=$worker1Ip ansible_user=ec2-user
k3s-worker-2 ansible_host=$worker2Ip ansible_user=ec2-user

[k3s_cluster:children]
master
workers

[all:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"@
    
    # Write inventory file
    Write-Host "[3/3] Writing inventory file..." -ForegroundColor Cyan
    $inventoryDir = Split-Path $inventoryPath -Parent
    if (-not (Test-Path $inventoryDir)) {
        New-Item -ItemType Directory -Path $inventoryDir -Force | Out-Null
    }
    
    $fullInventoryPath = Join-Path (Get-Location).Path.Replace("infrastructure\terraform\environments\$Environment", "") $inventoryPath
    Set-Content -Path $fullInventoryPath -Value $inventoryContent
    
    Write-Host "`n✅ Ansible inventory updated!" -ForegroundColor Green
    Write-Host "`nInventory file: $inventoryPath" -ForegroundColor Cyan
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Make sure you can SSH to the instances"
    Write-Host "  2. Run: cd infrastructure\ansible"
    Write-Host "  3. Run: ansible-playbook -i inventory\$Environment.ini playbooks\setup-cluster.yml"
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

