# Khôi Phục Dữ Liệu Sách

## Vấn Đề

Sau khi test database auto-build, dữ liệu sách đã bị mất vì seed script không tìm thấy file `book-details.json` trong container.

## Giải Pháp

Đã sửa 2 vấn đề:

1. **Thêm volume mount** trong `docker-compose.yml` để mount thư mục `src/data` vào container
2. **Sửa seed script** để thử nhiều paths khác nhau

## Cách Khôi Phục Dữ Liệu

### Cách 1: Rebuild và Restart (Khuyến nghị)

```powershell
cd backend

# Rebuild db-migration image với code mới
docker-compose build db-migration

# Restart db-migration service
docker-compose down db-migration
docker-compose up -d db-migration

# Đợi seed chạy xong (khoảng 10-15 giây)
Start-Sleep -Seconds 15

# Kiểm tra logs
docker-compose logs db-migration | Select-String -Pattern "book|Found"

# Kiểm tra số lượng books
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) FROM books;"
```

### Cách 2: Chạy Seed Thủ Công

Nếu cách 1 không hoạt động, chạy seed thủ công:

```powershell
cd backend/database

# Set DATABASE_URL
$env:DATABASE_URL = "postgresql://eshelf:eshelf123@localhost:5432/eshelf?schema=public"

# Chạy seed
node prisma/seed.js
```

Hoặc dùng script:

```powershell
cd backend/database
.\seed-books.ps1
```

### Cách 3: Import Trực Tiếp Vào Database

Nếu vẫn không được, có thể import trực tiếp:

```powershell
cd backend

# Copy file JSON vào container
docker cp ../src/data/book-details.json backend-db-migration-1:/app/data/

# Chạy seed trong container
docker-compose exec db-migration node prisma/seed.js
```

## Kiểm Tra

Sau khi seed xong, kiểm tra:

```powershell
cd backend

# Kiểm tra số lượng books
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as books FROM books; SELECT COUNT(*) as genres FROM genres;"

# Kiểm tra một vài books
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT title, authors FROM books LIMIT 5;"
```

## Lưu Ý

- File `book-details.json` phải tồn tại ở `src/data/book-details.json` (root của project)
- Volume mount đã được cấu hình trong `docker-compose.yml` để container có thể truy cập file
- Seed script sẽ tự động tìm file ở nhiều paths khác nhau

## Nếu Vẫn Không Hoạt Động

1. Kiểm tra file có tồn tại:
   ```powershell
   Test-Path "D:\github-renewable\eShelf\src\data\book-details.json"
   ```

2. Kiểm tra volume mount:
   ```powershell
   cd backend
   docker-compose exec db-migration ls -la /app/data/
   ```

3. Kiểm tra logs chi tiết:
   ```powershell
   docker-compose logs db-migration
   ```

