# Troubleshooting Guide

## Lỗi: "relation does not exist" hoặc "table does not exist"

### Nguyên nhân
Database migrations chưa được chạy. Các bảng `books`, `genres`, `users`, etc. chưa được tạo trong database.

### Giải pháp

**1. Kiểm tra migration service đã chạy chưa:**
```bash
docker-compose logs db-migration
```

**2. Nếu migration service chưa chạy hoặc bị lỗi:**
```bash
# Xem logs chi tiết
docker-compose logs db-migration

# Restart migration service
docker-compose up db-migration

# Hoặc restart toàn bộ
docker-compose down
docker-compose up -d
```

**3. Nếu vẫn lỗi, chạy migrations thủ công:**
```bash
# Vào container migration
docker-compose exec db-migration sh

# Hoặc chạy từ host (nếu đã cài Prisma)
cd backend/database
npm install
npx prisma migrate deploy
```

**4. Kiểm tra database connection:**
```bash
# Kiểm tra PostgreSQL đang chạy
docker-compose ps postgres

# Kiểm tra logs PostgreSQL
docker-compose logs postgres

# Test connection
docker-compose exec postgres psql -U eshelf -d eshelf -c "SELECT 1;"
```

## Lỗi: Migration service không start

### Nguyên nhân
- Database chưa sẵn sàng
- DATABASE_URL không đúng
- Biến môi trường trong `.env` không khớp
- Network issues

### Giải pháp

**1. Kiểm tra file .env:**
```bash
# Kiểm tra file .env có tồn tại không
ls -la backend/.env

# Nếu chưa có, tạo từ .env.example (nếu có)
cp backend/.env.example backend/.env

# Kiểm tra các biến môi trường quan trọng
cat backend/.env | grep -E "DATABASE_URL|POSTGRES_"
```

**2. Kiểm tra DATABASE_URL có đúng không:**
```bash
# Xem giá trị DATABASE_URL được sử dụng
docker-compose config | grep DATABASE_URL

# Kiểm tra format DATABASE_URL
# Phải có dạng: postgresql://user:password@postgres:5432/database?schema=public
```

**3. Kiểm tra các biến POSTGRES_*:**
```bash
# Nếu không set DATABASE_URL, docker-compose sẽ build từ POSTGRES_*
# Đảm bảo các biến này khớp với postgres service
docker-compose config | grep POSTGRES
```

**4. Kiểm tra PostgreSQL health:**
```bash
docker-compose ps postgres
# Phải thấy "healthy" status
```

**5. Kiểm tra network:**
```bash
docker network ls
docker network inspect backend_eshelf-network
```

**6. Nếu DATABASE_URL trong .env không khớp:**
```bash
# Ví dụ: Nếu .env có DATABASE_URL khác với POSTGRES_* settings
# Thì DATABASE_URL sẽ được ưu tiên, nhưng phải đảm bảo:
# - Host phải là "postgres" (tên service trong docker-compose)
# - Port phải là 5432
# - User, password, database phải khớp với postgres service

# Sửa .env file:
# DATABASE_URL=postgresql://eshelf:eshelf123@postgres:5432/eshelf?schema=public
```

## Lỗi: Services start trước khi migrations hoàn tất

### Nguyên nhân
Docker Compose có thể start services song song nếu không có `depends_on` đúng.

### Giải pháp

Đảm bảo trong `docker-compose.yml`, các services có:
```yaml
depends_on:
  db-migration:
    condition: service_completed_successfully
```

Sau đó restart:
```bash
docker-compose down
docker-compose up -d
```

## Reset Database (Xóa tất cả dữ liệu)

⚠️ **Cảnh báo:** Lệnh này sẽ xóa tất cả dữ liệu!

```bash
docker-compose down -v  # Xóa volumes
docker-compose up -d    # Tạo lại từ đầu
```

## Xem logs của tất cả services

```bash
docker-compose logs -f
```

## Xem logs của một service cụ thể

```bash
docker-compose logs -f book-service
docker-compose logs -f db-migration
docker-compose logs -f postgres
```

