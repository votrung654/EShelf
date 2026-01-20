# Hướng Dẫn Demo - eShelf Project

## Tổng Quan

Project đã hoàn thành ~90% yêu cầu. Phần còn lại chủ yếu là setup thủ công và test.

## Trước Khi Demo

### 1. Kiểm Tra Cluster

```powershell
.\scripts\quick-check.ps1 -Detailed
```

**Kỳ vọng:**
- 3 nodes Ready
- Hầu hết pods Running
- Services accessible

### 2. Đọc Tài Liệu

- **Trạng thái project:** `docs/PROJECT_STATUS_SUMMARY.md`
- **Phần cần setup:** `docs/MANUAL_SETUP_REQUIRED.md`
- **Kịch bản demo:** `docs/DEMO_SCRIPT.md`
- **Nội dung slide:** `docs/SLIDE_CONTENT.md`
- **Kiến trúc:** `docs/ARCHITECTURE_DIAGRAM.md`

## Setup Thủ Công (Ưu Tiên)

Xem chi tiết trong `docs/MANUAL_SETUP_REQUIRED.md`:

1. **GitHub Secrets** (5 phút)
   - HARBOR_REGISTRY
   - HARBOR_USERNAME
   - HARBOR_PASSWORD

2. **Fix Harbor Issues** (15-30 phút)
   - harbor-core Redis connection
   - harbor-nginx CrashLoopBackOff

3. **Push Images** (10-20 phút)
   - Chạy `.\scripts\push-images-to-harbor.ps1`

4. **Sửa ArgoCD Annotations** (5 phút)
   - Sửa `harbor.yourdomain.com` thành địa chỉ thật

5. **Scale Up Applications** (2 phút)
   - `kubectl scale deployment -n eshelf-dev --all --replicas=1`

## Demo Flow

Xem chi tiết trong `docs/DEMO_SCRIPT.md`:

1. **Giới thiệu kiến trúc** (5 phút)
2. **Demo Smart Build** (10 phút)
3. **Demo CI/CD Pipeline** (15 phút)
4. **Demo GitOps & Image Updater** (10 phút)
5. **Demo Monitoring** (10 phút)
6. **Demo Security** (5 phút)
7. **Demo Rollback** (5 phút)
8. **Kết luận** (5 phút)

**Tổng thời gian:** ~60 phút

## Files Quan Trọng

### Scripts
- `scripts/quick-check.ps1` - Kiểm tra cluster nhanh
- `scripts/push-images-to-harbor.ps1` - Push images tự động

### Documentation
- `docs/PROJECT_STATUS_SUMMARY.md` - Trạng thái project
- `docs/MANUAL_SETUP_REQUIRED.md` - Phần cần setup thủ công
- `docs/DEMO_SCRIPT.md` - Kịch bản demo chi tiết
- `docs/SLIDE_CONTENT.md` - Nội dung slide
- `docs/ARCHITECTURE_DIAGRAM.md` - Kiến trúc chi tiết
- `docs/REQUIREMENTS_CHECKLIST.md` - Checklist yêu cầu

## Quick Start

### 1. Check Status
```powershell
.\scripts\quick-check.ps1
```

### 2. Setup GitHub Secrets
Vào GitHub > Settings > Secrets > Actions

### 3. Fix Harbor
Xem `docs/MANUAL_SETUP_REQUIRED.md` section 2

### 4. Push Images
```powershell
kubectl port-forward svc/harbor-core -n harbor 8080:80
.\scripts\push-images-to-harbor.ps1
```

### 5. Test Services
Xem `FINAL_TESTING_CHECKLIST.md`

### 6. Demo
Xem `docs/DEMO_SCRIPT.md`

## Lưu Ý

- Cluster cần ổn định trước khi demo
- Practice demo ít nhất 2 lần
- Chuẩn bị backup video nếu demo trực tiếp lỗi
- Có screenshots các bước quan trọng

## Support

Nếu có vấn đề:
1. Check `docs/MANUAL_SETUP_REQUIRED.md`
2. Check `docs/PROJECT_STATUS_SUMMARY.md`
3. Run `.\scripts\quick-check.ps1 -Detailed`

