# Hướng Dẫn Dọn Dẹp Ổ C An Toàn

## Tổng Quan

Script này giúp bạn dọn dẹp ổ C một cách an toàn, **KHÔNG ảnh hưởng** đến:
- Project files và source code
- `node_modules` trong project (dependencies cần thiết)
- Công cụ đã cài đặt (Node.js, Python, Docker, AWS CLI, Terraform, kubectl)
- Database files
- Configuration files

## Những Gì Sẽ Được Xóa

### 1. Windows Temp Files
- `%TEMP%` - Windows temp files
- `%LOCALAPPDATA%\Temp` - User temp files
- `C:\Windows\Temp` - System temp files

### 2. Browser Cache
- Chrome cache
- Edge cache
- Firefox cache

### 3. npm Cache
- npm global cache (có thể tái tạo bằng `npm install`)

### 4. Python Cache
- `__pycache__` folders trong project
- `.pyc` files (chỉ trong project, không ảnh hưởng Python system)

### 5. Docker Cleanup
- Unused Docker images
- Stopped containers
- Unused volumes
- Build cache

### 6. Build Artifacts
- `dist/` folders (có thể tái tạo bằng `npm run build`)
- `build/` folders

### 7. Recycle Bin
- Tất cả files trong Recycle Bin

### 8. Windows Update Files
- Old Windows Update files (cần quyền admin)

### 9. Log Files
- Log files cũ hơn 7 ngày trong project

## Cách Sử Dụng

### Bước 1: Kiểm Tra Dung Lượng

Trước khi dọn dẹp, kiểm tra dung lượng hiện tại:

```powershell
.\scripts\check-disk-space.ps1
```

Script này sẽ hiển thị:
- Dung lượng còn trống trên ổ C
- Các thư mục lớn
- npm cache size
- Docker disk usage
- Recycle Bin size

### Bước 2: Xem Trước (Dry Run)

Chạy script ở chế độ dry run để xem những gì sẽ được xóa **MÀ KHÔNG XÓA THẬT**:

```powershell
.\scripts\cleanup-c-drive-safe.ps1 -DryRun
```

### Bước 3: Thực Hiện Dọn Dẹp

Sau khi xem trước và đồng ý, chạy script để thực sự xóa:

```powershell
.\scripts\cleanup-c-drive-safe.ps1
```

Hoặc bỏ qua xác nhận:

```powershell
.\scripts\cleanup-c-drive-safe.ps1 -SkipConfirmation
```

## Lưu Ý Quan Trọng

### An Toàn
- Script **KHÔNG** xóa project files
- Script **KHÔNG** xóa `node_modules` trong project
- Script **KHÔNG** xóa công cụ đã cài (Node.js, Python, Docker, etc.)
- Script chỉ xóa cache và temp files có thể tái tạo

### Sau Khi Dọn Dẹp
- npm cache sẽ được tái tạo tự động khi bạn chạy `npm install`
- Build artifacts có thể tái tạo bằng `npm run build`
- Python cache sẽ được tạo lại khi chạy Python scripts

### Quyền Admin
Một số tính năng (như Windows Update cleanup) cần quyền admin. Nếu cần, chạy PowerShell as Administrator:

```powershell
# Right-click PowerShell > Run as Administrator
cd D:\github-renewable\eShelf
.\scripts\cleanup-c-drive-safe.ps1
```

## 🔍 Kiểm Tra Sau Khi Dọn Dẹp

Sau khi dọn dẹp, kiểm tra lại dung lượng:

```powershell
.\scripts\check-disk-space.ps1
```

## 💡 Gợi Ý Thêm

### Dọn Dẹp Thủ Công (An Toàn)

Nếu muốn dọn dẹp thêm, bạn có thể:

1. **Disk Cleanup (Windows)**
   ```powershell
   # Chạy với quyền admin
   cleanmgr.exe /sagerun:1
   ```

2. **Xóa Files Lớn Trong Downloads**
   - Kiểm tra thư mục `C:\Users\<YourName>\Downloads`
   - Xóa các file không cần thiết

3. **Gỡ Ứng Dụng Không Dùng**
   - Settings > Apps > Apps & features
   - Gỡ các ứng dụng không cần thiết

4. **Di Chuyển Project Sang Ổ Khác**
   - Nếu ổ C quá đầy, có thể di chuyển project sang ổ D
   - Hoặc sử dụng symbolic links

### Dọn Dẹp Docker Thủ Công

```powershell
# Xem dung lượng Docker
docker system df

# Dọn dẹp tất cả (unused images, containers, volumes, networks)
docker system prune -a --volumes

# Chỉ xóa images không dùng
docker image prune -a
```

### Dọn Dẹp npm Cache Thủ Công

```powershell
# Xem vị trí cache
npm config get cache

# Xóa cache
npm cache clean --force
```

## 🐛 Troubleshooting

### Lỗi: "Access Denied"
- Một số thư mục cần quyền admin
- Chạy PowerShell as Administrator

### Lỗi: "Cannot delete file"
- File có thể đang được sử dụng
- Đóng các ứng dụng đang chạy và thử lại

### npm Cache Không Xóa Được
- Thử xóa thủ công:
  ```powershell
  $cachePath = npm config get cache
  Remove-Item -Path $cachePath -Recurse -Force
  ```

## 📊 Ước Tính Dung Lượng Giải Phóng

Tùy thuộc vào máy của bạn, script có thể giải phóng:
- Windows Temp: 0.5 - 5 GB
- Browser Cache: 0.5 - 10 GB
- npm Cache: 0.5 - 5 GB
- Docker: 1 - 20 GB (nếu có nhiều images)
- Build Artifacts: 0.1 - 2 GB
- Recycle Bin: 0.1 - 5 GB
- Windows Update: 1 - 10 GB

**Tổng cộng: 3 - 57 GB** (tùy máy)

## ✅ Checklist

Trước khi dọn dẹp:
- [ ] Đã backup các file quan trọng
- [ ] Đã chạy `check-disk-space.ps1` để xem tình trạng
- [ ] Đã chạy `cleanup-c-drive-safe.ps1 -DryRun` để xem trước

Sau khi dọn dẹp:
- [ ] Đã kiểm tra project vẫn chạy được
- [ ] Đã chạy `npm install` nếu cần (để tái tạo cache)
- [ ] Đã kiểm tra lại dung lượng với `check-disk-space.ps1`

## 📞 Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra lại script với `-DryRun` trước
2. Đọc kỹ thông báo lỗi
3. Đảm bảo đã đóng các ứng dụng đang chạy
4. Thử chạy với quyền admin nếu cần

