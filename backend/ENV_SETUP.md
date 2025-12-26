# Environment Variables Setup

## Có Cần File .env Không?

### Câu Trả Lời: **KHÔNG CẦN**

Docker-compose đã có **giá trị mặc định** cho tất cả biến môi trường. Bạn có thể chạy ngay mà không cần tạo file `.env`.

## Giá Trị Mặc Định

Tất cả biến môi trường đã có giá trị mặc định trong `docker-compose.yml`:

| Biến | Giá Trị Mặc Định | Mô Tả |
|------|------------------|-------|
| `POSTGRES_USER` | `eshelf` | Database user |
| `POSTGRES_PASSWORD` | `eshelf123` | Database password |
| `POSTGRES_DB` | `eshelf` | Database name |
| `DATABASE_URL` | `postgresql://eshelf:eshelf123@postgres:5432/eshelf?schema=public` | Full connection string |
| `JWT_SECRET` | `your-secret-key` | JWT secret (lưu ý: đổi trong production) |
| `JWT_REFRESH_SECRET` | `your-refresh-secret` | JWT refresh secret |
| `NODE_ENV` | `development` | Node environment |
| `ALLOWED_ORIGINS` | `http://localhost:5173,http://localhost:3000` | CORS allowed origins |

## Chạy Không Cần .env

```bash
# Clone repo
git clone https://github.com/votrung654/EShelf.git
cd EShelf/backend

# Chạy ngay (không cần .env)
docker-compose up -d
```

**Kết quả:** Tất cả services sẽ dùng giá trị mặc định và chạy được ngay!

## Khi Nào Cần .env?

### Cần Tạo .env Khi:

1. **Production Environment**
   - Cần đổi `JWT_SECRET` (bắt buộc!)
   - Cần đổi database password
   - Cần custom database settings

2. **Development Custom Settings**
   - Muốn dùng database khác
   - Muốn đổi ports
   - Muốn custom CORS origins

3. **Team Development**
   - Mỗi developer có settings riêng
   - Không muốn commit sensitive data

### Không Cần .env Khi:

- Chỉ test/demo local
- Dùng giá trị mặc định
- Development đơn giản

## Cách Tạo .env (Nếu Cần)

### Bước 1: Copy .env.example

```bash
cd backend
cp .env.example .env
```

### Bước 2: Chỉnh Sửa .env

Mở file `.env` và uncomment các biến muốn thay đổi:

```env
# Ví dụ: Đổi database password
POSTGRES_PASSWORD=my-secure-password

# Ví dụ: Đổi JWT secret (QUAN TRỌNG cho production!)
JWT_SECRET=my-super-secret-key-change-this-in-production

# Ví dụ: Custom database URL
DATABASE_URL=postgresql://myuser:mypass@postgres:5432/mydb?schema=public
```

### Bước 3: Restart Services

```bash
docker-compose down
docker-compose up -d
```

## Lưu Ý Quan Trọng

### 1. DATABASE_URL Format

Nếu bạn set `DATABASE_URL` trong `.env`, đảm bảo:
- **Host phải là `postgres`** (tên service trong docker-compose)
- **Port phải là `5432`**
- **User, password, database phải khớp** với `POSTGRES_*` settings

Ví dụ đúng:
```env
DATABASE_URL=postgresql://eshelf:eshelf123@postgres:5432/eshelf?schema=public
```

Ví dụ sai (sẽ không hoạt động):
```env
DATABASE_URL=postgresql://eshelf:eshelf123@localhost:5432/eshelf  # SAI: localhost thay vì postgres
```

### 2. JWT_SECRET trong Production

**BẮT BUỘC** phải đổi `JWT_SECRET` trong production

```env
JWT_SECRET=your-very-secure-random-secret-key-here
JWT_REFRESH_SECRET=your-very-secure-random-refresh-secret-here
```

### 3. .env File Không Được Commit

File `.env` đã có trong `.gitignore`, không được commit lên git.

## Kiểm Tra Giá Trị Đang Dùng

### Xem Giá Trị Từ Docker Compose

```bash
cd backend

# Xem tất cả environment variables
docker-compose config | grep -A 5 "environment:"

# Xem DATABASE_URL cụ thể
docker-compose config | grep DATABASE_URL

# Xem POSTGRES settings
docker-compose config | grep POSTGRES
```

### Xem Giá Trị Trong Container

```bash
# Xem env trong một service
docker-compose exec auth-service env | grep DATABASE_URL
docker-compose exec postgres env | grep POSTGRES
```

## So Sánh: Có .env vs Không Có .env

| Tình Huống | Có .env | Không Có .env |
|------------|---------|---------------|
| **Development** | Tùy chọn | Hoạt động ngay |
| **Production** | Nên có | Không an toàn |
| **Team Dev** | Nên có | OK nếu dùng default |
| **Custom Settings** | Cần có | Không thể custom |

## Tóm Tắt

1. **Không cần .env để chạy** - Giá trị mặc định đã đủ
2. **Nên có .env cho production** - Để đổi JWT_SECRET và password
3. **Có thể có .env cho development** - Nếu muốn custom settings
4. **.env.example có sẵn** - Copy và chỉnh sửa nếu cần

## Kết Luận

**Cho người mới clone:**
- **KHÔNG CẦN** tạo .env
- Chạy `docker-compose up -d` là được
- Tất cả dùng giá trị mặc định

**Cho production:**
- **NÊN** tạo .env
- **BẮT BUỘC** đổi JWT_SECRET
- **NÊN** đổi database password

