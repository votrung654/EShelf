# Smart Build System - Chỉ Build Khi Cần

## Tổng Quan

Hệ thống Smart Build được thiết kế để **chỉ build khi có thay đổi code thực sự**, bỏ qua các thay đổi chỉ là:
- Comment (//, #, /* */, <!-- -->)
- Whitespace
- Formatting

## Cách Hoạt Động

### 1. Path Filtering (Bước 1)
- Sử dụng `dorny/paths-filter@v2` để detect files thay đổi trong từng service
- Nhanh và hiệu quả, filter theo đường dẫn

### 2. Code Change Detection (Bước 2)
- Sử dụng `scripts/check-service-changes.sh` để phân tích git diff
- Loại bỏ các dòng chỉ là comment
- Chỉ build nếu có code thực sự thay đổi

## Scripts

### `check-service-changes.sh`
```bash
./scripts/check-service-changes.sh <service_path1> [service_path2] ... [base_ref]
```

**Chức năng:**
- So sánh thay đổi giữa base_ref và HEAD
- Phân tích từng file đã thay đổi
- Loại bỏ comment và whitespace
- Return 0 nếu có code changes, 1 nếu chỉ comment

**Ví dụ:**
```bash
# Check frontend changes
./scripts/check-service-changes.sh src public package.json HEAD~1

# Check API Gateway changes
./scripts/check-service-changes.sh backend/services/api-gateway HEAD~1
```

### `check-code-changes.sh`
```bash
./scripts/check-code-changes.sh <file_path> [base_ref]
```

**Chức năng:**
- Check một file cụ thể
- Phân tích diff của file đó
- Return 0 nếu có code changes, 1 nếu chỉ comment

## Các Trường Hợp Được Xử Lý

### ✅ Sẽ Build:
- Thay đổi code thực sự (function, class, logic)
- Thay đổi config files (package.json, Dockerfile, .env, etc.)
- Thay đổi dependencies
- Thay đổi build scripts

### ❌ Không Build:
- Chỉ thay đổi comment
- Chỉ thay đổi whitespace
- Chỉ format code (không thay đổi logic)
- Chỉ thay đổi documentation

## Ví Dụ

### Case 1: Chỉ Comment - Không Build
```javascript
// Before
function getUser() {
  return user;
}

// After
// Get user information
function getUser() {
  return user;
}
```
→ **Không build** vì chỉ thêm comment

### Case 2: Code Change - Sẽ Build
```javascript
// Before
function getUser() {
  return user;
}

// After
function getUser(id) {
  return users.find(u => u.id === id);
}
```
→ **Sẽ build** vì có thay đổi logic

### Case 3: Config Change - Sẽ Build
```json
// package.json
{
  "dependencies": {
    "express": "^4.18.2"  // Changed version
  }
}
```
→ **Sẽ build** vì config files luôn cần build

## Lợi Ích

1. **Tiết kiệm thời gian**: Không build không cần thiết
2. **Tiết kiệm tài nguyên**: Giảm CI/CD costs
3. **Nhanh hơn**: Pipeline chạy nhanh hơn
4. **Thông minh**: Tự động detect thay đổi thực sự

## Lưu Ý

- Scripts cần quyền execute: `chmod +x scripts/*.sh`
- GitHub Actions tự động chmod khi chạy
- Base ref mặc định: `HEAD~1` (commit trước)
- PR sẽ so sánh với base branch

## Troubleshooting

### Script không chạy được
```bash
# Check permissions
ls -l scripts/*.sh

# Chmod nếu cần
chmod +x scripts/check-service-changes.sh
chmod +x scripts/check-code-changes.sh
```

### Test locally
```bash
# Test với git diff
git diff HEAD~1 HEAD -- src/

# Test script
./scripts/check-service-changes.sh src HEAD~1
```

