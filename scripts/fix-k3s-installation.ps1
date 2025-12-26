# Script to fix K3s installation on master node
# Usage: .\scripts\fix-k3s-installation.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$terraformDir = "infrastructure\terraform\environments\$Environment"

if (-not (Test-Path $terraformDir)) {
    Write-Host "Error: Terraform directory not found: $terraformDir" -ForegroundColor Red
    exit 1
}

Push-Location $terraformDir

try {
    # Get region from terraform.tfvars
    $tfvarsContent = Get-Content "terraform.tfvars" -Raw
    if ($tfvarsContent -match 'aws_region\s*=\s*"([^"]+)"') {
        $region = $matches[1]
    } else {
        $region = "ap-southeast-2"
    }
    
    # Get master instance ID and IP
    $masterIpOutput = terraform output -json k3s_master_public_ip 2>&1
    $masterIp = ($masterIpOutput | ConvertFrom-Json).Trim('"')
    
    $masterInstanceIdOutput = terraform output -json k3s_master_instance_id 2>&1
    $masterInstanceId = ($masterInstanceIdOutput | ConvertFrom-Json).Trim('"')
    
    Write-Host "=== Fixing K3s Installation ===" -ForegroundColor Cyan
    Write-Host "Region: $region" -ForegroundColor Yellow
    Write-Host "Master IP: $masterIp" -ForegroundColor Yellow
    Write-Host "Master Instance ID: $masterInstanceId" -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host "Error: Could not get Terraform outputs: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

# Create fix script
$fixScript = @"
#!/bin/bash
set -e

echo "=== Stopping existing K3s processes ==="
sudo pkill -9 k3s 2>&1 || true
sudo systemctl stop k3s 2>&1 || true
sleep 3

echo "=== Cleaning old data ==="
sudo rm -rf /var/lib/rancher/k3s/server/db/etcd/* 2>&1 || true
sudo mkdir -p /etc/rancher/k3s /var/lib/rancher/k3s/server/db/etcd

echo "=== Installing K3s with proper configuration ==="
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=latest sh -s - server \
  --cluster-init \
  --tls-san $masterIp \
  --node-ip $masterIp \
  --bind-address 0.0.0.0 \
  --disable traefik \
  --write-kubeconfig-mode 644 \
  --data-dir /var/lib/rancher/k3s

echo "=== Waiting for K3s to start (up to 3 minutes) ==="
timeout=180
elapsed=0
while [ ! -f /etc/rancher/k3s/k3s.yaml ] && [ $elapsed -lt $timeout ]; do
  sleep 5
  elapsed=`$((elapsed + 5))
  echo "Waiting... (`$elapsed seconds)"
done

if [ ! -f /etc/rancher/k3s/k3s.yaml ]; then
  echo "ERROR: K3s config file not created after `$timeout seconds"
  echo "Checking K3s service status..."
  systemctl status k3s --no-pager | head -30
  echo "Checking logs..."
  journalctl -u k3s --no-pager -n 50 | tail -50
  exit 1
fi

echo "=== Setting up kubeconfig ==="
mkdir -p /home/ec2-user/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sed -i "s/127.0.0.1/$masterIp/g" /home/ec2-user/.kube/config

echo "=== Verifying installation ==="
sleep 10
systemctl is-active k3s && echo "SERVICE_ACTIVE" || echo "SERVICE_INACTIVE"
netstat -tlnp | grep 6443 && echo "PORT_LISTENING" || echo "PORT_NOT_LISTENING"
test -f /etc/rancher/k3s/k3s.yaml && echo "CONFIG_EXISTS" || echo "CONFIG_MISSING"

echo "=== Testing kubectl ==="
/usr/local/bin/k3s kubectl get nodes 2>&1

echo "=== SUCCESS: K3s installation fixed! ==="
"@

# Convert script to commands array (handle both CRLF and LF)
$commands = $fixScript -split "`r?`n" | Where-Object { $_.Trim() -ne "" -and -not $_.StartsWith("#") } | ForEach-Object { $_.TrimEnd("`r") }

# Create JSON for SSM command
$jsonContent = @{
    InstanceIds = @($masterInstanceId)
    DocumentName = "AWS-RunShellScript"
    TimeoutSeconds = 600
    Parameters = @{
        commands = $commands
    }
} | ConvertTo-Json -Depth 10

$jsonFile = "$env:TEMP\fix-k3s-$(Get-Random).json"
[System.IO.File]::WriteAllText($jsonFile, $jsonContent, [System.Text.UTF8Encoding]::new($false))
$jsonUri = "file://" + ($jsonFile -replace '\\', '/')

Write-Host "Sending fix command to master node..." -ForegroundColor Yellow
$result = aws ssm send-command --cli-input-json $jsonUri --region $region --output json 2>&1
Remove-Item $jsonFile -ErrorAction SilentlyContinue

# Clean output
$clean = ($result -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''

try {
    $cmdId = ($clean | ConvertFrom-Json).Command.CommandId
    Write-Host "Command ID: $cmdId" -ForegroundColor Green
    Write-Host ""
    Write-Host "Waiting for K3s installation to complete (up to 5 minutes)..." -ForegroundColor Yellow
    Write-Host "This may take 3-5 minutes. Please wait..." -ForegroundColor Yellow
    Write-Host ""
    
    # Wait and check status
    $maxWait = 300
    $elapsed = 0
    $checkInterval = 30
    
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds $checkInterval
        $elapsed += $checkInterval
        
        $statusOutput = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterInstanceId --region $region --query "Status" --output text 2>&1
        $cleanStatus = ($statusOutput -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
        
        if ($cleanStatus -match "Success") {
            Write-Host "Command completed! Checking results..." -ForegroundColor Green
            break
        } elseif ($cleanStatus -match "Failed|TimedOut") {
            Write-Host "Command failed or timed out!" -ForegroundColor Red
            break
        }
        
        Write-Host "Still running... ($elapsed seconds)" -ForegroundColor Gray
    }
    
    # Get final output
    Write-Host ""
    Write-Host "=== Final Results ===" -ForegroundColor Cyan
    $finalOutput = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterInstanceId --region $region --output text 2>&1
    $cleanFinal = ($finalOutput -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
    
    if ($cleanFinal -match "SERVICE_ACTIVE") {
        Write-Host "SERVICE ACTIVE" -ForegroundColor Green
    }
    if ($cleanFinal -match "PORT_LISTENING") {
        Write-Host "PORT LISTENING" -ForegroundColor Green
    }
    if ($cleanFinal -match "CONFIG_EXISTS") {
        Write-Host "CONFIG EXISTS" -ForegroundColor Green
    }
    if ($cleanFinal -match "SUCCESS") {
        Write-Host "K3s installation fixed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next step: Get kubeconfig and test kubectl" -ForegroundColor Cyan
        Write-Host "  .\scripts\get-kubeconfig-simple.ps1 -Environment $Environment" -ForegroundColor White
    } else {
        Write-Host "WARNING: Installation may still be in progress or encountered errors" -ForegroundColor Yellow
        Write-Host "Check command output for details:" -ForegroundColor White
        Write-Host "  aws ssm get-command-invocation --command-id $cmdId --instance-id $masterInstanceId --region $region" -ForegroundColor Gray
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Raw output: $result" -ForegroundColor Gray
}

