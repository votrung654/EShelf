# Simple script to get kubeconfig - handles AWS CLI v1 issues
param(
    [string]$Environment = "dev"
)

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Get region and master instance ID from terraform
$terraformDir = "infrastructure\terraform\environments\$Environment"
Push-Location $terraformDir
try {
    $region = (Get-Content "terraform.tfvars" -Raw | Select-String -Pattern 'aws_region\s*=\s*"([^"]+)"').Matches.Groups[1].Value
    if (-not $region) { $region = "ap-southeast-2" }
    
    $masterId = (terraform output -json k3s_master_instance_id 2>&1 | ConvertFrom-Json).Trim('"')
} finally {
    Pop-Location
}

Write-Host "Region: $region, Master: $masterId" -ForegroundColor Cyan

# Create JSON file for SSM command
$jsonContent = @{
    InstanceIds = @($masterId)
    DocumentName = "AWS-RunShellScript"
    Parameters = @{
        commands = @("cat /home/ec2-user/.kube/config 2>/dev/null || echo 'KUBECONFIG_NOT_FOUND'")
    }
} | ConvertTo-Json -Depth 10

$jsonFile = "$env:TEMP\get-kubeconfig-$(Get-Random).json"
[System.IO.File]::WriteAllText($jsonFile, $jsonContent, [System.Text.UTF8Encoding]::new($false))
$jsonUri = "file://" + ($jsonFile -replace '\\', '/')

Write-Host "Sending SSM command..." -ForegroundColor Yellow

# Send command and capture output differently
$cmdOutput = aws ssm send-command --cli-input-json $jsonUri --region $region --output json 2>&1
Remove-Item $jsonFile -ErrorAction SilentlyContinue

# Remove "File association" error message if present
$cleanOutput = $cmdOutput -replace 'File association not found for extension \.py\s*', ''

# Parse command ID from output (handle both JSON and text output)
$cmdId = $null
# Try to parse as JSON first
try {
    $jsonObj = $cleanOutput | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($jsonObj -and $jsonObj.Command -and $jsonObj.Command.CommandId) {
        $cmdId = $jsonObj.Command.CommandId
    }
} catch {
    # If JSON parse fails, try regex
    if ($cleanOutput -match '"CommandId"\s*:\s*"([a-f0-9-]{36})"') {
        $cmdId = $matches[1]
    } elseif ($cleanOutput -match '([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})') {
        $cmdId = $matches[1]
    }
}

if ($cmdId) {
    Write-Host "Command ID: $cmdId" -ForegroundColor Green
    Write-Host "Waiting for result..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Get command result
    $resultRaw = aws ssm get-command-invocation --command-id $cmdId --instance-id $masterId --region $region --output json 2>&1
    $result = $resultRaw -replace 'File association not found for extension \.py\s*', ''
    
    # Parse kubeconfig from result
    $kubeconfig = $null
    try {
        $resultObj = $result | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($resultObj -and $resultObj.StandardOutputContent) {
            $kubeconfig = $resultObj.StandardOutputContent
        }
    } catch {
        # Try regex if JSON parse fails
        if ($result -match '"StandardOutputContent"\s*:\s*"([^"]+)"') {
            $kubeconfig = $matches[1] -replace '\\n', "`n" -replace '\\"', '"'
        }
    }
    
    if ($kubeconfig -and $kubeconfig -notmatch "KUBECONFIG_NOT_FOUND" -and $kubeconfig.Length -gt 100) {
        # Save kubeconfig
        $kubeDir = "$env:USERPROFILE\.kube"
        if (-not (Test-Path $kubeDir)) {
            New-Item -ItemType Directory -Path $kubeDir -Force | Out-Null
        }
        
        $kubeconfigPath = "$kubeDir\config"
        $kubeconfig | Out-File -FilePath $kubeconfigPath -Encoding UTF8 -NoNewline
        
        Write-Host "`n✅ Kubeconfig saved to: $kubeconfigPath" -ForegroundColor Green
        Write-Host "Try: kubectl get nodes" -ForegroundColor Cyan
    } else {
        Write-Host "K3s may not be deployed yet. Please wait and try again." -ForegroundColor Yellow
        if ($result) {
            Write-Host "Raw result preview: $($result.Substring(0, [Math]::Min(200, $result.Length)))" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "Could not get command ID. Output: $cmdOutput" -ForegroundColor Red
}

