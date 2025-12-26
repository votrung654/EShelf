# Script deploy K3s cluster via AWS SSM Session Manager
# Usage: .\scripts\deploy-k3s-via-ssm.ps1 -Environment dev

param(
    [string]$Environment = "dev",
    [string]$Region = ""
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Deploy K3s Cluster via AWS SSM" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

$terraformDir = "infrastructure\terraform\environments\$Environment"

# Check if terraform directory exists
if (-not (Test-Path $terraformDir)) {
    Write-Host "Error: Terraform directory not found: $terraformDir" -ForegroundColor Red
    exit 1
}

Push-Location $terraformDir

try {
    # Get region from terraform.tfvars if not provided
    if (-not $Region) {
        $tfvarsContent = Get-Content "terraform.tfvars" -Raw
        if ($tfvarsContent -match 'aws_region\s*=\s*"([^"]+)"') {
            $Region = $matches[1]
        } else {
            $Region = "us-east-1" # Default fallback
        }
    }
    Write-Host "  Using region: $Region" -ForegroundColor Cyan
    
    # Get Terraform outputs
    Write-Host "[1/5] Getting Terraform outputs..." -ForegroundColor Cyan
    
    $masterIpOutput = terraform output -json k3s_master_public_ip 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get master IP"
    }
    $masterIp = ($masterIpOutput | ConvertFrom-Json).Trim('"')
    
    $masterInstanceIdOutput = terraform output -json k3s_master_instance_id 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get master instance ID"
    }
    $masterInstanceId = ($masterInstanceIdOutput | ConvertFrom-Json).Trim('"')
    
    $workerIpsOutput = terraform output -json k3s_worker_private_ips 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get worker IPs"
    }
    $workerIps = $workerIpsOutput | ConvertFrom-Json
    $worker1Ip = $workerIps[0].Trim('"')
    $worker2Ip = $workerIps[1].Trim('"')
    
    $workerInstanceIdsOutput = terraform output -json k3s_worker_instance_ids 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get worker instance IDs"
    }
    $workerInstanceIds = $workerInstanceIdsOutput | ConvertFrom-Json
    $worker1InstanceId = $workerInstanceIds[0].Trim('"')
    $worker2InstanceId = $workerInstanceIds[1].Trim('"')
    
    if (-not $masterIp -or -not $masterInstanceId) {
        throw "Could not get required Terraform outputs"
    }
    
    Write-Host "  Master IP: $masterIp" -ForegroundColor Green
    Write-Host "  Master Instance ID: $masterInstanceId" -ForegroundColor Green
    Write-Host "  Worker 1 IP: $worker1Ip" -ForegroundColor Green
    Write-Host "  Worker 1 Instance ID: $worker1InstanceId" -ForegroundColor Green
    Write-Host "  Worker 2 IP: $worker2Ip" -ForegroundColor Green
    Write-Host "  Worker 2 Instance ID: $worker2InstanceId" -ForegroundColor Green
    Write-Host ""
    
} catch {
    Write-Host "Error: Could not get Terraform outputs: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

# Check AWS CLI
Write-Host "[2/5] Checking AWS CLI..." -ForegroundColor Cyan
$awsVersion = aws --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}
Write-Host "  $awsVersion" -ForegroundColor Green

# Deploy K3s Master
Write-Host "[3/5] Deploying K3s Master Node..." -ForegroundColor Cyan
Write-Host "  This may take 5-10 minutes..." -ForegroundColor Yellow

$masterScript = @"
#!/bin/bash
set -e

# Update system
sudo yum update -y

# Install required packages
sudo yum install -y curl wget vim net-tools

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe br_netfilter
sudo modprobe overlay

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Install K3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=latest sh -s - server \
  --cluster-init \
  --tls-san $masterIp \
  --node-ip $masterIp

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
timeout=300
elapsed=0
while [ ! -f /etc/rancher/k3s/k3s.yaml ] && [ $elapsed -lt $timeout ]; do
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
  echo "Error: K3s did not start in time"
  exit 1
fi

# Get K3s token
K3S_TOKEN=\$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo "K3S_TOKEN=\$K3S_TOKEN" > /tmp/k3s-token.txt

# Create .kube directory
mkdir -p /home/ec2-user/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube

# Update kubeconfig server URL
sed -i "s/127.0.0.1/$masterIp/g" /home/ec2-user/.kube/config

# Install kubectl
if [ ! -f /usr/local/bin/kubectl ]; then
  curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Verify installation
/usr/local/bin/k3s kubectl get nodes

echo "K3s Master deployed successfully!"
"@

# Split script into commands array for SSM
$masterCommands = $masterScript -split "`n" | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }

Write-Host "  Sending commands to master node..." -ForegroundColor Yellow
$masterParamsJson = @{
    commands = $masterCommands
} | ConvertTo-Json -Depth 10

