# Script to verify K3s cluster status via AWS SSM
# Usage: .\scripts\verify-k3s-cluster.ps1 -Environment dev

param(
    [string]$Environment = "dev"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Verify K3s Cluster Status" -ForegroundColor Cyan
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

Write-Host "[1/3] Getting master instance ID..." -ForegroundColor Cyan
$masterInstanceId = aws ec2 describe-instances --region us-east-1 --filters "Name=ip-address,Values=$masterIp" --query "Reservations[*].Instances[*].InstanceId" --output text
Write-Host "  Master Instance: $masterInstanceId" -ForegroundColor Green
Write-Host ""

# Check cluster nodes
Write-Host "[2/3] Checking cluster nodes..." -ForegroundColor Cyan
$checkNodesJson = @{
    InstanceIds = @($masterInstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = @("/usr/local/bin/k3s kubectl get nodes")
    }
} | ConvertTo-Json -Depth 10

$checkFile = Join-Path $env:TEMP "check-nodes-$(Get-Random).json"
[System.IO.File]::WriteAllText($checkFile, $checkNodesJson, [System.Text.UTF8Encoding]::new($false))
$checkUri = "file://" + ($checkFile -replace '\\', '/')

$checkResult = aws ssm send-command --cli-input-json $checkUri --region us-east-1 --output json 2>&1 | ConvertFrom-Json
Remove-Item $checkFile -ErrorAction SilentlyContinue

if ($checkResult -and $checkResult.Command) {
    $commandId = $checkResult.Command.CommandId
    Write-Host "  Command sent. Waiting for result..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    $output = aws ssm get-command-invocation --command-id $commandId --instance-id $masterInstanceId --region us-east-1 --output json 2>&1 | ConvertFrom-Json
    
    if ($output -and $output.StandardOutputContent) {
        Write-Host "`nCluster Nodes:" -ForegroundColor Green
        Write-Host $output.StandardOutputContent -ForegroundColor White
    } else {
        Write-Host "  Warning: Could not get node status yet. Cluster may still be deploying." -ForegroundColor Yellow
    }
} else {
    Write-Host "  Error: Could not send check command" -ForegroundColor Red
}

# Check pods
Write-Host "`n[3/3] Checking system pods..." -ForegroundColor Cyan
$checkPodsJson = @{
    InstanceIds = @($masterInstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = @("/usr/local/bin/k3s kubectl get pods -A")
    }
} | ConvertTo-Json -Depth 10

$podsFile = Join-Path $env:TEMP "check-pods-$(Get-Random).json"
[System.IO.File]::WriteAllText($podsFile, $checkPodsJson, [System.Text.UTF8Encoding]::new($false))
$podsUri = "file://" + ($podsFile -replace '\\', '/')

$podsResult = aws ssm send-command --cli-input-json $podsUri --region us-east-1 --output json 2>&1 | ConvertFrom-Json
Remove-Item $podsFile -ErrorAction SilentlyContinue

if ($podsResult -and $podsResult.Command) {
    $podsCommandId = $podsResult.Command.CommandId
    Start-Sleep -Seconds 10
    
    $podsOutput = aws ssm get-command-invocation --command-id $podsCommandId --instance-id $masterInstanceId --region us-east-1 --output json 2>&1 | ConvertFrom-Json
    
    if ($podsOutput -and $podsOutput.StandardOutputContent) {
        Write-Host "`nSystem Pods:" -ForegroundColor Green
        Write-Host $podsOutput.StandardOutputContent -ForegroundColor White
    }
}

Write-Host "`n✅ Verification complete!" -ForegroundColor Green
Write-Host "`nTo get kubeconfig:" -ForegroundColor Cyan
Write-Host "  aws ssm start-session --target $masterInstanceId --region us-east-1" -ForegroundColor Gray
Write-Host "  Then run: cat /home/ec2-user/.kube/config" -ForegroundColor Gray



