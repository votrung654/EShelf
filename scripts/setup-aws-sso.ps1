# Script to setup AWS CLI with SSO for AWS Academy
# This script configures AWS SSO CLI profile for AWS Academy

param(
    [string]$CredentialsFile = "aws-academy-credentials.txt",
    [string]$ProfileName = "aws-academy",
    [string]$Region = "us-east-1"
)

Write-Host "Setting up AWS SSO CLI for AWS Academy..." -ForegroundColor Cyan
Write-Host ""

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

# Extract account ID from URL
$url = $credentials['AWS_ACADEMY_URL']
if ($url -match 'https://(\d+)\.signin\.aws\.amazon\.com') {
    $accountId = $matches[1]
    Write-Host "Detected AWS Account ID: $accountId" -ForegroundColor Green
}
else {
    Write-Host "WARNING: Could not extract account ID from URL" -ForegroundColor Yellow
    $accountId = "YOUR_ACCOUNT_ID"
}

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version 2>&1
    Write-Host "AWS CLI version: $awsVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: AWS CLI is not installed" -ForegroundColor Red
    Write-Host "Please install AWS CLI v2: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AWS Academy SSO Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "AWS Academy sử dụng SSO (Single Sign-On) để đăng nhập." -ForegroundColor Yellow
Write-Host "Có 2 cách để sử dụng AWS CLI với AWS Academy:" -ForegroundColor Yellow
Write-Host ""

Write-Host "CÁCH 1: Sử dụng AWS SSO CLI (Khuyến nghị)" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Bước 1: Configure SSO profile" -ForegroundColor Cyan
Write-Host "Chạy lệnh sau và điền thông tin:" -ForegroundColor White
Write-Host ""
Write-Host "  aws configure sso --profile $ProfileName" -ForegroundColor Gray
Write-Host ""
Write-Host "Khi được hỏi, điền:" -ForegroundColor White
Write-Host "  SSO start URL: https://$accountId.signin.aws.amazon.com/console" -ForegroundColor Gray
Write-Host "  SSO region: us-east-1" -ForegroundColor Gray
Write-Host "  SSO registration scopes: sso:account:access" -ForegroundColor Gray
Write-Host "  CLI default client Region: $Region" -ForegroundColor Gray
Write-Host "  CLI default output format: json" -ForegroundColor Gray
Write-Host ""

Write-Host "Bước 2: Login" -ForegroundColor Cyan
Write-Host "Sau khi configure, login bằng:" -ForegroundColor White
Write-Host ""
Write-Host "  aws sso login --profile $ProfileName" -ForegroundColor Gray
Write-Host ""
Write-Host "Browser sẽ mở và bạn đăng nhập với:" -ForegroundColor White
Write-Host "  Username: $($credentials['AWS_ACADEMY_USERNAME'])" -ForegroundColor Gray
Write-Host "  Password: $($credentials['AWS_ACADEMY_PASSWORD'])" -ForegroundColor Gray
Write-Host ""

Write-Host "Bước 3: Sử dụng profile" -ForegroundColor Cyan
Write-Host "Sau khi login, sử dụng AWS CLI với:" -ForegroundColor White
Write-Host ""
Write-Host "  aws s3 ls --profile $ProfileName" -ForegroundColor Gray
Write-Host ""
Write-Host "Hoặc set environment variable:" -ForegroundColor White
Write-Host "  `$env:AWS_PROFILE = '$ProfileName'" -ForegroundColor Gray
Write-Host ""

Write-Host "CÁCH 2: Sử dụng Temporary Access Keys" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "1. Đăng nhập AWS Console: .\scripts\open-aws-console.ps1" -ForegroundColor White
Write-Host "2. Vào IAM → Users → Security credentials" -ForegroundColor White
Write-Host "3. Tạo Access Key" -ForegroundColor White
Write-Host "4. Configure: aws configure" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to configure SSO now
$response = Read-Host "Bạn có muốn configure SSO profile ngay bây giờ? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host ""
    Write-Host "Đang mở AWS SSO configure..." -ForegroundColor Cyan
    Write-Host "Làm theo hướng dẫn trên màn hình." -ForegroundColor Yellow
    Write-Host ""
    
    # Prepare SSO start URL
    $ssoStartUrl = "https://$accountId.signin.aws.amazon.com/console"
    
    Write-Host "Thông tin cần điền:" -ForegroundColor Cyan
    Write-Host "  SSO start URL: $ssoStartUrl" -ForegroundColor White
    Write-Host "  SSO region: us-east-1" -ForegroundColor White
    Write-Host "  SSO registration scopes: sso:account:access" -ForegroundColor White
    Write-Host "  CLI default client Region: $Region" -ForegroundColor White
    Write-Host "  CLI default output format: json" -ForegroundColor White
    Write-Host ""
    
    # Run aws configure sso
    aws configure sso --profile $ProfileName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✓ SSO profile configured successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Bây giờ login bằng:" -ForegroundColor Cyan
        Write-Host "  aws sso login --profile $ProfileName" -ForegroundColor White
    }
    else {
        Write-Host ""
        Write-Host "⚠ Configuration có thể chưa hoàn tất. Kiểm tra lại." -ForegroundColor Yellow
    }
}
else {
    Write-Host "Bạn có thể configure SSO sau bằng:" -ForegroundColor Yellow
    Write-Host "  aws configure sso --profile $ProfileName" -ForegroundColor White
}

Write-Host ""
Write-Host "For more details, see DEMO_GUIDE.md" -ForegroundColor Cyan

