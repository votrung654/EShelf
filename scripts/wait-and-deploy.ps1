# Script to wait for cluster to be ready and then deploy applications
# Usage: .\scripts\wait-and-deploy.ps1 -Environment dev

param(
    [string]$Environment = "dev",
    [int]$MaxWaitMinutes = 15
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Wait for Cluster and Deploy Applications" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$inventoryPath = "infrastructure\ansible\inventory\$Environment.ini"
$inventory = Get-Content $inventoryPath
$masterIp = ($inventory | Where-Object { $_ -match "ansible_host=" -and $_ -match "master" }) -replace ".*ansible_host=([^\s]+).*", '$1'
$masterInstanceId = aws ec2 describe-instances --region us-east-1 --filters "Name=ip-address,Values=$masterIp" --query "Reservations[*].Instances[*].InstanceId" --output text

Write-Host "Master Instance: $masterInstanceId" -ForegroundColor Green
Write-Host "Max wait time: $MaxWaitMinutes minutes" -ForegroundColor Yellow
Write-Host ""

$startTime = Get-Date
$elapsed = 0
$clusterReady = $false

while ($elapsed -lt ($MaxWaitMinutes * 60) -and -not $clusterReady) {
    Write-Host "[$([Math]::Floor($elapsed/60))m $($elapsed%60)s] Checking cluster status..." -ForegroundColor Cyan
    
    # Check if k3s is installed
    $checkK3sJson = @{
        InstanceIds = @($masterInstanceId)
        DocumentName = "AWS-RunShellScript"
        Parameters = @{
            commands = @("test -f /usr/local/bin/k3s && echo 'K3s installed' || echo 'Not installed'")
        }
    } | ConvertTo-Json -Depth 10
    
    $checkFile = Join-Path $env:TEMP "check-k3s-$(Get-Random).json"
    [System.IO.File]::WriteAllText($checkFile, $checkK3sJson, [System.Text.UTF8Encoding]::new($false))
    $checkUri = "file://" + ($checkFile -replace '\\', '/')
    
    $checkResult = aws ssm send-command --cli-input-json $checkUri --region us-east-1 --output json 2>&1 | ConvertFrom-Json
    Remove-Item $checkFile -ErrorAction SilentlyContinue
    
    if ($checkResult -and $checkResult.Command) {
        Start-Sleep -Seconds 5
        $output = aws ssm get-command-invocation --command-id $checkResult.Command.CommandId --instance-id $masterInstanceId --region us-east-1 --output json 2>&1 | ConvertFrom-Json
        
        if ($output -and $output.StandardOutputContent -match "K3s installed") {
            Write-Host "  K3s is installed. Checking cluster..." -ForegroundColor Yellow
            
            # Check cluster nodes
            $checkNodesJson = @{
                InstanceIds = @($masterInstanceId)
                DocumentName = "AWS-RunShellScript"
                Parameters = @{
                    commands = @("/usr/local/bin/k3s kubectl get nodes --no-headers 2>&1 | wc -l")
                }
            } | ConvertTo-Json -Depth 10
            
            $nodesFile = Join-Path $env:TEMP "check-nodes-$(Get-Random).json"
            [System.IO.File]::WriteAllText($nodesFile, $checkNodesJson, [System.Text.UTF8Encoding]::new($false))
            $nodesUri = "file://" + ($nodesFile -replace '\\', '/')
            
            $nodesResult = aws ssm send-command --cli-input-json $nodesUri --region us-east-1 --output json 2>&1 | ConvertFrom-Json
            Remove-Item $nodesFile -ErrorAction SilentlyContinue
            
            if ($nodesResult -and $nodesResult.Command) {
                Start-Sleep -Seconds 5
                $nodesOutput = aws ssm get-command-invocation --command-id $nodesResult.Command.CommandId --instance-id $masterInstanceId --region us-east-1 --output json 2>&1 | ConvertFrom-Json
                
                if ($nodesOutput -and $nodesOutput.StandardOutputContent) {
                    $nodeCount = [int]($nodesOutput.StandardOutputContent.Trim())
                    if ($nodeCount -ge 1) {
                        Write-Host "  ✅ Cluster is ready! Found $nodeCount node(s)" -ForegroundColor Green
                        $clusterReady = $true
                    } else {
                        Write-Host "  Cluster still initializing..." -ForegroundColor Yellow
                    }
                }
            }
        } else {
            Write-Host "  K3s not installed yet..." -ForegroundColor Yellow
        }
    }
    
    if (-not $clusterReady) {
        Write-Host "  Waiting 30 seconds before next check..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
    }
}

if ($clusterReady) {
    Write-Host "`n✅ Cluster is ready! Getting kubeconfig..." -ForegroundColor Green
    .\scripts\get-kubeconfig.ps1 -Environment $Environment
    
    Write-Host "`nDeploying applications..." -ForegroundColor Cyan
    .\scripts\deploy-applications.ps1 -Environment $Environment
} else {
    Write-Host "`n⚠️  Cluster not ready after $MaxWaitMinutes minutes." -ForegroundColor Yellow
    Write-Host "You can check manually:" -ForegroundColor Cyan
    Write-Host "  aws ssm start-session --target $masterInstanceId --region us-east-1" -ForegroundColor Gray
    Write-Host "  /usr/local/bin/k3s kubectl get nodes" -ForegroundColor Gray
}



