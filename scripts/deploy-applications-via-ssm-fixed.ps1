# Deploy Applications via SSM (Fixed for AWS CLI v1)
param(
    [string]$Environment = "dev"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploy Applications via SSM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Hardcode region and instance ID to avoid AWS CLI v1 issues
$region = "ap-southeast-2"
$masterId = "i-0fba6eeba0cd77a15"

Write-Host "Region: $region" -ForegroundColor Green
Write-Host "Master Instance: $masterId" -ForegroundColor Green
Write-Host ""

# Helper function to clean AWS CLI output
function Clean-AwsOutput {
    param([string]$Output)
    $clean = ($Output -replace 'File association[^\}]*', '') -replace '[\u0000-\u001F]', ''
    return $clean
}

# Helper function to invoke AWS CLI and parse JSON
function Invoke-AwsCliJson {
    param(
        [string]$Command,
        [string]$Region
    )
    $raw = Invoke-Expression "$Command 2>&1" | Out-String
    $clean = Clean-AwsOutput -Output $raw
    try {
        return $clean | ConvertFrom-Json
    } catch {
        Write-Host "JSON parse error. Raw output: $($clean.Substring(0, [Math]::Min(200, $clean.Length)))" -ForegroundColor Yellow
        throw
    }
}

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

try {
    $result = Invoke-AwsCliJson -Command "aws ssm send-command --cli-input-json $verifyUri --region $region --output json" -Region $region
    $cmdId = $result.Command.CommandId
    Write-Host "  Command ID: $cmdId" -ForegroundColor Gray
    Start-Sleep -Seconds 15

    $output = Invoke-AwsCliJson -Command "aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json" -Region $region
    if ($output.StandardOutputContent) {
        Write-Host "`nCluster Status:" -ForegroundColor Cyan
        Write-Host $output.StandardOutputContent
    }
} catch {
    Write-Host "  Warning: Could not verify cluster status" -ForegroundColor Yellow
}
Remove-Item $verifyFile -ErrorAction SilentlyContinue

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

try {
    $result = Invoke-AwsCliJson -Command "aws ssm send-command --cli-input-json $argocdUri --region $region --output json" -Region $region
    $cmdId = $result.Command.CommandId
    Write-Host "  Command ID: $cmdId" -ForegroundColor Gray
    Write-Host "  Waiting 60s for ArgoCD to deploy..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
} catch {
    Write-Host "  Error deploying ArgoCD: $_" -ForegroundColor Red
}
Remove-Item $argocdFile -ErrorAction SilentlyContinue

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

try {
    $result = Invoke-AwsCliJson -Command "aws ssm send-command --cli-input-json $monUri --region $region --output json" -Region $region
    $cmdId = $result.Command.CommandId
    Start-Sleep -Seconds 10
} catch {
    Write-Host "  Error creating monitoring namespace: $_" -ForegroundColor Yellow
}
Remove-Item $monFile -ErrorAction SilentlyContinue

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

try {
    $result = Invoke-AwsCliJson -Command "aws ssm send-command --cli-input-json $finalUri --region $region --output json" -Region $region
    $cmdId = $result.Command.CommandId
    Start-Sleep -Seconds 20

    $output = Invoke-AwsCliJson -Command "aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json" -Region $region
    Write-Host "`n=== Deployment Status ===" -ForegroundColor Green
    if ($output.StandardOutputContent) {
        Write-Host $output.StandardOutputContent
    }
} catch {
    Write-Host "  Could not get final status" -ForegroundColor Yellow
}
Remove-Item $finalFile -ErrorAction SilentlyContinue

Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Get ArgoCD password (via SSM session):" -ForegroundColor White
Write-Host "     sudo /usr/local/bin/k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" -ForegroundColor Gray
Write-Host "  2. Port-forward ArgoCD (via SSM session):" -ForegroundColor White
Write-Host "     sudo /usr/local/bin/k3s kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Gray

