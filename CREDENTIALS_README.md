# Hướng Dẫn Quản Lý Credentials

## Lưu ý Bảo Mật

**KHÔNG BAO GIỜ commit các file chứa credentials thực tế lên Git!**

Các file sau đã được thêm vào `.gitignore` và sẽ không được commit:
- `aws-academy-credentials.txt`
- `*.credentials`
- `*.secrets`
- `.env`
- `.env.local`
- `terraform.tfvars`
- `*.pem`
- `*.key`

## AWS Academy Credentials

### Cách tạo file credentials:

1. Copy file template:
   ```powershell
   Copy-Item aws-academy-credentials.example.txt aws-academy-credentials.txt
   ```

2. Mở file `aws-academy-credentials.txt` và điền thông tin thực tế:
   ```
   AWS_ACADEMY_URL=https://YOUR_ACCOUNT_ID.signin.aws.amazon.com/console?region=us-east-1
   AWS_ACADEMY_USERNAME=your_username
   AWS_ACADEMY_PASSWORD=your_password
   ```

3. File này sẽ không được commit lên Git (đã có trong .gitignore)

### Sử dụng trong DEMO_GUIDE.md:

Khi làm theo hướng dẫn trong `DEMO_GUIDE.md`, bạn sẽ được hướng dẫn đọc thông tin từ file `aws-academy-credentials.txt` này.

## Các Credentials Khác

### SSH Keys
- SSH keys được lưu trong `~/.ssh/` (Windows: `$env:USERPROFILE\.ssh\`)
- Không commit private keys lên Git
- Chỉ sử dụng public keys trong Terraform/configs

### AWS Access Keys
- Lưu trong AWS CLI config (`aws configure`)
- Hoặc sử dụng environment variables
- Không commit lên Git

### GitHub Secrets
- Sử dụng GitHub Repository Secrets cho CI/CD
- Không hardcode trong code hoặc config files

## Best Practices

1. **Luôn sử dụng file `.example`** cho templates
2. **Kiểm tra `.gitignore`** trước khi commit
3. **Sử dụng environment variables** khi có thể
4. **Rotate credentials** định kỳ
5. **Không chia sẻ credentials** qua chat/email không mã hóa

