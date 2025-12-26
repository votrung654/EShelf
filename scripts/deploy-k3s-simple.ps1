# Simple script to deploy K3s via AWS SSM
# Uses inventory file and AWS CLI to get instance IDs

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Deploy K3s Cluster via AWS SSM" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Read inventory file
$inventoryPath = "infrastructure\ansible\inventory\$Environment.ini"
if (-not (Test-Path $inventoryPath)) {
    Write-Host "Error: Inventory file not found: $inventoryPath" -ForegroundColor Red
    exit 1
}

$inventory = Get-Content $inventoryPath
$masterIp = ($inventory | Where-Object { $_ -match "ansible_host=" -and $_ -match "master" }) -replace ".*ansible_host=([^\s]+).*", '$1'
$worker1Ip = ($inventory | Where-Object { $_ -match "ansible_host=" -and $_ -match "worker-1" }) -replace ".*ansible_host=([^\s]+).*", '$1'
$worker2Ip = ($inventory | Where-Object { $_ -match "ansible_host=" -and $_ -match "worker-2" }) -replace ".*ansible_host=([^\s]+).*", '$1'

Write-Host "[1/5] Getting instance IDs from AWS..." -ForegroundColor Cyan
# Get region from terraform.tfvars if available
$terraformDir = "infrastructure\terraform\environments\$Environment"
$currentRegion = "us-east-1" # Default
if (Test-Path "$terraformDir\terraform.tfvars") {
    $tfvarsContent = Get-Content "$terraformDir\terraform.tfvars" -Raw
    if ($tfvarsContent -match 'aws_region\s*=\s*"([^"]+)"') {
        $currentRegion = $matches[1]
    }
}
Write-Host "  Using region: $currentRegion" -ForegroundColor Cyan

# Try to get from Terraform output first
$terraformDir = "infrastructure\terraform\environments\$Environment"
if (Test-Path "$terraformDir\terraform.tfstate") {
    Push-Location $terraformDir
    try {
        $masterInstanceIdJson = terraform output -json k3s_master_instance_id 2>&1
        $workerInstanceIdsJson = terraform output -json k3s_worker_instance_ids 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $masterInstanceIdJson -match "i-") {
            $masterInstanceId = ($masterInstanceIdJson | ConvertFrom-Json).Trim('"')
            $workerInstanceIds = $workerInstanceIdsJson | ConvertFrom-Json
            $worker1InstanceId = $workerInstanceIds[0].Trim('"')
            $worker2InstanceId = $workerInstanceIds[1].Trim('"')
        } else {
            throw "Could not get from Terraform"
        }
    } catch {
        # Fallback to AWS query
        $masterInstanceId = aws ec2 describe-instances --region $currentRegion --filters "Name=ip-address,Values=$masterIp" --query "Reservations[*].Instances[*].InstanceId" --output text
        $worker1InstanceId = aws ec2 describe-instances --region $currentRegion --filters "Name=private-ip-address,Values=$worker1Ip" --query "Reservations[*].Instances[*].InstanceId" --output text
        $worker2InstanceId = aws ec2 describe-instances --region $currentRegion --filters "Name=private-ip-address,Values=$worker2Ip" --query "Reservations[*].Instances[*].InstanceId" --output text
    }
    Pop-Location
} else {
    # Query from AWS
    $masterInstanceId = aws ec2 describe-instances --region $currentRegion --filters "Name=ip-address,Values=$masterIp" --query "Reservations[*].Instances[*].InstanceId" --output text
    $worker1InstanceId = aws ec2 describe-instances --region $currentRegion --filters "Name=private-ip-address,Values=$worker1Ip" --query "Reservations[*].Instances[*].InstanceId" --output text
    $worker2InstanceId = aws ec2 describe-instances --region $currentRegion --filters "Name=private-ip-address,Values=$worker2Ip" --query "Reservations[*].Instances[*].InstanceId" --output text
}

Write-Host "  Master IP: $masterIp (Instance: $masterInstanceId)" -ForegroundColor Green
Write-Host "  Worker 1 IP: $worker1Ip (Instance: $worker1InstanceId)" -ForegroundColor Green
Write-Host "  Worker 2 IP: $worker2Ip (Instance: $worker2InstanceId)" -ForegroundColor Green
Write-Host ""

# Deploy K3s Master
Write-Host "[2/5] Deploying K3s Master Node..." -ForegroundColor Cyan
Write-Host "  This may take 5-10 minutes..." -ForegroundColor Yellow

