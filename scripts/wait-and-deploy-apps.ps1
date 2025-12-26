# Wait for K3s to be ready and deploy applications
param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Wait for K3s and Deploy Applications" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$region = aws configure get region
$masterId = aws ec2 describe-instances --region $region --filters "Name=tag:Name,Values=eshelf-k3s-master-dev" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text

if (-not $masterId -or $masterId -eq "None") {
    Write-Host "Error: Could not get master instance ID" -ForegroundColor Red
    exit 1
}

Write-Host "Master Instance: $masterId" -ForegroundColor Green
Write-Host ""

# Wait for K3s to be ready
Write-Host "[1/3] Waiting for K3s to be ready..." -ForegroundColor Yellow
$maxWait = 30
$waitCount = 0

while ($waitCount -lt $maxWait) {
    $checkCommands = @(
        "if [ -f /etc/rancher/k3s/k3s.yaml ]; then echo 'READY'; sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes 2>&1 | head -n 5; else echo 'NOT_READY'; fi"
    )
    
    $checkJson = @{
        InstanceIds = @($masterId)
        DocumentName = "AWS-RunShellScript"
        Parameters = @{
            commands = $checkCommands
        }
    } | ConvertTo-Json -Depth 10
    
    $checkFile = "$env:TEMP\check-k3s-$(Get-Random).json"
    [System.IO.File]::WriteAllText($checkFile, $checkJson, [System.Text.UTF8Encoding]::new($false))
    $checkUri = "file://" + ($checkFile -replace '\\', '/')
    
    $result = aws ssm send-command --cli-input-json $checkUri --region $region --output json | ConvertFrom-Json
    $cmdId = $result.Command.CommandId
    Start-Sleep -Seconds 15
    
    $output = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json 2>&1 | Out-String -Width 4096
    
    try {
        $outputObj = $output | ConvertFrom-Json
        if ($outputObj.StandardOutputContent -and $outputObj.StandardOutputContent -match "READY") {
            Write-Host "`n✅ K3s is ready!" -ForegroundColor Green
            if ($outputObj.StandardOutputContent) {
                $outputObj.StandardOutputContent | Select-String -Pattern "NAME|STATUS|ROLES|Ready" -Context 0,0
            }
            Remove-Item $checkFile
            break
        }
    } catch {
    }
    
    $waitCount++
    Write-Host "  Waiting... ($waitCount/$maxWait)" -ForegroundColor Gray
    Start-Sleep -Seconds 30
    Remove-Item $checkFile -ErrorAction SilentlyContinue
}

if ($waitCount -eq $maxWait) {
    Write-Host "`n⚠️  K3s not ready after $maxWait attempts" -ForegroundColor Yellow
    Write-Host "Please check K3s service manually:" -ForegroundColor White
    Write-Host "  aws ssm start-session --target $masterId" -ForegroundColor Gray
    Write-Host "  sudo systemctl status k3s" -ForegroundColor Gray
    exit 1
}

# Deploy ArgoCD
Write-Host "`n[2/3] Deploying ArgoCD..." -ForegroundColor Yellow
$argocdCommands = @(
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml create namespace argocd --dry-run=client -o yaml | sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml apply -f -",
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml 2>&1 | head -n 30"
)

$argocdJson = @{
    InstanceIds = @($masterId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $argocdCommands
    }
} | ConvertTo-Json -Depth 10

$argocdFile = "$env:TEMP\deploy-argocd-wait.json"
[System.IO.File]::WriteAllText($argocdFile, $argocdJson, [System.Text.UTF8Encoding]::new($false))
$argocdUri = "file://" + ($argocdFile -replace '\\', '/')

$result = aws ssm send-command --cli-input-json $argocdUri --region $region --output json | ConvertFrom-Json
$cmdId = $result.Command.CommandId
Write-Host "  Command ID: $cmdId" -ForegroundColor Gray
Write-Host "  Waiting 60s for ArgoCD..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Remove-Item $argocdFile

# Verify
Write-Host "`n[3/3] Verifying deployments..." -ForegroundColor Yellow
$verifyCommands = @(
    "echo '=== Namespaces ==='",
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get namespaces | grep -E 'argocd|monitoring|default|kube-system'",
    "echo ''",
    "echo '=== ArgoCD Pods ==='",
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -n argocd 2>&1 | head -n 10"
)

$verifyJson = @{
    InstanceIds = @($masterId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $verifyCommands
    }
} | ConvertTo-Json -Depth 10

$verifyFile = "$env:TEMP\verify-wait.json"
[System.IO.File]::WriteAllText($verifyFile, $verifyJson, [System.Text.UTF8Encoding]::new($false))
$verifyUri = "file://" + ($verifyFile -replace '\\', '/')

$result = aws ssm send-command --cli-input-json $verifyUri --region $region --output json | ConvertFrom-Json
$cmdId = $result.Command.CommandId
Start-Sleep -Seconds 20

$output = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json 2>&1 | Out-String -Width 4096
try {
    $outputObj = $output | ConvertFrom-Json
    Write-Host "`n=== Deployment Status ===" -ForegroundColor Green
    if ($outputObj.StandardOutputContent) {
        $outputObj.StandardOutputContent
    }
} catch {
    Write-Host "  Processing..." -ForegroundColor Yellow
}
Remove-Item $verifyFile

Write-Host "`n✅ Deployment process completed!" -ForegroundColor Green



