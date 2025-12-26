# Quick test for AWS CLI version (safe version with timeout)
param(
    [string]$AWSPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
)

if (Test-Path $AWSPath) {
    Write-Host "Testing AWS CLI..." -ForegroundColor Cyan
    $job = Start-Job -ScriptBlock {
        param($Path)
        & $Path --version 2>&1 | Select-Object -First 1
    } -ArgumentList $AWSPath
    
    $result = Wait-Job $job -Timeout 5
    if ($result) {
        $output = Receive-Job $job
        Remove-Job $job -Force
        Write-Host $output -ForegroundColor Green
    } else {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force
        Write-Host "AWS CLI command timed out!" -ForegroundColor Red
    }
} else {
    Write-Host "AWS CLI not found at: $AWSPath" -ForegroundColor Red
}
