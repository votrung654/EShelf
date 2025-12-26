# Hướng Dẫn Xóa AWS CLI Thủ Công

## Cách 1: Dùng Script với Quyền Administrator (Khuyến nghị)

### Bước 1: Mở PowerShell với quyền Administrator

1. Nhấn `Win + X`
2. Chọn **"Windows PowerShell (Admin)"** hoặc **"Terminal (Admin)"**
3. Nếu có UAC prompt, click **"Yes"**

### Bước 2: Chạy script

```powershell
cd D:\github-renewable\eShelf
.\scripts\force-remove-aws-cli.ps1
```

Script này sẽ tự động:
- Kill tất cả AWS processes
- Uninstall qua winget
- Xóa tất cả directories với quyền admin
- Clean PATH
- Xóa registry entries
- Xóa shortcuts

## Cách 2: Xóa Thủ Công

### Bước 1: Kill Processes

Mở PowerShell và chạy:
```powershell
Get-Process -Name "aws" | Stop-Process -Force
```

### Bước 2: Uninstall qua winget

```powershell
winget uninstall Amazon.AWSCLI
```

### Bước 3: Xóa Directories (Cần quyền Admin)

Mở PowerShell **as Administrator** và chạy:

```powershell
# Lấy quyền sở hữu
takeown /F "C:\Program Files\Amazon\AWSCLIV2" /R /D Y

# Cấp quyền full control
icacls "C:\Program Files\Amazon\AWSCLIV2" /grant administrators:F /T

# Xóa directory
Remove-Item "C:\Program Files\Amazon\AWSCLIV2" -Recurse -Force
```

Lặp lại cho các directories khác:
- `C:\Program Files (x86)\Amazon\AWSCLIV2`
- `$env:LOCALAPPDATA\Programs\Amazon\AWSCLIV2`
- `$env:APPDATA\Amazon\AWSCLI`

### Bước 4: Clean PATH

1. Mở **System Properties**:
   - Nhấn `Win + R`
   - Gõ `sysdm.cpl` và Enter
   - Tab **"Advanced"**
   - Click **"Environment Variables"**

2. Trong **"User variables"**, tìm **"Path"** và click **"Edit"**

3. Xóa các entries liên quan đến AWS CLI:
   - `C:\Program Files\Amazon\AWSCLIV2`
   - `C:\Program Files (x86)\Amazon\AWSCLIV2`

4. Click **"OK"** để save

### Bước 5: Xóa Config Files (Optional)

```powershell
# Backup trước
Copy-Item "$env:USERPROFILE\.aws" "$env:USERPROFILE\.aws.backup" -Recurse

# Xóa
Remove-Item "$env:USERPROFILE\.aws" -Recurse -Force
```

### Bước 6: Xóa Registry (Cần quyền Admin)

Mở PowerShell **as Administrator**:

```powershell
# Xóa registry keys
Remove-Item "HKLM:\SOFTWARE\Amazon\AWSCLI" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\WOW6432Node\Amazon\AWSCLI" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKCU:\SOFTWARE\Amazon\AWSCLI" -Recurse -Force -ErrorAction SilentlyContinue
```

## Cách 3: Dùng File Explorer (GUI)

### Bước 1: Mở File Explorer với quyền Admin

1. Tìm **File Explorer** trong Start Menu
2. Right-click → **"Run as administrator"**

### Bước 2: Navigate và xóa

1. Đi đến: `C:\Program Files\Amazon\`
2. Right-click folder **AWSCLIV2** → **"Properties"**
3. Tab **"Security"** → **"Advanced"**
4. Click **"Change"** ở phần Owner
5. Nhập tên user admin → **"OK"**
6. Check **"Replace owner on subcontainers and objects"** → **"OK"**
7. Quay lại Properties → **"Edit"** permissions
8. Chọn **"Administrators"** → Check **"Full control"** → **"OK"**
9. Xóa folder **AWSCLIV2**

### Bước 3: Xóa từ PATH

1. `Win + R` → `sysdm.cpl` → **"Environment Variables"**
2. Edit **"Path"** trong User variables
3. Xóa AWS CLI entries
4. **"OK"** để save

## Kiểm Tra Sau Khi Xóa

```powershell
# Kiểm tra AWS CLI còn tồn tại không
Get-Command aws -ErrorAction SilentlyContinue

# Kiểm tra directories
Test-Path "C:\Program Files\Amazon\AWSCLIV2"
Test-Path "C:\Program Files (x86)\Amazon\AWSCLIV2"

# Kiểm tra PATH
$env:Path -split ';' | Select-String "Amazon"
```

Nếu tất cả đều trả về `$null` hoặc `False`, thì đã xóa sạch!

## Sau Khi Xóa Xong

Reinstall AWS CLI:
```powershell
.\scripts\clean-reinstall-aws-cli.ps1
```

Hoặc cài thủ công:
```powershell
winget install Amazon.AWSCLI
```

## Troubleshooting

### "Access Denied" khi xóa

1. Đảm bảo đang chạy PowerShell as Administrator
2. Đóng tất cả programs đang dùng AWS CLI
3. Restart computer và thử lại

### Không thể xóa một số files

Dùng robocopy trick:
```powershell
# Tạo empty folder
$empty = "$env:TEMP\empty"
New-Item -ItemType Directory -Path $empty -Force

# Mirror empty folder vào target (xóa target)
robocopy $empty "C:\Program Files\Amazon\AWSCLIV2" /MIR /R:0 /W:0

# Xóa empty folder
Remove-Item $empty -Force
```

### PATH vẫn còn sau khi xóa

1. Restart PowerShell
2. Hoặc restart computer
3. Kiểm tra lại: `$env:Path -split ';' | Select-String "Amazon"`

