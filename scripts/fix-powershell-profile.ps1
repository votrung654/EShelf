# Fix PowerShell profile to make aws command work
# Usage: .\scripts\fix-powershell-profile.ps1

Write-Host "Fixing PowerShell profile..." -ForegroundColor Cyan

$profilePath = $PROFILE
$profileDir = Split-Path $profilePath -Parent

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
if (-not (Test-Path $awsPath)) {
    $awsPath = "C:\Program Files (x86)\Amazon\AWSCLIV2\aws.exe"
}

if (-not (Test-Path $awsPath)) {
    Write-Host "[ERROR] AWS CLI not found!" -ForegroundColor Red
    exit 1
}

# Read existing profile
$existingContent = ""
if (Test-Path $profilePath) {
    $existingContent = Get-Content $profilePath -Raw
}

# Remove old AWS CLI code
$patternsToRemove = @(
    "Remove-Alias aws.*",
    "# AWS CLI.*",
    "function aws \{[^}]+\}"
)

$cleanedContent = $existingContent
foreach ($pattern in $patternsToRemove) {
    $cleanedContent = $cleanedContent -replace $pattern, ""
}

# Add new AWS CLI function
$newAwsCode = @"

# AWS CLI function (added by fix-powershell-profile.ps1)
# This makes aws command work by using direct path
if (Test-Path '$awsPath') {
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
}
"@

# Check if already added
if ($cleanedContent -notmatch "fix-powershell-profile") {
    $newContent = $cleanedContent.Trim() + "`n`n" + $newAwsCode
} else {
    $newContent = $cleanedContent
}

try {
    Set-Content -Path $profilePath -Value $newContent -Force -Encoding UTF8
    Write-Host "[OK] PowerShell profile fixed!" -ForegroundColor Green
    Write-Host "Profile location: $profilePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To use immediately, run:" -ForegroundColor Yellow
    Write-Host "  . `$PROFILE" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or restart PowerShell, then test:" -ForegroundColor Yellow
    Write-Host "  aws --version" -ForegroundColor Cyan
} catch {
    Write-Host "[ERROR] Could not fix profile: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual fix: Add this to $profilePath" -ForegroundColor Yellow
    Write-Host $newAwsCode -ForegroundColor Gray
}

Write-Host ""

