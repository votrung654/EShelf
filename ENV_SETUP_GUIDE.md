# Hướng Dẫn Setup Biến Môi Trường

## Tổng Quan

Project eShelf sử dụng biến môi trường để quản lý các thông tin nhạy cảm như:
- Database credentials
- JWT secrets
- API keys
- Service URLs

## Cài Đặt

### Bước 1: Tạo file .env

**Ở root project:**
```powershell
Copy-Item .env.example .env
```

**Ở backend (nếu cần):**
```powershell
Copy-Item backend\.env.example backend\.env
```

### Bước 2: Điền thông tin thực tế

Mở file `.env` và cập nhật các giá trị:

#### Bắt buộc phải thay đổi:
- `JWT_SECRET`: Tạo secret mạnh cho production
  ```powershell
  # Tạo secret mạnh (Windows)
  [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([System.Guid]::NewGuid().ToString() + [System.Guid]::NewGuid().ToString()))
  ```
  
- `JWT_REFRESH_SECRET`: Tạo secret mạnh khác cho refresh token
- `POSTGRES_PASSWORD`: Đổi password database (không dùng mặc định)
- `DATABASE_URL`: Cập nhật nếu đã đổi password

#### Tùy chọn:
- `NODE_ENV`: `development` hoặc `production`
- `VITE_API_URL`: URL của API Gateway (frontend)
- Service URLs: Chỉ cần thay đổi nếu không dùng Docker Compose

### Bước 3: Kiểm tra setup

Chạy script kiểm tra:
```powershell
.\scripts\test-env-setup.ps1
```

## Sử Dụng với Docker Compose

Docker Compose sẽ tự động đọc file `.env` ở thư mục `backend/`:

```powershell
cd backend
docker-compose up -d
```

Nếu file `.env` không tồn tại, docker-compose sẽ sử dụng giá trị mặc định (KHÔNG AN TOÀN cho production).

## Biến Môi Trường Theo Service

### Frontend (React/Vite)
- `VITE_API_URL`: URL của API Gateway

### API Gateway
- `PORT`: Port của gateway (mặc định: 3000)
- `AUTH_SERVICE_URL`: URL của auth service
- `BOOK_SERVICE_URL`: URL của book service
- `USER_SERVICE_URL`: URL của user service
- `ML_SERVICE_URL`: URL của ML service
- `JWT_SECRET`: Secret để verify JWT tokens
- `ALLOWED_ORIGINS`: CORS allowed origins

### Auth Service
- `PORT`: Port của service (mặc định: 3001)
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret để sign JWT tokens
- `JWT_REFRESH_SECRET`: Secret để sign refresh tokens
- `ALLOWED_ORIGINS`: CORS allowed origins

### Book Service
- `PORT`: Port của service (mặc định: 3002)
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret để verify JWT tokens
- `ALLOWED_ORIGINS`: CORS allowed origins

### User Service
- `PORT`: Port của service (mặc định: 3003)
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret để verify JWT tokens
- `ALLOWED_ORIGINS`: CORS allowed origins

### ML Service
- `ML_SERVICE_PORT`: Port của service (mặc định: 8000)
- `ML_SERVICE_HOST`: Host (mặc định: 0.0.0.0)

### PostgreSQL
- `POSTGRES_USER`: Database user (mặc định: eshelf)
- `POSTGRES_PASSWORD`: Database password (PHẢI ĐỔI!)
- `POSTGRES_DB`: Database name (mặc định: eshelf)
- `POSTGRES_HOST`: Database host (mặc định: postgres trong Docker)
- `POSTGRES_PORT`: Database port (mặc định: 5432)

## Bảo Mật

### ✅ Đã Làm:
- File `.env` đã được thêm vào `.gitignore`
- File `.env.example` được commit (không chứa thông tin thực)
- Docker Compose sử dụng biến môi trường
- Code sử dụng `process.env` thay vì hardcode

### ⚠️ Lưu Ý:
1. **KHÔNG BAO GIỜ commit file `.env` lên Git**
2. **Đổi tất cả giá trị mặc định** trước khi deploy production
3. **Sử dụng secrets management** (AWS Secrets Manager, HashiCorp Vault) cho production
4. **Rotate secrets định kỳ** (đặc biệt là JWT secrets)

## Troubleshooting

### Lỗi: "Cannot connect to database"
- Kiểm tra `DATABASE_URL` có đúng không
- Kiểm tra PostgreSQL container đã chạy chưa: `docker ps`
- Kiểm tra password có đúng không

### Lỗi: "JWT verification failed"
- Kiểm tra `JWT_SECRET` giống nhau ở tất cả services
- Kiểm tra token không hết hạn

### Lỗi: "CORS error"
- Kiểm tra `ALLOWED_ORIGINS` có chứa frontend URL không
- Kiểm tra format: `http://localhost:5173,http://localhost:3000`

## Production Checklist

Trước khi deploy production, đảm bảo:

- [ ] Đã tạo file `.env` với giá trị thực
- [ ] Đã đổi `JWT_SECRET` và `JWT_REFRESH_SECRET`
- [ ] Đã đổi `POSTGRES_PASSWORD`
- [ ] Đã cập nhật `DATABASE_URL` với password mới
- [ ] Đã set `NODE_ENV=production`
- [ ] Đã kiểm tra bằng `.\scripts\test-env-setup.ps1`
- [ ] Đã test kết nối database
- [ ] Đã test authentication flow
- [ ] Đã backup credentials ở nơi an toàn (không phải Git)

