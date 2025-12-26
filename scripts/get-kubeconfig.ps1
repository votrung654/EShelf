# Script to get kubeconfig from K3s master node
# Usage: .\scripts\get-kubeconfig.ps1 -Environment dev

param(
    [string]$Environment = "dev",
    [string]$Region = ""
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Get Kubeconfig from K3s Master" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get region from terraform if not provided
if (-not $Region) {
    $tfvarsPath = "infrastructure\terraform\environments\$Environment\terraform.tfvars"
    if (Test-Path $tfvarsPath) {
        $tfvarsContent = Get-Content $tfvarsPath -Raw
        if ($tfvarsContent -match 'aws_region\s*=\s*"([^"]+)"') {
            $Region = $matches[1]
        }
    }
    if (-not $Region) {
        $Region = "us-east-1" # Default fallback
    }
}

# Get master instance ID from terraform output
Write-Host "[1/2] Getting master instance ID from Terraform..." -ForegroundColor Cyan
Push-Location "infrastructure\terraform\environments\$Environment"
try {
    $masterInstanceIdOutput = terraform output -json k3s_master_instance_id 2>&1
    if ($LASTEXITCODE -eq 0) {
        $masterInstanceId = ($masterInstanceIdOutput | ConvertFrom-Json).Trim('"')
    } else {
        throw "Could not get master instance ID from terraform"
    }
} catch {
    Write-Host "Error: Could not get master instance ID: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}
Write-Host "  Master Instance: $masterInstanceId" -ForegroundColor Green
Write-Host ""

# Get kubeconfig
Write-Host "[2/2] Retrieving kubeconfig..." -ForegroundColor Cyan
$getKubeconfigJson = @{
    InstanceIds = @($masterInstanceId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = @("cat /home/ec2-user/.kube/config")
    }
} | ConvertTo-Json -Depth 10

$kubeconfigFile = Join-Path $env:TEMP "get-kubeconfig-$(Get-Random).json"
[System.IO.File]::WriteAllText($kubeconfigFile, $getKubeconfigJson, [System.Text.UTF8Encoding]::new($false))
$kubeconfigUri = "file://" + ($kubeconfigFile -replace '\\', '/')

$kubeconfigResult = aws ssm send-command --cli-input-json $kubeconfigUri --region $Region --output json 2>&1 | ConvertFrom-Json
Remove-Item $kubeconfigFile -ErrorAction SilentlyContinue

if ($kubeconfigResult -and $kubeconfigResult.Command) {
    $commandId = $kubeconfigResult.Command.CommandId
    Write-Host "  Command sent. Waiting for result..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    $output = aws ssm get-command-invocation --command-id $commandId --instance-id $masterInstanceId --region $Region --output json 2>&1 | ConvertFrom-Json
    
    if ($output -and $output.StandardOutputContent) {
        $kubeconfigContent = $output.StandardOutputContent
        
        # Create .kube directory if it doesn't exist
        $kubeDir = "$env:USERPROFILE\.kube"
        if (-not (Test-Path $kubeDir)) {
            New-Item -ItemType Directory -Path $kubeDir -Force | Out-Null
        }
        
        # Save kubeconfig
        $kubeconfigPath = "$kubeDir\config"
        $kubeconfigContent | Out-File -FilePath $kubeconfigPath -Encoding UTF8 -NoNewline
        
        Write-Host "`n✅ Kubeconfig saved to: $kubeconfigPath" -ForegroundColor Green
        Write-Host "`nYou can now use kubectl commands!" -ForegroundColor Cyan
        Write-Host "  Try: kubectl get nodes" -ForegroundColor Gray
    } else {
        Write-Host "  Warning: Could not get kubeconfig. Cluster may still be deploying." -ForegroundColor Yellow
        Write-Host "  You can try manually:" -ForegroundColor Yellow
        Write-Host "    aws ssm start-session --target $masterInstanceId --region $Region" -ForegroundColor Gray
        Write-Host "    cat /home/ec2-user/.kube/config" -ForegroundColor Gray
    }
} else {
    Write-Host "  Error: Could not send command" -ForegroundColor Red
}



