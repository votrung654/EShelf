# Sửa Lỗi Database Bị Mất Dữ Liệu

## Vấn Đề Đã Sửa

1. **Seed script chỉ tạo 50 sách** - Đã sửa để seed TẤT CẢ sách từ file JSON
2. **Seed script không kiểm tra dữ liệu đã tồn tại** - Đã thêm kiểm tra để bảo toàn dữ liệu hiện có
3. **Seed script không an toàn khi chạy nhiều lần** - Đã sửa để idempotent (có thể chạy nhiều lần mà không làm mất dữ liệu)

## Các Thay Đổi

### 1. Seed Script (`backend/database/prisma/seed.js`)

**Trước:**
- Chỉ seed 50 sách đầu tiên: `bookData.slice(0, 50)`
- Dùng `upsert` cho tất cả, có thể ghi đè dữ liệu

**Sau:**
- Seed TẤT CẢ sách từ file JSON
- Kiểm tra sách đã tồn tại trước khi tạo mới
- Bỏ qua sách đã có để bảo toàn dữ liệu
- Hiển thị thống kê: số sách tạo mới, số sách bỏ qua, tổng số sách

### 2. Wait-for-DB Script (`backend/database/wait-for-db.sh`)

- Thêm thông báo rõ ràng hơn về quá trình seed
- Giải thích rằng seed script sẽ bảo toàn dữ liệu hiện có

## Cách Khôi Phục Dữ Liệu

### Cách 1: Chạy Seed Script Tự Động (Khuyến nghị)

```powershell
cd backend

# Rebuild db-migration với code mới
docker-compose build db-migration

# Restart service để chạy seed
docker-compose down db-migration
docker-compose up -d db-migration

# Đợi seed chạy (khoảng 20 giây)
Start-Sleep -Seconds 20

# Kiểm tra logs
docker-compose logs db-migration | Select-String -Pattern "books|Found"
```

### Cách 2: Chạy Seed Thủ Công

```powershell
cd backend/database

# Set DATABASE_URL
$env:DATABASE_URL = "postgresql://eshelf:eshelf123@localhost:5432/eshelf?schema=public"

# Chạy seed
node prisma/seed.js
```

Hoặc dùng script có sẵn:
```powershell
cd backend/database
.\seed-books.ps1
```

### Cách 3: Test Tự Động

Chạy script test để kiểm tra quy trình:
```powershell
cd backend
.\test-database-setup.ps1
```

## Đảm Bảo Database Không Bị Mất Dữ Liệu

### 1. Database Volume

Database sử dụng Docker volume `postgres_data` để lưu trữ dữ liệu. Volume này sẽ:
- **Giữ dữ liệu** khi rebuild containers
- **Giữ dữ liệu** khi restart services
- **Mất dữ liệu** CHỈ KHI chạy `docker-compose down -v` (xóa volumes)

### 2. Seed Script An Toàn

Seed script hiện tại:
- ✅ Kiểm tra sách đã tồn tại trước khi tạo
- ✅ Bỏ qua sách đã có (không ghi đè)
- ✅ Chỉ thêm sách mới
- ✅ Có thể chạy nhiều lần an toàn

### 3. Migration Script

`wait-for-db.sh` sử dụng `prisma migrate deploy`:
- ✅ Chỉ chạy migrations mới
- ✅ **KHÔNG** reset database
- ✅ **KHÔNG** xóa dữ liệu hiện có

## Kiểm Tra Dữ Liệu

```powershell
cd backend

# Kiểm tra số lượng sách
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) FROM books;"

# Kiểm tra số lượng genres
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) FROM genres;"

# Xem một vài sách
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT isbn, title FROM books LIMIT 5;"
```

## Lưu Ý Quan Trọng

⚠️ **CẢNH BÁO:** Các lệnh sau sẽ **XÓA TẤT CẢ DỮ LIỆU**:

```powershell
# KHÔNG chạy lệnh này nếu muốn giữ dữ liệu!
docker-compose down -v  # Xóa volumes
docker-compose up -d    # Tạo lại từ đầu
```

Nếu muốn rebuild mà **GIỮ DỮ LIỆU**, chỉ cần:
```powershell
docker-compose down        # Dừng services (GIỮ volumes)
docker-compose up -d      # Start lại (dữ liệu vẫn còn)
```

## Test Quy Trình

Sau khi sửa, test để đảm bảo:
1. Database giữ dữ liệu khi rebuild
2. Seed script tạo đủ sách (không chỉ 50)
3. Seed script không làm mất dữ liệu hiện có

Chạy script test:
```powershell
cd backend
.\test-database-setup.ps1
```

