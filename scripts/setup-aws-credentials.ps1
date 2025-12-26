# Script to setup AWS CLI credentials from aws-academy-credentials.txt
# This script reads credentials from the file and configures AWS CLI

param(
    [string]$CredentialsFile = "aws-academy-credentials.txt"
)

Write-Host "Setting up AWS CLI credentials..." -ForegroundColor Cyan

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
$required = @('AWS_ACADEMY_URL', 'AWS_ACADEMY_USERNAME', 'AWS_ACADEMY_PASSWORD')
foreach ($key in $required) {
    if (-not $credentials.ContainsKey($key)) {
        Write-Host "ERROR: Missing required credential: $key" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Found credentials for: $($credentials['AWS_ACADEMY_USERNAME'])" -ForegroundColor Green
Write-Host "AWS Console URL: $($credentials['AWS_ACADEMY_URL'])" -ForegroundColor Green

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI version: $awsVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: AWS CLI is not installed" -ForegroundColor Red
    Write-Host "Please install AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Note: AWS Academy uses SSO login, not access keys
# We'll configure the profile but user needs to login via browser
Write-Host ""
Write-Host "IMPORTANT: AWS Academy uses SSO (Single Sign-On) login" -ForegroundColor Yellow
Write-Host "You need to login via browser using the credentials above" -ForegroundColor Yellow
Write-Host ""
Write-Host "To login:" -ForegroundColor Cyan
Write-Host "1. Open browser and go to: $($credentials['AWS_ACADEMY_URL'])" -ForegroundColor White
Write-Host "2. Username: $($credentials['AWS_ACADEMY_USERNAME'])" -ForegroundColor White
Write-Host "3. Password: $($credentials['AWS_ACADEMY_PASSWORD'])" -ForegroundColor White
Write-Host ""
Write-Host "After logging in, you can:" -ForegroundColor Cyan
Write-Host "- Use AWS Console in browser" -ForegroundColor White
Write-Host "- Get temporary credentials from IAM console" -ForegroundColor White
Write-Host "- Configure AWS CLI with temporary credentials" -ForegroundColor White
Write-Host ""

# Save credentials info to environment (for scripts to use)
$env:AWS_ACADEMY_URL = $credentials['AWS_ACADEMY_URL']
$env:AWS_ACADEMY_USERNAME = $credentials['AWS_ACADEMY_USERNAME']
$env:AWS_ACADEMY_PASSWORD = $credentials['AWS_ACADEMY_PASSWORD']

Write-Host "Credentials loaded to environment variables (for this session only)" -ForegroundColor Green
Write-Host "Run 'aws configure' manually to set up AWS CLI with temporary credentials" -ForegroundColor Yellow



