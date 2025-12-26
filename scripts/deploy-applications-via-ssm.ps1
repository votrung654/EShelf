# Deploy Applications via SSM
param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy Applications via SSM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get region - hardcode to avoid AWS CLI v1 issues
$region = "ap-southeast-2"
Write-Host "Using region: $region" -ForegroundColor Green

# Get master instance ID - hardcode known instance ID
$masterId = "i-0fba6eeba0cd77a15"
Write-Host "Using master instance: $masterId" -ForegroundColor Green

# Try to get from Terraform as fallback
if ($false) {  # Disabled to avoid AWS CLI issues
    Push-Location "infrastructure\terraform\environments\$Environment"
    try {
        $masterIdJson = terraform output -json k3s_master_instance_id 2>&1
        if ($LASTEXITCODE -eq 0) {
            $masterId = ($masterIdJson | ConvertFrom-Json).value
        }
    } catch {
        # Use hardcoded ID
    }
    Pop-Location
}

Write-Host "Master Instance: $masterId" -ForegroundColor Green
Write-Host ""

# Verify K3s is ready
Write-Host "[1/4] Verifying K3s cluster..." -ForegroundColor Yellow
$verifyCommands = @(
    "sudo systemctl is-active k3s",
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get nodes 2>&1"
)

$verifyJson = @{
    InstanceIds = @($masterId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $verifyCommands
    }
} | ConvertTo-Json -Depth 10

$verifyFile = "$env:TEMP\verify-k3s-$(Get-Random).json"
[System.IO.File]::WriteAllText($verifyFile, $verifyJson, [System.Text.UTF8Encoding]::new($false))
$verifyUri = "file://" + ($verifyFile -replace '\\', '/')

$resultRaw = aws ssm send-command --cli-input-json $verifyUri --region $region --output json 2>&1 | Out-String
$resultClean = ($resultRaw -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
$result = $resultClean | ConvertFrom-Json
$cmdId = $result.Command.CommandId
Write-Host "  Command ID: $cmdId" -ForegroundColor Gray
Start-Sleep -Seconds 15

$output = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json 2>&1 | Out-String -Width 4096
try {
    $outputObj = $output | ConvertFrom-Json
    if ($outputObj.StandardOutputContent) {
        Write-Host "`nCluster Status:" -ForegroundColor Cyan
        $outputObj.StandardOutputContent
    }
} catch {
    Write-Host "  Checking status..." -ForegroundColor Yellow
}
Remove-Item $verifyFile

# Deploy ArgoCD
Write-Host "`n[2/4] Deploying ArgoCD..." -ForegroundColor Yellow
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

$argocdFile = "$env:TEMP\deploy-argocd-$(Get-Random).json"
[System.IO.File]::WriteAllText($argocdFile, $argocdJson, [System.Text.UTF8Encoding]::new($false))
$argocdUri = "file://" + ($argocdFile -replace '\\', '/')

$resultRaw = aws ssm send-command --cli-input-json $argocdUri --region $region --output json 2>&1 | Out-String
$resultClean = ($resultRaw -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
$result = $resultClean | ConvertFrom-Json
$cmdId = $result.Command.CommandId
Write-Host "  Command ID: $cmdId" -ForegroundColor Gray
Write-Host "  Waiting 60s for ArgoCD to deploy..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

Remove-Item $argocdFile

# Deploy Monitoring namespace
Write-Host "`n[3/4] Creating Monitoring namespace..." -ForegroundColor Yellow
$monCommands = @(
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml create namespace monitoring --dry-run=client -o yaml | sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml apply -f -"
)

$monJson = @{
    InstanceIds = @($masterId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $monCommands
    }
} | ConvertTo-Json -Depth 10

$monFile = "$env:TEMP\deploy-mon-$(Get-Random).json"
[System.IO.File]::WriteAllText($monFile, $monJson, [System.Text.UTF8Encoding]::new($false))
$monUri = "file://" + ($monFile -replace '\\', '/')

$resultRaw = aws ssm send-command --cli-input-json $monUri --region $region --output json 2>&1 | Out-String
$resultClean = ($resultRaw -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
$result = $resultClean | ConvertFrom-Json
$cmdId = $result.Command.CommandId
Start-Sleep -Seconds 10

Remove-Item $monFile

# Final verification
Write-Host "`n[4/4] Verifying deployments..." -ForegroundColor Yellow
$finalCommands = @(
    "echo '=== Namespaces ==='",
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get namespaces | grep -E 'argocd|monitoring|harbor|default|kube-system'",
    "echo ''",
    "echo '=== ArgoCD Pods ==='",
    "sudo /usr/local/bin/k3s kubectl --kubeconfig=/etc/rancher/k3s/k3s.yaml get pods -n argocd 2>&1 | head -n 10"
)

$finalJson = @{
    InstanceIds = @($masterId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = $finalCommands
    }
} | ConvertTo-Json -Depth 10

$finalFile = "$env:TEMP\final-verify-$(Get-Random).json"
[System.IO.File]::WriteAllText($finalFile, $finalJson, [System.Text.UTF8Encoding]::new($false))
$finalUri = "file://" + ($finalFile -replace '\\', '/')

$resultRaw = aws ssm send-command --cli-input-json $finalUri --region $region --output json 2>&1 | Out-String
$resultClean = ($resultRaw -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
$result = $resultClean | ConvertFrom-Json
$cmdId = $result.Command.CommandId
Start-Sleep -Seconds 20

$outputRaw = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json 2>&1 | Out-String -Width 4096
$outputClean = ($outputRaw -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
try {
    $outputObj = $outputClean | ConvertFrom-Json
    Write-Host "`n=== Deployment Status ===" -ForegroundColor Green
    if ($outputObj.StandardOutputContent) {
        $outputObj.StandardOutputContent
    }
} catch {
    Write-Host "  Processing output..." -ForegroundColor Yellow
    Write-Host "  Raw output (first 500 chars): $($outputClean.Substring(0, [Math]::Min(500, $outputClean.Length)))" -ForegroundColor Gray
}
Remove-Item $finalFile

Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Get ArgoCD password:" -ForegroundColor White
Write-Host "     aws ssm start-session --target $masterId" -ForegroundColor Gray
Write-Host "     sudo /usr/local/bin/k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" -ForegroundColor Gray
Write-Host "  2. Port-forward ArgoCD:" -ForegroundColor White
Write-Host "     sudo /usr/local/bin/k3s kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Gray

