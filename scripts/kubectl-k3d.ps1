# Wrapper script để dùng kubectl với k3d cluster từ container
# Usage: .\scripts\kubectl-k3d.ps1 <kubectl-command>

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$KubectlArgs
)

$clusterName = "eshelf-cluster"
$serverContainer = "k3d-$clusterName-server-0"

if ($KubectlArgs.Count -eq 0) {
    Write-Host "Usage: .\scripts\kubectl-k3d.ps1 <kubectl-command>" -ForegroundColor Yellow
    Write-Host "Example: .\scripts\kubectl-k3d.ps1 get nodes" -ForegroundColor Yellow
    exit 1
}

$command = $KubectlArgs -join " "
docker exec $serverContainer kubectl $command

