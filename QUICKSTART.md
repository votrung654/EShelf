# 🚀 Quick Start Guide

Hướng dẫn chạy nhanh eShelf trong 5 phút.

## Yêu cầu

- Node.js >= 18
- Docker & Docker Compose (optional)
- Git

## Bước 1: Clone Project

```bash
git clone https://github.com/levanvux/eShelf.git
cd eShelf
```

## Bước 2: Chạy Frontend

```bash
# Install dependencies
npm install

# Start dev server
npm run dev
```

✅ Frontend: http://localhost:5173

## Bước 3: Chạy Backend (Chọn 1 trong 2 cách)

### Cách 1: Docker Compose (Khuyến nghị)

```bash
cd backend
docker-compose up -d
```

### Cách 2: Manual (Không cần Docker)

**Terminal 1:**
```bash
cd backend/services/api-gateway
npm install
npm run dev
```

**Terminal 2:**
```bash
cd backend/services/auth-service
npm install
npm run dev
```

**Terminal 3:**
```bash
cd backend/services/book-service
npm install
npm run dev
```

**Terminal 4:**
```bash
cd backend/services/user-service
npm install
npm run dev
```

**Terminal 5:**
```bash
cd backend/services/ml-service
pip install -r requirements.txt
uvicorn src.main:app --reload
```

## Bước 4: Kiểm tra

```bash
# Check services
curl http://localhost:3000/health  # API Gateway
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Book Service
curl http://localhost:3003/health  # User Service
curl http://localhost:8000/health  # ML Service
```

## Bước 5: Truy cập

- **Website:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **ML API Docs:** http://localhost:8000/docs

## Test Account

Đăng ký tài khoản mới hoặc dùng localStorage để test.

## Dừng Services

```bash
# Docker Compose
cd backend
docker-compose down

# Manual: Ctrl+C trong mỗi terminal
```

## Troubleshooting

### Port đã được sử dụng

```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### Docker không chạy

```bash
# Start Docker Desktop
# Hoặc start Docker daemon

# Verify
docker ps
```

### npm install lỗi

```bash
# Clear cache
npm cache clean --force

# Delete node_modules và reinstall
rm -rf node_modules
npm install
```

## Next Steps

- Đọc [README.md](README.md) để hiểu chi tiết
- Đọc [PLAN.md](PLAN.md) để biết roadmap
- Xem [docs/master_prompts.md](docs/master_prompts.md) để biết kế hoạch phát triển

