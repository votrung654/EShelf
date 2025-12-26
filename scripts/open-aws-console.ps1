# Script to open AWS Academy Console in browser
# This script reads credentials and opens the console URL

param(
    [string]$CredentialsFile = "aws-academy-credentials.txt"
)

Write-Host "Opening AWS Academy Console..." -ForegroundColor Cyan

# Check if credentials file exists
if (-not (Test-Path $CredentialsFile)) {
    Write-Host "ERROR: Credentials file not found: $CredentialsFile" -ForegroundColor Red
    Write-Host "Please create the file using aws-academy-credentials.example.txt as template" -ForegroundColor Yellow
    exit 1
}

# Read credentials file
$credentials = @{}
Get-Content $CredentialsFile | ForEach-Object {
    if ($_ -match '^([^#=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $credentials[$key] = $value
    }
}

# Check required fields
if (-not $credentials.ContainsKey('AWS_ACADEMY_URL')) {
    Write-Host "ERROR: Missing AWS_ACADEMY_URL in credentials file" -ForegroundColor Red
    exit 1
}

$consoleUrl = $credentials['AWS_ACADEMY_URL']
$username = if ($credentials.ContainsKey('AWS_ACADEMY_USERNAME')) { $credentials['AWS_ACADEMY_USERNAME'] } else { "" }
$password = if ($credentials.ContainsKey('AWS_ACADEMY_PASSWORD')) { $credentials['AWS_ACADEMY_PASSWORD'] } else { "" }

Write-Host ""
Write-Host "AWS Academy Console URL: $consoleUrl" -ForegroundColor Green
if ($username) {
    Write-Host "Username: $username" -ForegroundColor Green
}
if ($password) {
    Write-Host "Password: [Hidden - check credentials file]" -ForegroundColor Yellow
}
Write-Host ""

# Open browser
Write-Host "Opening browser..." -ForegroundColor Cyan
Start-Process $consoleUrl

Write-Host ""
Write-Host "Browser opened! Please:" -ForegroundColor Cyan
Write-Host "1. Login with the credentials above" -ForegroundColor White
Write-Host "2. After login, you can:" -ForegroundColor White
Write-Host "   - Use AWS Console directly" -ForegroundColor Gray
Write-Host "   - Get temporary credentials from IAM console for AWS CLI" -ForegroundColor Gray
Write-Host "   - Use CloudShell for command-line access" -ForegroundColor Gray
Write-Host ""