$masterParamsFile = [System.IO.Path]::GetTempFileName()
$masterParamsJson | Out-File -FilePath $masterParamsFile -Encoding UTF8

aws ssm send-command `
    --instance-ids $masterInstanceId `
    --document-name "AWS-RunShellScript" `
    --cli-input-json "file://$masterParamsFile" `
    --region $Region `
    --output json | Out-Null

Remove-Item $masterParamsFile -ErrorAction SilentlyContinue

Write-Host "  Waiting for master deployment to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# Get K3s token from master
Write-Host "[4/5] Getting K3s token from master..." -ForegroundColor Cyan
$tokenCommand = "cat /tmp/k3s-token.txt"
$tokenResult = aws ssm send-command `
    --instance-ids $masterInstanceId `
    --document-name "AWS-RunShellScript" `
    --parameters "commands=[$tokenCommand]" `
    --region $Region `
    --output json | ConvertFrom-Json

Start-Sleep -Seconds 10
$commandId = $tokenResult.Command.CommandId
$tokenOutput = aws ssm get-command-invocation `
    --command-id $commandId `
    --instance-id $masterInstanceId `
    --region $Region `
    --output json | ConvertFrom-Json

$k3sToken = ($tokenOutput.StandardOutputContent -split "`n" | Where-Object { $_ -match "K3S_TOKEN=" }) -replace "K3S_TOKEN=", ""

if (-not $k3sToken) {
    Write-Host "  Warning: Could not get K3s token. Using default token." -ForegroundColor Yellow
    $k3sToken = "changeme-token-12345"
} else {
    Write-Host "  K3s token retrieved" -ForegroundColor Green
}

# Deploy K3s Workers
Write-Host "[5/5] Deploying K3s Worker Nodes..." -ForegroundColor Cyan

$workerScript = @"
#!/bin/bash
set -e

# Update system
sudo yum update -y

# Install required packages
sudo yum install -y curl wget vim net-tools

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Load kernel modules
sudo modprobe br_netfilter
sudo modprobe overlay

# Configure sysctl
cat <<EOF | sudo tee /etc/sysctl.d/k3s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# Install K3s agent
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=latest K3S_URL=https://$masterIp:6443 K3S_TOKEN=$k3sToken sh -s - agent \
  --node-ip WORKER_IP_PLACEHOLDER

echo "K3s Worker deployed successfully!"
"@

# Deploy worker 1
$worker1Script = $workerScript -replace "WORKER_IP_PLACEHOLDER", $worker1Ip
$worker1Commands = $worker1Script -split "`n" | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }

Write-Host "  Deploying worker 1..." -ForegroundColor Yellow
$worker1ParamsJson = @{
    commands = $worker1Commands
} | ConvertTo-Json -Depth 10

$worker1ParamsFile = [System.IO.Path]::GetTempFileName()
$worker1ParamsJson | Out-File -FilePath $worker1ParamsFile -Encoding UTF8

aws ssm send-command `
    --instance-ids $worker1InstanceId `
    --document-name "AWS-RunShellScript" `
    --cli-input-json "file://$worker1ParamsFile" `
    --region $Region `
    --output json | Out-Null

Remove-Item $worker1ParamsFile -ErrorAction SilentlyContinue

# Deploy worker 2
$worker2Script = $workerScript -replace "WORKER_IP_PLACEHOLDER", $worker2Ip
$worker2Commands = $worker2Script -split "`n" | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") }

Write-Host "  Deploying worker 2..." -ForegroundColor Yellow
$worker2ParamsJson = @{
    commands = $worker2Commands
} | ConvertTo-Json -Depth 10

$worker2ParamsFile = [System.IO.Path]::GetTempFileName()
$worker2ParamsJson | Out-File -FilePath $worker2ParamsFile -Encoding UTF8

aws ssm send-command `
    --instance-ids $worker2InstanceId `
    --document-name "AWS-RunShellScript" `
    --cli-input-json "file://$worker2ParamsFile" `
    --region $Region `
    --output json | Out-Null

Remove-Item $worker2ParamsFile -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "✅ K3s deployment commands sent!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 5-10 minutes for deployment to complete" -ForegroundColor White
Write-Host "  2. Get kubeconfig from master:" -ForegroundColor White
Write-Host "     aws ssm start-session --target $masterInstanceId --region $Region" -ForegroundColor Gray
Write-Host "     cat /home/ec2-user/.kube/config" -ForegroundColor Gray
Write-Host "  3. Or use kubectl via SSM:" -ForegroundColor White
Write-Host "     aws ssm send-command --instance-ids $masterInstanceId --document-name AWS-RunShellScript --parameters 'commands=[/usr/local/bin/k3s kubectl get nodes]' --region $Region" -ForegroundColor Gray

# No cleanup needed - using base64 encoding instead of temp files

