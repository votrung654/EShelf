# Services Database Sync

## Tổng Quan

Tất cả services dùng **CHUNG một database** PostgreSQL. Database được tạo tự động bởi `db-migration` service.

## Database Setup Tự Động

### Quy Trình

```
docker-compose up -d
  ↓
postgres starts → healthy
  ↓
db-migration starts (sau khi postgres healthy)
  ↓
wait-for-db.sh:
  1. Chờ postgres ready
  2. Chạy migrations (tạo schema)
  3. Chạy seed (tạo users, seed 40 sách)
  ↓
Các services khác start (sau khi db-migration completed)
```

### Database Connection

Tất cả services dùng cùng `DATABASE_URL`:
```
postgresql://eshelf:eshelf123@postgres:5432/eshelf?schema=public
```

## Prisma Schema Files

### Schema Locations

1. **`backend/database/prisma/schema.prisma`** (Master schema)
   - Dùng cho db-migration service
   - Đây là schema chính, được dùng để tạo database

2. **`backend/services/auth-service/prisma/schema.prisma`**
   - Schema riêng cho auth-service
   - **Cần sync với master schema**

3. **`backend/services/book-service/prisma/schema.prisma`**
   - Schema riêng cho book-service
   - **Cần sync với master schema**

4. **`backend/services/user-service/`**
   - **Dùng chung schema từ `database/prisma/schema.prisma`**
   - Copy trong Dockerfile: `COPY database/prisma ./prisma`

### Prisma Client Generation

Tất cả services đã có `prisma generate` trong Dockerfile:

- **auth-service**: `RUN npx prisma generate`
- **book-service**: `RUN npx prisma generate` + `postinstall: "prisma generate"`
- **user-service**: `RUN npx prisma generate` (dùng schema từ database/prisma)

## Services Dependencies

Tất cả services đã có `depends_on: db-migration`:

```yaml
depends_on:
  db-migration:
    condition: service_completed_successfully
```

Điều này đảm bảo:
- Database đã được setup (migrations chạy xong)
- Database đã có dữ liệu seed
- Services chỉ start sau khi database sẵn sàng

## Khi Nào Cần Rebuild Services?

### Cần Rebuild Khi:

1. **Database schema thay đổi** (thêm/xóa/sửa models)
   - Cần rebuild tất cả services để generate Prisma client mới
   - Command: `docker-compose build`

2. **Prisma version thay đổi**
   - Cần rebuild để sync Prisma client version

3. **Dependencies thay đổi** (package.json)
   - Cần rebuild để cài dependencies mới

### KHÔNG Cần Rebuild Khi:

1. **Chỉ thay đổi dữ liệu** (seed thêm sách, users)
   - Database tự động seed, services không cần rebuild

2. **Chỉ thay đổi business logic** (code trong src/)
   - Chỉ cần restart service: `docker-compose restart <service>`

## Đảm Bảo Schema Sync

### Vấn Đề Tiềm Ẩn

- `auth-service` và `book-service` có schema riêng
- Nếu master schema thay đổi, cần update schema của các services

### Giải Pháp

**Option 1: Dùng chung schema (Khuyến nghị)**

Sửa Dockerfile của auth-service và book-service để dùng chung schema:

```dockerfile
# Thay vì COPY prisma ./prisma/
COPY ../database/prisma ./prisma/
```

**Option 2: Sync schema thủ công**

Khi thay đổi master schema, cần copy sang các services:
```bash
cp backend/database/prisma/schema.prisma backend/services/auth-service/prisma/
cp backend/database/prisma/schema.prisma backend/services/book-service/prisma/
```

**Option 3: Symbolic link (Development)**

Trong development, có thể dùng symbolic link để sync tự động.

## Best Practices

1. **Dùng chung schema** - user-service đã làm đúng
2. **Prisma generate trong Dockerfile** - Tất cả services đã có
3. **depends_on db-migration** - Tất cả services đã có
4. **Sync schema khi thay đổi** - Cần chú ý cho auth-service và book-service

## Kết Luận

**Database tự động setup** - db-migration service làm việc này
**Services tự động đợi database** - depends_on đảm bảo
**Prisma client tự động generate** - Khi build services
⚠️ **Cần đảm bảo schema sync** - Cho auth-service và book-service

**Hiện tại: Ổn, nhưng nên cải thiện để dùng chung schema cho tất cả services.**

