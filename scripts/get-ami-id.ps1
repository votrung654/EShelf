# Script to get latest Amazon Linux 2023 AMI ID
# This uses AWS Console method since we don't have DescribeImages permission

param(
    [string]$Region = "us-east-1"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Get Amazon Linux 2023 AMI ID" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Since you don't have ec2:DescribeImages permission," -ForegroundColor Yellow
Write-Host "please get the AMI ID from AWS Console:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Steps:" -ForegroundColor Cyan
Write-Host "1. Go to AWS Console: https://console.aws.amazon.com/ec2/" -ForegroundColor Gray
Write-Host "2. Click 'Launch instance'" -ForegroundColor Gray
Write-Host "3. Search for 'Amazon Linux 2023'" -ForegroundColor Gray
Write-Host "4. Copy the AMI ID (e.g., ami-xxxxxxxxxxxxxxxxx)" -ForegroundColor Gray
Write-Host ""
Write-Host "Or try to get AMI ID automatically:" -ForegroundColor Cyan
try {
    $amiId = aws ec2 describe-images --region $Region --owners amazon --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=virtualization-type,Values=hvm" --query "sort_by(Images, &CreationDate)[-1].[ImageId]" --output text 2>&1
    
    if ($LASTEXITCODE -eq 0 -and $amiId -match "^ami-") {
        Write-Host "  ✅ Found AMI ID: $amiId" -ForegroundColor Green
        Write-Host "`nUpdate terraform.tfvars with this AMI ID:" -ForegroundColor Yellow
        Write-Host "  ami_id = `"$amiId`"" -ForegroundColor Gray
    } else {
        Write-Host "  ⚠️  Could not get AMI ID automatically" -ForegroundColor Yellow
        Write-Host "  Please get it manually from AWS Console" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  Error getting AMI ID: $_" -ForegroundColor Yellow
    Write-Host "  Please get it manually from AWS Console" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "If you get AMI ID manually, update it in:" -ForegroundColor Yellow
Write-Host "  - infrastructure/terraform/environments/dev/terraform.tfvars" -ForegroundColor Gray
Write-Host ""
