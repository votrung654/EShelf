# Hướng dẫn Setup eShelf Project

## Yêu cầu hệ thống

- **Node.js** >= 18.x
- **Python** >= 3.11
- **Docker** & **Docker Compose**
- **Git**

## Cài đặt nhanh (Quick Start)

### 1. Clone repository

```bash
git clone https://github.com/votrung654/eShelf.git
cd eShelf
```

### 2. Chạy Backend với Docker (Khuyến nghị)

```bash
cd backend
docker-compose up -d
```

Chờ khoảng 30-60 giây để tất cả services khởi động.

### 3. Chạy Frontend

```bash
# Từ thư mục root
npm install
npm run dev
```

### 4. Truy cập ứng dụng

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML Service Docs:** http://localhost:8000/docs

## Kiểm tra Services

```bash
# Kiểm tra tất cả services
curl http://localhost:3000/health  # API Gateway
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Book Service
curl http://localhost:3003/health  # User Service
curl http://localhost:8000/health  # ML Service
```

Hoặc sử dụng script:

```bash
npm run check
```

## Tài khoản mặc định

Sau khi chạy lần đầu, database sẽ được seed với:

**Admin:**
- Email: `admin@eshelf.com`
- Password: `Admin123!`

**User:**
- Email: `user@eshelf.com`
- Password: `User123!`

Hoặc bạn có thể đăng ký tài khoản mới.

## Troubleshooting

### Port đã được sử dụng

Nếu port bị chiếm, bạn có thể:

1. Dừng service đang dùng port đó
2. Hoặc thay đổi port trong `docker-compose.yml`

### Database connection error

Đảm bảo PostgreSQL container đã khởi động hoàn toàn:

```bash
docker-compose logs postgres
```

### Services không start

Kiểm tra logs:

```bash
cd backend
docker-compose logs -f
```

Hoặc kiểm tra từng service:

```bash
docker-compose logs api-gateway
docker-compose logs auth-service
```

## Development Mode (Không dùng Docker)

Nếu muốn chạy services riêng lẻ:

```bash
# Setup tất cả
npm run setup

# Hoặc chạy script
bash scripts/start-dev.sh
```

## Dừng Services

```bash
cd backend
docker-compose down

# Hoặc từ root
npm run backend:stop
```

## Reset Database

```bash
cd backend
docker-compose down -v  # Xóa volumes
docker-compose up -d    # Tạo lại
```

## Cấu trúc Services

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 5173 | React UI |
| API Gateway | 3000 | API routing |
| Auth Service | 3001 | Authentication |
| Book Service | 3002 | Book management |
| User Service | 3003 | User management |
| ML Service | 8000 | ML recommendations |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache |

