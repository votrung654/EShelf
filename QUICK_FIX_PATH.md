# Quick Fix: AWS CLI và Terraform không chạy được

## Vấn Đề

Sau khi cài đặt, `aws` và `terraform` không chạy được vì chưa có trong PATH của PowerShell session hiện tại.

## Giải Pháp Nhanh

### Cách 1: Chạy Script Init (Khuyến nghị)

Trong PowerShell của bạn, chạy:

```powershell
. .\scripts\init-tools.ps1
```

Script này sẽ:
- Refresh PATH trong session hiện tại
- Tạo aliases cho AWS CLI và Terraform
- Test tất cả tools

### Cách 2: Restart PowerShell

Đơn giản nhất: **Đóng và mở lại PowerShell**. PATH đã được lưu vào environment variables, chỉ cần restart để load.

### Cách 3: Dùng Full Path (Tạm thời)

Nếu không muốn restart, dùng full path:

```powershell
# AWS CLI
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" --version

# Terraform
& "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe" version
```

### Cách 4: Thêm vào PowerShell Profile (Permanent)

Để tự động load mỗi khi mở PowerShell:

```powershell
# Mở profile
notepad $PROFILE

# Thêm dòng này vào cuối file:
. "$PSScriptRoot\scripts\init-tools.ps1"
```

Hoặc thêm trực tiếp:

```powershell
Add-Content $PROFILE "`n. `"$PWD\scripts\init-tools.ps1`""
```

## Kiểm Tra

Sau khi chạy script hoặc restart PowerShell:

```powershell
aws --version
terraform version
kubectl version --client
```

Tất cả đều phải chạy được!

## Troubleshooting

### Vẫn không chạy được sau khi restart?

1. Kiểm tra PATH có đúng không:
   ```powershell
   $env:Path -split ';' | Select-String -Pattern "AWSCLIV2|Terraform"
   ```

2. Kiểm tra file có tồn tại không:
   ```powershell
   Test-Path "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
   Test-Path "C:\Users\$env:USERNAME\AppData\Local\Microsoft\WinGet\Packages\Hashicorp.Terraform_Microsoft.Winget.Source_8wekyb3d8bbwe\terraform.exe"
   ```

3. Chạy lại script setup:
   ```powershell
   .\scripts\find-and-setup-tools.ps1
   ```



