# Hướng Dẫn Sử Dụng AWS Academy với SSO CLI

## Tổng Quan

AWS Academy sử dụng **Single Sign-On (SSO)** để đăng nhập. Thay vì tạo Access Keys truyền thống, bạn có thể sử dụng **AWS SSO CLI** để login trực tiếp qua browser.

## Ưu Điểm của SSO CLI

✅ **Không cần tạo Access Keys** - An toàn hơn  
✅ **Tự động refresh** - Không cần quản lý credentials  
✅ **Dễ dàng hơn** - Chỉ cần login một lần  
✅ **Hỗ trợ nhiều accounts** - Dễ dàng switch giữa các accounts  

## Cài Đặt

### Yêu Cầu

- AWS CLI v2 (không phải v1)
- PowerShell hoặc Bash

### Kiểm Tra AWS CLI Version

```powershell
aws --version
```

Phải là `aws-cli/2.x.x`. Nếu là v1, cài đặt lại AWS CLI v2.

## Cấu Hình SSO

### Bước 1: Chạy Script Tự Động

```powershell
.\scripts\setup-aws-sso.ps1
```

Script sẽ:
- Đọc credentials từ `aws-academy-credentials.txt`
- Hướng dẫn configure SSO profile
- Tự động điền thông tin cần thiết

### Bước 2: Configure SSO Profile (Thủ Công)

Nếu muốn configure thủ công:

```powershell
aws configure sso --profile aws-academy
```

Khi được hỏi, điền:

1. **SSO start URL:**
   ```
   https://644123626050.signin.aws.amazon.com/console
   ```

2. **SSO region:**
   ```
   us-east-1
   ```

3. **SSO registration scopes:**
   ```
   sso:account:access
   ```

4. **CLI default client Region:**
   ```
   us-east-1
   ```

5. **CLI default output format:**
   ```
   json
   ```

### Bước 3: Login

Sau khi configure, login:

```powershell
aws sso login --profile aws-academy
```

Browser sẽ tự động mở và bạn sẽ thấy AWS Academy login page.

**Đăng nhập với:**
- Username: `cloud_user`
- Password: `3ZJ7)y2GAjsk#P+^aD8y`

Sau khi login thành công, terminal sẽ hiển thị:
```
Successfully logged into Start URL: https://644123626050.signin.aws.amazon.com/console
```

## Sử Dụng

### Cách 1: Dùng --profile trong mỗi command

```powershell
aws s3 ls --profile aws-academy
aws ec2 describe-instances --profile aws-academy
aws terraform --profile aws-academy
```

### Cách 2: Set Environment Variable (Khuyến nghị)

```powershell
# PowerShell
$env:AWS_PROFILE = "aws-academy"

# Sau đó dùng bình thường
aws s3 ls
aws ec2 describe-instances
```

```bash
# Bash/Linux/Mac
export AWS_PROFILE=aws-academy

# Sau đó dùng bình thường
aws s3 ls
aws ec2 describe-instances
```

### Cách 3: Set trong AWS Config

Edit file `~/.aws/config` (Linux/Mac) hoặc `$env:USERPROFILE\.aws\config` (Windows):

```ini
[default]
region = us-east-1
output = json
sso_start_url = https://644123626050.signin.aws.amazon.com/console
sso_region = us-east-1
sso_account_id = 644123626050
sso_role_name = AWSAdministratorAccess
```

## Kiểm Tra Kết Nối

### Test với Profile

```powershell
.\scripts\test-aws-connection.ps1 -Profile aws-academy
```

### Test Thủ Công

```powershell
aws sts get-caller-identity --profile aws-academy
```

Kết quả mong đợi:
```json
{
    "UserId": "...",
    "Account": "644123626050",
    "Arn": "arn:aws:sts::644123626050:assumed-role/..."
}
```

## Session Management

### Kiểm Tra Session Status

```powershell
aws sso login --profile aws-academy --no-browser
```

Nếu đã login, sẽ hiển thị:
```
Attempting to automatically open the SSO authorization page in your default browser.
```

### Logout

```powershell
aws sso logout --profile aws-academy
```

### Refresh Session

Nếu session hết hạn, login lại:

```powershell
aws sso login --profile aws-academy
```

## Troubleshooting

### Lỗi: "The SSO session associated with this profile has expired"

**Nguyên nhân:** SSO session đã hết hạn (thường sau 8-12 giờ)

**Giải pháp:**
```powershell
aws sso login --profile aws-academy
```

### Lỗi: "Unable to locate credentials"

**Nguyên nhân:** Chưa login hoặc profile chưa được set

**Giải pháp:**
1. Login: `aws sso login --profile aws-academy`
2. Set profile: `$env:AWS_PROFILE = "aws-academy"`
3. Hoặc dùng `--profile` trong mỗi command

### Lỗi: "SSO start URL is invalid"

**Nguyên nhân:** SSO start URL không đúng

**Giải pháp:**
1. Kiểm tra URL trong `aws-academy-credentials.txt`
2. Reconfigure: `aws configure sso --profile aws-academy`

### Lỗi: "Browser không mở tự động"

**Giải pháp:**
1. Copy URL từ terminal
2. Paste vào browser thủ công
3. Hoặc dùng: `aws sso login --profile aws-academy --no-browser`

## So Sánh SSO vs Access Keys

| Tính năng | SSO CLI | Access Keys |
|-----------|---------|-------------|
| Bảo mật | ✅ Tự động rotate | ⚠️ Phải quản lý thủ công |
| Dễ sử dụng | ✅ Login một lần | ⚠️ Phải tạo và configure |
| Hết hạn | ✅ Tự động refresh | ❌ Không hết hạn (rủi ro) |
| Multi-account | ✅ Dễ dàng | ⚠️ Phải tạo keys cho mỗi account |
| AWS Academy | ✅ Hỗ trợ tốt | ⚠️ Phải tạo từ IAM console |

## Best Practices

1. **Luôn dùng SSO cho AWS Academy** - Dễ dàng và an toàn hơn
2. **Set AWS_PROFILE environment variable** - Tránh phải gõ `--profile` mỗi lần
3. **Login lại khi session hết hạn** - SSO session có thời hạn
4. **Không commit SSO config** - File `~/.aws/config` có thể chứa thông tin nhạy cảm

## Tài Liệu Tham Khảo

- [AWS CLI SSO Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html)
- [AWS Academy Documentation](https://awsacademy.instructure.com/)
- [DEMO_GUIDE.md](../DEMO_GUIDE.md) - Hướng dẫn demo chi tiết



