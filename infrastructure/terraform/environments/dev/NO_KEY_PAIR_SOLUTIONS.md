# Giải Pháp Khi Không Có Key Pair

## Vấn Đề

Bạn không có key pair trong AWS account, và không có quyền tạo key pair mới (`ec2:ImportKeyPair` bị chặn).

## Giải Pháp

### Option 1: Tạo Key Pair Trên Máy Local và Yêu Cầu Admin Import

1. **Tạo key pair trên máy local:**
   ```powershell
   # Windows PowerShell
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/eshelf-key -N '""'
   ```

2. **Lấy public key:**
   ```powershell
   Get-Content ~/.ssh/eshelf-key.pub
   ```

3. **Yêu cầu AWS Admin import key pair:**
   - Gửi public key cho admin
   - Admin sẽ import vào AWS với tên bạn chỉ định (ví dụ: "eshelf-keypair-dev")
   - Sau đó cập nhật `key_name = "eshelf-keypair-dev"` trong terraform.tfvars

### Option 2: Dùng AWS Systems Manager Session Manager (Không Cần Key Pair)

**Ưu điểm:** Không cần key pair, có thể truy cập EC2 instances qua browser hoặc AWS CLI.

**Yêu cầu:**
- EC2 instances cần có SSM Agent (Amazon Linux 2023 đã có sẵn)
- IAM role với SSM permissions (có thể cần admin setup)

**Cách dùng sau khi deploy:**
```powershell
# Install AWS Session Manager Plugin
# Download từ: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Connect to instance
aws ssm start-session --target <instance-id>
```

### Option 3: Tạm Thời Bỏ Qua Key Pair (Chỉ Để Test Infrastructure)

**Lưu ý:** Instances sẽ được tạo nhưng bạn **KHÔNG THỂ SSH** vào được.

- Để `key_name = ""` trong terraform.tfvars
- Terraform sẽ tạo instances không có key pair
- Bạn vẫn có thể:
  - Kiểm tra instances đã được tạo
  - Xem logs qua CloudWatch
  - Test infrastructure setup
  - Nhưng **KHÔNG THỂ SSH** vào instances

### Option 4: Dùng EC2 Instance Connect (Nếu Được Bật)

Một số AWS accounts có EC2 Instance Connect được bật, cho phép SSH qua browser mà không cần key pair.

**Cách kiểm tra:**
1. Vào EC2 Console
2. Chọn instance
3. Click "Connect"
4. Nếu thấy tab "EC2 Instance Connect", bạn có thể dùng

## Khuyến Nghị

**Cho Lab 1 (Infrastructure as Code):**
- **Option 3** là đủ - bạn chỉ cần chứng minh infrastructure được tạo đúng
- Instances không có key pair vẫn đáp ứng yêu cầu Lab 1:
  - ✅ VPC và Subnets
  - ✅ Route Tables
  - ✅ NAT Gateway
  - ✅ EC2 Instances (tạo được)
  - ✅ Security Groups

**Cho thực tế sử dụng:**
- **Option 1** hoặc **Option 2** - cần truy cập vào instances

## Cập Nhật terraform.tfvars

Hiện tại đã được cấu hình để chấp nhận `key_name = ""`:

```hcl
create_key_pair = false
key_name = ""  # Để trống nếu không có key pair
```

Bạn có thể chạy `terraform apply` ngay bây giờ, instances sẽ được tạo mà không có key pair.



