# Simple script to create AWS CLI alias in PowerShell profile
# This makes aws --version work normally by using direct path

Write-Host "Creating AWS CLI alias in PowerShell profile..." -ForegroundColor Cyan

$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (-not (Test-Path $awsPath)) {
    $awsPath = "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe"
}

if (-not (Test-Path $awsPath)) {
    Write-Host "[ERROR] AWS CLI not found!" -ForegroundColor Red
    exit 1
}

$profilePath = $PROFILE
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$aliasCode = @"

# AWS CLI alias (added by create-aws-alias.ps1)
# This makes aws command work by using direct path
if (Get-Command aws -ErrorAction SilentlyContinue) {
    Remove-Item Alias:aws -ErrorAction SilentlyContinue
}
function aws {
    param(
        [Parameter(ValueFromRemainingArguments=`$true)]
        [string[]]`$Arguments
    )
    & '$awsPath' @Arguments
}
"@

# Check if already exists
$existing = Get-Content $profilePath -ErrorAction SilentlyContinue | Select-String -Pattern "create-aws-alias"
if ($existing) {
    Write-Host "[INFO] Alias already exists in profile" -ForegroundColor Yellow
    Write-Host "Profile location: $profilePath" -ForegroundColor Gray
} else {
    try {
        Add-Content -Path $profilePath -Value $aliasCode -ErrorAction Stop
        Write-Host "[OK] Added AWS CLI alias to PowerShell profile" -ForegroundColor Green
        Write-Host "Profile location: $profilePath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "To use immediately, run:" -ForegroundColor Yellow
        Write-Host "  . `$PROFILE" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Or restart PowerShell, then test:" -ForegroundColor Yellow
        Write-Host "  aws --version" -ForegroundColor Cyan
    } catch {
        Write-Host "[ERROR] Could not add to profile: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Manual fix: Add this to $profilePath" -ForegroundColor Yellow
        Write-Host $aliasCode -ForegroundColor Gray
    }
}

Write-Host ""