$masterCommands = @(
    "sudo yum update -y",
    "sudo yum install -y curl wget vim net-tools",
    "sudo swapoff -a",
    "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab",
    "sudo modprobe br_netfilter",
    "sudo modprobe overlay",
    "echo 'net.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.d/k3s.conf",
    "echo 'net.bridge.bridge-nf-call-ip6tables = 1' | sudo tee -a /etc/sysctl.d/k3s.conf",
    "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/k3s.conf",
    "sudo sysctl --system",
    "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -s - server --cluster-init --tls-san $masterIp --node-ip $masterIp || wget -q -O - https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -s - server --cluster-init --tls-san $masterIp --node-ip $masterIp",
    "sleep 30",
    "sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s-token.txt",
    "mkdir -p /home/ec2-user/.kube",
    "sudo cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config",
    "sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube",
    "sed -i 's/127.0.0.1/$masterIp/g' /home/ec2-user/.kube/config",
    "if [ ! -f /usr/local/bin/kubectl ]; then curl -LO https://dl.k8s.io/release/`$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/; fi",
    "/usr/local/bin/k3s kubectl get nodes"
)

# Create full JSON structure for cli-input-json
$masterCommandJson = @{
    InstanceIds = @($masterInstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $masterCommands
    }
} | ConvertTo-Json -Depth 10

# Write to temp file with UTF8NoBOM encoding
$masterParamsFile = Join-Path $env:TEMP "k3s-master-params-$(Get-Random).json"
[System.IO.File]::WriteAllText($masterParamsFile, $masterCommandJson, [System.Text.UTF8Encoding]::new($false))

# Convert to forward slashes for AWS CLI
$masterParamsFileUri = "file://" + ($masterParamsFile -replace '\\', '/')

Write-Host "  Sending commands to master node..." -ForegroundColor Yellow
$masterResultJson = aws ssm send-command `
    --cli-input-json $masterParamsFileUri `
    --region $currentRegion `
    --output json 2>&1

Remove-Item $masterParamsFile -ErrorAction SilentlyContinue

if ($LASTEXITCODE -eq 0) {
    $masterResult = $masterResultJson | ConvertFrom-Json
} else {
    Write-Host "  Error: $masterResultJson" -ForegroundColor Red
    $masterResult = $null
}

if ($masterResult -and $masterResult.Command) {
    Write-Host "  Command sent. Command ID: $($masterResult.Command.CommandId)" -ForegroundColor Green
    Write-Host "  Waiting 2 minutes for master to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 120
} else {
    Write-Host "  Warning: Command may not have been sent successfully. Continuing anyway..." -ForegroundColor Yellow
    Write-Host "  Waiting 2 minutes for master to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 120
}

# Get K3s token
Write-Host "[3/5] Getting K3s token from master..." -ForegroundColor Cyan
$tokenCommandJson = @{
    InstanceIds = @($masterInstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = @("cat /tmp/k3s-token.txt")
    }
} | ConvertTo-Json -Depth 10

$tokenParamsFile = Join-Path $env:TEMP "k3s-token-params-$(Get-Random).json"
[System.IO.File]::WriteAllText($tokenParamsFile, $tokenCommandJson, [System.Text.UTF8Encoding]::new($false))
$tokenParamsFileUri = "file://" + ($tokenParamsFile -replace '\\', '/')

$tokenResultJson = aws ssm send-command `
    --cli-input-json $tokenParamsFileUri `
    --region $currentRegion `
    --output json 2>&1

Remove-Item $tokenParamsFile -ErrorAction SilentlyContinue

if ($LASTEXITCODE -eq 0) {
    $tokenResult = $tokenResultJson | ConvertFrom-Json
} else {
    Write-Host "  Warning: Could not send token retrieval command: $tokenResultJson" -ForegroundColor Yellow
    $tokenResult = $null
}

