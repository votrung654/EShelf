# AWS CLI wrapper function to prevent hanging
# Source this file in your PowerShell profile or run: . .\scripts\aws-wrapper.ps1

function aws {
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
    
    if (-not (Test-Path $awsPath)) {
        Write-Error "AWS CLI not found at $awsPath"
        return
    }
    
    # For --version, use timeout
    if ($Arguments -contains "--version") {
        try {
            $job = Start-Job -ScriptBlock {
                param($Path)
                & $Path --version 2>&1 | Select-Object -First 1
            } -ArgumentList $awsPath
            
            $result = Wait-Job $job -Timeout 5
            if ($result) {
                Receive-Job $job
                Remove-Job $job -Force
            } else {
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -Force
                Write-Error "AWS CLI command timed out"
            }
        } catch {
            Write-Error "Error running AWS CLI: $_"
        }
    } else {
        # For other commands, use direct path
        & $awsPath @Arguments
    }
}
