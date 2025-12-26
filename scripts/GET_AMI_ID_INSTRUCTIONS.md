# Hướng Dẫn Lấy AMI ID cho Region us-east-1

## Vấn đề
AMI ID `ami-012face341cb74b64` chỉ có trong region `us-east-1`, nhưng VPC và Subnets của bạn ở `us-east-1`.

## Giải pháp: Lấy AMI ID trong us-east-1

### Cách 1: Qua AWS Console (Khuyến nghị)

1. **Đảm bảo region là us-east-1:**
   - Click vào region selector ở góc trên bên phải
   - Chọn "US East (N. Virginia)" hoặc "us-east-1"

2. **Vào EC2 Console:**
   - Go to: https://console.aws.amazon.com/ec2/
   - Đảm bảo region là `us-east-1`

3. **Launch instance:**
   - Click "Launch instance"
   - Ở tab "Quick Start" hoặc "My AMIs"
   - Tìm "Amazon Linux 2023" hoặc AMI tương tự
   - Copy AMI ID (format: `ami-xxxxxxxxxxxxxxxxx`)

4. **Cập nhật AMI ID:**
   - Mở `scripts/create-ec2-instances.ps1`
   - Tìm dòng: `[string]$AmiId = "ami-..."`
   - Thay bằng AMI ID mới
   - Mở `infrastructure/terraform/environments/dev/terraform.tfvars`
   - Tìm dòng: `ami_id = "ami-..."`
   - Thay bằng AMI ID mới

### Cách 2: Qua AWS CloudShell (Nếu có quyền)

```bash
aws ec2 describe-images \
  --region us-east-1 \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=virtualization-type,Values=hvm" \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
  --output text
```

### Cách 3: Dùng AMI được share

Nếu bạn có AMI được share trong region `us-east-1`:
- Vào EC2 Console → AMIs → "Shared with me"
- Tìm AMI có sẵn trong region `us-east-1`
- Copy AMI ID

## Sau khi có AMI ID

Chạy lại script:
```powershell
.\scripts\create-ec2-instances.ps1
```

