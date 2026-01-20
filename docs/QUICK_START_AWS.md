# Quick Start Guide - AWS Setup

Hướng dẫn nhanh để setup và test AWS Academy credentials.

## Bước 1: Kiểm Tra Credentials File

File `aws-academy-credentials.txt` đã được tạo tự động với thông tin từ AWS Academy.

**Kiểm tra:**
```powershell
Test-Path aws-academy-credentials.txt
```

Nếu trả về `True`, file đã tồn tại.

## Bước 2: Mở AWS Console (Browser)

Chạy script để mở AWS Console trong browser:

```powershell
.\scripts\open-aws-console.ps1
```

Script sẽ:
- Đọc credentials từ file
- Mở browser với URL đúng
- Hiển thị username và password

**Sau đó:**
1. Đăng nhập với:
   - Username: `cloud_user`
   - Password: `3ZJ7)y2GAjsk#P+^aD8y`

2. **Kiểm tra thành công:**
   - AWS Console dashboard hiển thị
   - Có thể thấy các services (EC2, VPC, IAM, etc.)
   - Account ID hiển thị: `644123626050`

## Bước 3: Configure AWS CLI cho AWS Academy

### Cách 1: AWS SSO CLI (Khuyến nghị - Dễ nhất)

AWS Academy hỗ trợ SSO, bạn có thể login trực tiếp:

```powershell
# Configure SSO profile
.\scripts\setup-aws-sso.ps1
```

Script sẽ hướng dẫn bạn configure. Sau đó login:

```powershell
aws sso login --profile aws-academy
```

Browser sẽ mở, đăng nhập với:
- Username: `cloud_user`
- Password: `3ZJ7)y2GAjsk#P+^aD8y`

Sau khi login, sử dụng:
```powershell
# Set profile
$env:AWS_PROFILE = "aws-academy"

# Hoặc dùng --profile trong mỗi command
aws s3 ls --profile aws-academy
```

### Cách 2: Temporary Access Keys (Nếu không dùng SSO)

1. Trong AWS Console, vào **IAM** → **Users** → `cloud_user`
2. Tab **Security credentials** → **Create access key**
3. Chọn **Command Line Interface (CLI)**
4. Copy **Access Key ID** và **Secret Access Key**

Configure:
```powershell
aws configure
```

Nhập:
- **AWS Access Key ID:** [Paste từ bước trên]
- **AWS Secret Access Key:** [Paste từ bước trên]
- **Default region name:** `us-east-1`
- **Default output format:** `json`

## Bước 4: Test AWS Connection

Sau khi configure AWS CLI, test kết nối:

```powershell
.\scripts\test-aws-connection.ps1
```

**Kết quả mong đợi:**
```
[PASS] AWS CLI Installation: aws-cli/2.x.x
[PASS] AWS Credentials: Account: 644123626050
[PASS] Region Access: Region: us-east-1
[PASS] EC2 Service: Service accessible
[PASS] VPC Service: Service accessible

✓ All tests passed! AWS connection is working.
```

## Bước 5: Tiếp Tục với Terraform

Sau khi AWS connection hoạt động, tiếp tục với:

1. **Đọc DEMO_GUIDE.md** để biết các bước chi tiết
2. **Setup Terraform:**
   ```powershell
   cd infrastructure/terraform/environments/dev
   terraform init
   terraform plan
   ```
3. **Apply Terraform** (khi sẵn sàng):
   ```powershell
   terraform apply
   ```

## Các Scripts Có Sẵn

### 1. `scripts/open-aws-console.ps1`
- Mở AWS Console trong browser
- Hiển thị credentials để login

### 2. `scripts/setup-aws-credentials.ps1`
- Load credentials vào environment
- Hướng dẫn configure AWS CLI

### 3. `scripts/test-aws-connection.ps1`
- Test AWS CLI installation
- Test AWS credentials
- Test region và service access

### 4. `scripts/verify-aws-setup.ps1`
- Verify tất cả prerequisites
- Check tools installation
- Guide next steps

## Browser Testing

Sau khi deploy infrastructure, test các tools qua browser:

### ArgoCD
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Truy cập: https://localhost:8080
```

### Grafana
```powershell
kubectl port-forward svc/grafana -n monitoring 3000:3000
# Truy cập: http://localhost:3000
```

### Harbor
```powershell
kubectl port-forward svc/harbor-core -n harbor 8081:80
# Truy cập: http://localhost:8081
```

**Xem chi tiết:** `docs/BROWSER_TESTING_GUIDE.md`

## Troubleshooting

### Lỗi: "AWS CLI is not installed"
```powershell
# Install AWS CLI
winget install Amazon.AWSCLI

# Hoặc download từ: https://aws.amazon.com/cli/
```

### Lỗi: "Credentials are not configured"
1. Mở AWS Console: `.\scripts\open-aws-console.ps1`
2. Lấy Access Key từ IAM Console
3. Configure: `aws configure`

### Lỗi: "Cannot access AWS Console"
- Kiểm tra credentials trong `aws-academy-credentials.txt`
- Kiểm tra internet connection
- Thử lại sau vài phút (sandbox có thể bị lock)

## Lưu Ý Quan Trọng

⚠️ **AWS Academy Sandbox:**
- Sẽ reset sau 4 giờ
- Tất cả dữ liệu sẽ bị xóa
- Có thể bị khóa vì nhiều lý do

⚠️ **Bảo Mật:**
- File `aws-academy-credentials.txt` KHÔNG được commit lên Git (đã có trong .gitignore)
- Không chia sẻ credentials qua chat/email
- Rotate credentials định kỳ

## Tài Liệu Tham Khảo

- **DEMO_GUIDE.md** - Hướng dẫn demo chi tiết
- **docs/BROWSER_TESTING_GUIDE.md** - Hướng dẫn test qua browser
- **CREDENTIALS_README.md** - Quản lý credentials
- **ENV_SETUP_GUIDE.md** - Setup biến môi trường