if ($commandId) {
    $tokenOutput = aws ssm get-command-invocation `
        --command-id $commandId `
        --instance-id $masterInstanceId `
        --region $currentRegion `
        --output json 2>&1 | ConvertFrom-Json

    if ($tokenOutput -and $tokenOutput.StandardOutputContent) {
        $k3sToken = $tokenOutput.StandardOutputContent.Trim()
        if (-not $k3sToken -or $k3sToken -match "No such file" -or $k3sToken.Length -lt 10) {
            Write-Host "  Warning: Could not get K3s token. You may need to wait longer or check manually." -ForegroundColor Yellow
            $k3sToken = "changeme-token-12345"
        } else {
            Write-Host "  K3s token retrieved: $($k3sToken.Substring(0, [Math]::Min(20, $k3sToken.Length)))..." -ForegroundColor Green
        }
    } else {
        Write-Host "  Warning: Could not get token output. Using default token." -ForegroundColor Yellow
        $k3sToken = "changeme-token-12345"
    }
} else {
    Write-Host "  Warning: Could not get command ID. Using default token." -ForegroundColor Yellow
    $k3sToken = "changeme-token-12345"
}

# Deploy Workers
Write-Host "[4/5] Deploying K3s Worker Nodes..." -ForegroundColor Cyan

$workerCommands = @(
    "sudo yum update -y",
    "sudo yum install -y curl wget vim net-tools",
    "sudo swapoff -a",
    "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab",
    "sudo modprobe br_netfilter",
    "sudo modprobe overlay",
    "echo 'net.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.d/k3s.conf",
    "echo 'net.bridge.bridge-nf-call-ip6tables = 1' | sudo tee -a /etc/sysctl.d/k3s.conf",
    "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/k3s.conf",
    "sudo sysctl --system"
)

# Worker 1
$worker1Commands = $workerCommands + @(
    "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 K3S_URL=https://$masterIp`:6443 K3S_TOKEN=$k3sToken sh -s - agent --node-ip $worker1Ip || wget -q -O - https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 K3S_URL=https://$masterIp`:6443 K3S_TOKEN=$k3sToken sh -s - agent --node-ip $worker1Ip"
)

# Format worker 1 commands
$worker1CommandJson = @{
    InstanceIds = @($worker1InstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $worker1Commands
    }
} | ConvertTo-Json -Depth 10

$worker1ParamsFile = Join-Path $env:TEMP "k3s-worker1-params-$(Get-Random).json"
[System.IO.File]::WriteAllText($worker1ParamsFile, $worker1CommandJson, [System.Text.UTF8Encoding]::new($false))
$worker1ParamsFileUri = "file://" + ($worker1ParamsFile -replace '\\', '/')

Write-Host "  Deploying worker 1..." -ForegroundColor Yellow
aws ssm send-command `
    --cli-input-json $worker1ParamsFileUri `
    --region $currentRegion `
    --output json 2>&1 | Out-Null

Remove-Item $worker1ParamsFile -ErrorAction SilentlyContinue

# Worker 2
$worker2Commands = $workerCommands + @(
    "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 K3S_URL=https://$masterIp`:6443 K3S_TOKEN=$k3sToken sh -s - agent --node-ip $worker2Ip || wget -q -O - https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 K3S_URL=https://$masterIp`:6443 K3S_TOKEN=$k3sToken sh -s - agent --node-ip $worker2Ip"
)

# Format worker 2 commands
$worker2CommandJson = @{
    InstanceIds = @($worker2InstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $worker2Commands
    }
} | ConvertTo-Json -Depth 10

$worker2ParamsFile = Join-Path $env:TEMP "k3s-worker2-params-$(Get-Random).json"
[System.IO.File]::WriteAllText($worker2ParamsFile, $worker2CommandJson, [System.Text.UTF8Encoding]::new($false))
$worker2ParamsFileUri = "file://" + ($worker2ParamsFile -replace '\\', '/')

Write-Host "  Deploying worker 2..." -ForegroundColor Yellow
aws ssm send-command `
    --cli-input-json $worker2ParamsFileUri `
    --region $currentRegion `
    --output json 2>&1 | Out-Null

Remove-Item $worker2ParamsFile -ErrorAction SilentlyContinue

Write-Host "[5/5] Deployment commands sent!" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ K3s deployment initiated!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Wait 5-10 minutes for deployment to complete" -ForegroundColor White
Write-Host "  2. Verify cluster status:" -ForegroundColor White
Write-Host "     aws ssm send-command --instance-ids $masterInstanceId --document-name AWS-RunShellScript --parameters '{\"commands\":[\"/usr/local/bin/k3s kubectl get nodes\"]}' --region $currentRegion" -ForegroundColor Gray
Write-Host "  3. Get kubeconfig:" -ForegroundColor White
Write-Host "     aws ssm start-session --target $masterInstanceId --region $currentRegion" -ForegroundColor Gray
Write-Host "     Then run: cat /home/ec2-user/.kube/config" -ForegroundColor Gray

