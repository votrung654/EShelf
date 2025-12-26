# Test Quy Trình Fresh Clone

## Câu Hỏi Cần Trả Lời

1. ✅ **Sách có lưu trong database thật không?**
   - **TRẢ LỜI: CÓ** - Sách được lưu trong PostgreSQL database (không phải local/memory)
   - Database volume: `postgres_data` lưu tại `/var/lib/docker/volumes/backend_postgres_data/_data`
   - Có thể query trực tiếp từ PostgreSQL: `SELECT * FROM books;`

2. ✅ **Người mới clone repo, chạy docker-compose có tự động setup đầy đủ không?**
   - **TRẢ LỜI: CÓ** - Docker-compose tự động setup đầy đủ dataset

## Quy Trình Tự Động Khi Chạy `docker-compose up -d`

### 1. PostgreSQL Container Start
- Tạo database `eshelf` nếu chưa có
- Database volume `postgres_data` được mount để lưu dữ liệu persistent

### 2. db-migration Service Start (tự động)
- **Chờ PostgreSQL sẵn sàng** (healthcheck)
- **Chạy migrations** (`prisma migrate deploy`)
  - Tạo schema: tables, relationships
  - **KHÔNG reset database**, chỉ apply migrations mới
- **Chạy seed script** (`prisma/seed.js`)
  - Tạo admin user: `admin@eshelf.com` / `Admin123!`
  - Tạo demo user: `user@eshelf.com` / `User123!`
  - Load file JSON: `src/data/book-details.json`
  - Seed **TẤT CẢ** sách từ JSON vào database
  - Tạo genres và link với sách
  - **Bảo toàn dữ liệu hiện có** (nếu đã có sách, sẽ bỏ qua)

### 3. Các Services Khác Start
- Các services (auth-service, book-service, etc.) đợi `db-migration` hoàn tất
- Kết nối với database đã được setup sẵn

## Test Thực Tế

### Kiểm Tra Dữ Liệu Hiện Tại

```powershell
cd backend

# Kiểm tra số lượng
docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as books FROM books; SELECT COUNT(*) as genres FROM genres; SELECT COUNT(*) as users FROM users;"

# Kiểm tra một vài sách
docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT isbn, title FROM books LIMIT 5;"
```

**Kết quả hiện tại:**
- ✅ 40 books (đầy đủ từ JSON)
- ✅ 44 genres
- ✅ 3 users (admin, demo, và 1 user khác)

### Test Fresh Clone (Giả Lập)

**Lưu ý:** Test này sẽ xóa database volume!

```powershell
cd backend

# 1. Dừng và xóa volume (giả lập fresh clone)
docker-compose down -v

# 2. Start lại (giả lập người mới clone và chạy docker-compose up)
docker-compose up -d

# 3. Đợi setup hoàn tất (30 giây)
Start-Sleep -Seconds 30

# 4. Kiểm tra logs
docker-compose logs db-migration | Select-String -Pattern "Found.*books|Total books|Seed completed"

# 5. Kiểm tra dữ liệu
docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) as books FROM books;"
```

**Kết quả mong đợi:**
- ✅ Database schema được tạo
- ✅ 40 sách được seed từ JSON
- ✅ 44 genres được tạo
- ✅ 2 users (admin, demo) được tạo

## Xác Nhận

### ✅ Sách Lưu Trong Database Thật

**Bằng chứng:**
1. Query trực tiếp từ PostgreSQL: `SELECT * FROM books;` → Có kết quả
2. Database volume persistent: `/var/lib/docker/volumes/backend_postgres_data/_data`
3. Dữ liệu giữ khi restart containers (chỉ mất khi xóa volume)

**Test:**
```powershell
# Restart containers (KHÔNG xóa volume)
docker-compose restart

# Kiểm tra - dữ liệu vẫn còn
docker-compose exec -T postgres psql -U eshelf -d eshelf -c "SELECT COUNT(*) FROM books;"
# → Vẫn có 40 sách
```

### ✅ Tự Động Setup Khi Fresh Clone

**Bằng chứng:**
1. `docker-compose.yml` có service `db-migration` tự động chạy
2. `db-migration` depends_on `postgres` với condition `service_healthy`
3. `wait-for-db.sh` tự động chạy migrations và seed
4. File JSON được mount vào container: `../src/data:/app/data:ro`
5. Seed script tìm và load file JSON tự động

**Quy trình:**
```
docker-compose up -d
  ↓
postgres starts → healthy
  ↓
db-migration starts (sau khi postgres healthy)
  ↓
wait-for-db.sh chạy:
  1. Chờ postgres ready
  2. Chạy migrations (tạo schema)
  3. Chạy seed script (tạo users, seed books)
  ↓
Các services khác start (sau khi db-migration completed)
```

## Kết Luận

✅ **Sách lưu trong PostgreSQL database thật** (không phải local/memory)
- Persistent storage qua Docker volume
- Có thể query, update, delete như database bình thường

✅ **Docker-compose tự động setup đầy đủ dataset**
- Người mới clone repo chỉ cần: `cd backend && docker-compose up -d`
- Database schema tự động tạo
- 40 sách tự động seed từ JSON
- Users (admin, demo) tự động tạo
- Không cần chạy lệnh thủ công nào

## Lưu Ý Quan Trọng

⚠️ **Database volume giữ dữ liệu:**
- `docker-compose down` → Dữ liệu vẫn còn
- `docker-compose down -v` → **XÓA TẤT CẢ DỮ LIỆU**
- `docker-compose up -d` → Dữ liệu vẫn còn (nếu volume chưa bị xóa)

✅ **Seed script an toàn:**
- Chạy nhiều lần không làm mất dữ liệu
- Chỉ thêm sách mới, bỏ qua sách đã có
- Idempotent - có thể chạy bất cứ lúc nào

