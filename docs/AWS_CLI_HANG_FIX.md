# AWS CLI Hang Issue - Fix Guide

## Vấn Đề

Khi chạy `aws --version` trong PowerShell, lệnh bị treo (hang) và không trả về kết quả, khiến PowerShell không phản hồi.

## Nguyên Nhân

Có thể do:
- AWS CLI đang cố truy cập config files bị lock
- Vấn đề với PATH resolution trong PowerShell
- AWS CLI đang chờ input từ một process khác

## Giải Pháp

Có 2 cách tiếp cận:

### Cách 1: Fix Root Cause (Khuyến nghị)

**File:** `scripts\diagnose-aws-cli-hang.ps1` - Chẩn đoán vấn đề
**File:** `scripts\fix-aws-cli-permanently.ps1` - Fix vĩnh viễn
**File:** `scripts\reinstall-aws-cli.ps1` - Reinstall AWS CLI nếu cần

**Cách dùng:**
```powershell
# Bước 1: Chẩn đoán
.\scripts\diagnose-aws-cli-hang.ps1

# Bước 2: Fix vĩnh viễn
.\scripts\fix-aws-cli-permanently.ps1

# Nếu vẫn không được, reinstall
.\scripts\reinstall-aws-cli.ps1
# Hoặc dùng MSI installer
.\scripts\reinstall-aws-cli.ps1 -UseMSI
```

### Cách 2: Workaround (Tạm thời)

Đã tạo các script và workaround để xử lý vấn đề này:

### 1. Script Fix Chính

**File:** `scripts\fix-aws-cli-hang.ps1`

Script này sẽ:
- Tìm AWS CLI installation
- Test với direct path và timeout
- Kiểm tra config files
- Tạo wrapper function và test script

**Cách dùng:**
```powershell
.\scripts\fix-aws-cli-hang.ps1
```

### 2. Test Script An Toàn

**File:** `scripts\test-aws-version-safe.ps1`

Script này kiểm tra AWS CLI version với timeout để tránh treo.

**Cách dùng:**
```powershell
.\scripts\test-aws-version-safe.ps1
```

### 3. AWS Wrapper Function

**File:** `scripts\aws-wrapper.ps1`

Function wrapper để thay thế lệnh `aws` thông thường, tự động xử lý timeout cho `--version`.

**Cách dùng:**
```powershell
# Load function
. .\scripts\aws-wrapper.ps1

# Sau đó có thể dùng bình thường
aws --version
aws sts get-caller-identity
```

### 4. Sử Dụng Direct Path

Thay vì dùng `aws --version`, dùng direct path:

```powershell
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" --version
```

## Scripts Đã Được Cập Nhật

Các script sau đã được cập nhật để sử dụng phương pháp an toàn:

1. `scripts\verify-aws-setup.ps1` - Sử dụng direct path và timeout
2. `scripts\test-aws-connection.ps1` - Sử dụng direct path cho tất cả AWS commands
3. `scripts\setup-infrastructure.ps1` - Sử dụng direct path khi check AWS CLI

## Workaround Tạm Thời

Nếu vẫn gặp vấn đề, có thể:

1. **Sử dụng CloudShell trong AWS Console:**
   - Mở AWS Console
   - Click icon CloudShell (terminal icon ở top bar)
   - CloudShell đã có AWS CLI sẵn và không bị treo

2. **Reinstall AWS CLI:**
   ```powershell
   winget uninstall Amazon.AWSCLI
   winget install Amazon.AWSCLI
   # Restart PowerShell sau khi cài
   ```

3. **Kiểm tra Config Files:**
   ```powershell
   # Kiểm tra config files có bị lock không
   Get-Content $env:USERPROFILE\.aws\config
   Get-Content $env:USERPROFILE\.aws\credentials
   ```

## Kiểm Tra Sau Khi Fix

Sau khi chạy fix script, test lại:

```powershell
# Method 1: Dùng test script
.\scripts\test-aws-version-safe.ps1

# Method 2: Dùng direct path
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" --version

# Method 3: Load wrapper function
. .\scripts\aws-wrapper.ps1
aws --version
```

## Lưu Ý

- Các script khác trong project đã được cập nhật để tự động sử dụng direct path
- Wrapper function chỉ cần load một lần trong mỗi PowerShell session
- Nếu muốn wrapper function tự động load, thêm vào PowerShell profile:
  ```powershell
  . $PSScriptRoot\scripts\aws-wrapper.ps1
  ```

## Troubleshooting

### Vẫn bị treo sau khi fix

1. Kiểm tra Windows Event Viewer cho errors
2. Thử uninstall và reinstall AWS CLI
3. Kiểm tra antivirus có block AWS CLI không
4. Thử chạy PowerShell as Administrator

### AWS CLI không tìm thấy

1. Kiểm tra installation path:
   ```powershell
   Test-Path "C:\Program Files\Amazon\AWSCLIV2\aws.exe"
   ```

2. Refresh PATH:
   ```powershell
   $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
   ```

3. Restart PowerShell

## Tài Liệu Liên Quan

- `NEXT_STEPS.md` - Hướng dẫn setup infrastructure
- `scripts\setup-infrastructure.ps1` - Script tự động setup
- `docs\AWS_FREE_TIER_SETUP_GUIDE.md` - Hướng dẫn setup AWS account

