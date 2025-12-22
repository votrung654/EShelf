# 🧪 Hướng dẫn Test Components trước khi chuyển sang Ops

Tài liệu này hướng dẫn cách test tất cả các components (FE, BE, Database, ML-AI) trước khi triển khai phần Ops (DevOps/Infrastructure).

## 📋 Mục lục

1. [Tổng quan](#tổng-quan)
2. [Chuẩn bị](#chuẩn-bị)
3. [Test Frontend](#1-test-frontend)
4. [Test Backend Services](#2-test-backend-services)
5. [Test Database](#3-test-database)
6. [Test ML-AI Service](#4-test-ml-ai-service)
7. [Test Integration](#5-test-integration)
8. [Chạy Test Tự động](#chạy-test-tự-động)
9. [Troubleshooting](#troubleshooting)

---

## Tổng quan

Trước khi chuyển sang phần Ops (Terraform, Kubernetes, CI/CD), bạn cần đảm bảo:

- ✅ **Frontend**: React app chạy và render đúng
- ✅ **Backend**: Tất cả microservices hoạt động
- ✅ **Database**: PostgreSQL kết nối và có schema
- ✅ **ML-AI**: FastAPI service chạy và models hoạt động
- ✅ **Integration**: Các services giao tiếp với nhau đúng

---

## Chuẩn bị

### 1. Start tất cả services

```bash
# Option 1: Docker Compose (Khuyến nghị)
cd backend
docker-compose up -d

# Option 2: Manual
# Terminal 1: Frontend
npm run dev

# Terminal 2-5: Backend services
# (Xem QUICKSTART.md)
```

### 2. Verify services đang chạy

```bash
# Check Docker containers
docker ps

# Hoặc dùng script có sẵn
npm run check
```

---

## 1. Test Frontend

### Manual Testing

1. **Mở browser**: http://localhost:5173
2. **Kiểm tra**:
   - ✅ Page load không lỗi
   - ✅ UI render đúng
   - ✅ Navigation hoạt động
   - ✅ API calls thành công (check Network tab)

### Automated Testing

```bash
# Check frontend đang chạy
curl http://localhost:5173

# Check build
npm run build
ls -la dist/  # hoặc build/
```

### Expected Results

- ✅ Frontend accessible tại http://localhost:5173
- ✅ Build thành công không lỗi
- ✅ React app render đúng

---

## 2. Test Backend Services

### 2.1 API Gateway (Port 3000)

```bash
# Health check
curl http://localhost:3000/health

# Expected: {"status":"ok",...}
```

### 2.2 Auth Service (Port 3001)

```bash
# Health check
curl http://localhost:3001/health

# Test register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "username": "testuser",
    "name": "Test User"
  }'

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

### 2.3 Book Service (Port 3002)

```bash
# Health check
curl http://localhost:3002/health

# Get books
curl http://localhost:3000/api/books?limit=5

# Search books
curl "http://localhost:3000/api/books/search?q=harry"
```

### 2.4 User Service (Port 3003)

```bash
# Health check
curl http://localhost:3003/health

# Get user profile (cần token)
curl http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <token>"
```

### Expected Results

- ✅ Tất cả services trả về HTTP 200
- ✅ Health endpoints hoạt động
- ✅ API endpoints trả về data đúng format

---

## 3. Test Database

### 3.1 PostgreSQL Connection

```bash
# Via Docker
docker exec -it backend-postgres-1 psql -U eshelf -d eshelf

# Hoặc nếu có psql client
psql -h localhost -U eshelf -d eshelf
```

### 3.2 Check Tables

```sql
-- List all tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check specific table
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM books;
```

### 3.3 Prisma

```bash
cd backend/database

# Check schema
cat prisma/schema.prisma

# Generate client
npm run db:generate

# Run migrations (nếu chưa)
npm run db:migrate

# Seed data (optional)
npm run db:seed
```

### Expected Results

- ✅ PostgreSQL connection thành công
- ✅ Tables tồn tại (users, books, genres, etc.)
- ✅ Prisma Client generated
- ✅ Migrations applied

---

## 4. Test ML-AI Service

### 4.1 Health Check

```bash
curl http://localhost:8000/health

# Expected:
# {
#   "status": "ok",
#   "service": "ml-service",
#   "models": {
#     "recommender": true,
#     "similarity": true
#   }
# }
```

### 4.2 Recommendations

```bash
curl -X POST http://localhost:8000/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "n_items": 10
  }'
```

### 4.3 Similar Books

```bash
curl -X POST http://localhost:8000/similar \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": "9780099908401",
    "n_items": 6
  }'
```

### 4.4 Reading Time Estimation

```bash
curl -X POST http://localhost:8000/estimate-time \
  -H "Content-Type: application/json" \
  -d '{
    "pages": 300,
    "genre": "Văn Học"
  }'
```

### 4.5 API Documentation

Mở browser: http://localhost:8000/docs

### Expected Results

- ✅ ML Service health check OK
- ✅ Models loaded (recommender, similarity)
- ✅ Endpoints trả về data
- ✅ FastAPI docs accessible

---

## 5. Test Integration

### 5.1 Frontend → API Gateway → Services

1. Mở browser: http://localhost:5173
2. Thực hiện các actions:
   - Register/Login
   - Search books
   - View book details
   - Add to favorites
3. Check Network tab: Tất cả requests thành công

### 5.2 API Gateway Routing

```bash
# Test routing qua Gateway
curl http://localhost:3000/api/books
curl http://localhost:3000/api/auth/login -X POST ...
curl http://localhost:3000/api/ml/recommendations -X POST ...
```

### 5.3 End-to-End Flow

```bash
# 1. Register user
REGISTER_RESPONSE=$(curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e@test.com",
    "password": "Test123!",
    "username": "e2etest",
    "name": "E2E Test"
  }')

# 2. Login
LOGIN_RESPONSE=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e@test.com",
    "password": "Test123!"
  }')

# Extract token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.accessToken')

# 3. Get books
curl http://localhost:3000/api/books \
  -H "Authorization: Bearer $TOKEN"

# 4. Get recommendations
curl -X POST http://localhost:3000/api/ml/recommendations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "user_id": "e2etest",
    "n_items": 5
  }'
```

### Expected Results

- ✅ Frontend gọi API thành công
- ✅ API Gateway route đúng
- ✅ Services giao tiếp với nhau
- ✅ End-to-end flow hoạt động

---

## Chạy Test Tự động

### Linux/Mac

```bash
# Make script executable
chmod +x scripts/test-all-components.sh

# Run tests
./scripts/test-all-components.sh
```

### Windows (PowerShell)

```powershell
# Run PowerShell script
.\scripts\test-all-components.ps1
```

### Output Example

```
========================================
1. FRONTEND (React + Vite)
========================================
✅ PASS: Frontend is running (HTTP 200)
✅ PASS: Frontend is serving React application
✅ PASS: Frontend build directory exists

========================================
2. BACKEND SERVICES (Microservices)
========================================
✅ PASS: API Gateway is running (HTTP 200)
✅ PASS: Auth Service is running (HTTP 200)
✅ PASS: Book Service is running (HTTP 200)
✅ PASS: User Service is running (HTTP 200)

========================================
3. DATABASE (PostgreSQL + Prisma)
========================================
✅ PASS: PostgreSQL connection via Docker successful
✅ PASS: Database tables exist (12 tables)
✅ PASS: Prisma schema file exists
✅ PASS: Prisma Client generated

========================================
4. ML-AI SERVICE (FastAPI)
========================================
✅ PASS: ML Service is running (HTTP 200)
✅ PASS: ML Service health check shows models status
✅ PASS: ML Service recommendations endpoint working
✅ PASS: ML Service API documentation accessible at /docs

========================================
5. INTEGRATION TESTS
========================================
✅ PASS: API Gateway routing to Book Service working
✅ PASS: API Gateway routing to Auth Service working
✅ PASS: ML Service accessible via API Gateway

========================================
TEST SUMMARY
========================================
Total Tests: 20
Passed: 20
Failed: 0
Warnings: 0

✅ All critical tests passed!
Your system is ready for Ops deployment.
```

---

## Troubleshooting

### Frontend không chạy

```bash
# Check port
netstat -ano | findstr :5173  # Windows
lsof -ti:5173                 # Linux/Mac

# Restart
npm run dev
```

### Backend services không chạy

```bash
# Check Docker
docker ps
docker-compose logs

# Restart
cd backend
docker-compose restart
```

### Database connection failed

```bash
# Check PostgreSQL container
docker ps | grep postgres

# Check connection
docker exec -it backend-postgres-1 psql -U eshelf -d eshelf

# Reset database (careful!)
cd backend/database
npm run db:migrate:reset
npm run db:seed
```

### ML Service không chạy

```bash
# Check Python
python3 --version

# Install dependencies
cd backend/services/ml-service
pip install -r requirements.txt

# Start manually
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### API Gateway không route

- Check environment variables trong `docker-compose.yml`
- Verify service URLs đúng
- Check logs: `docker-compose logs api-gateway`

---

## Checklist trước khi chuyển sang Ops

- [ ] Frontend build thành công
- [ ] Tất cả backend services health check OK
- [ ] Database có schema và data
- [ ] ML Service models loaded
- [ ] Integration tests pass
- [ ] API endpoints hoạt động
- [ ] Authentication flow hoàn chỉnh
- [ ] Error handling đúng

---

## Next Steps

Sau khi tất cả tests pass:

1. **Infrastructure as Code**: Terraform, CloudFormation
2. **CI/CD**: GitHub Actions, Jenkins
3. **Container Orchestration**: Kubernetes
4. **Monitoring**: Prometheus, Grafana
5. **Security**: Scanning, hardening

Xem thêm:
- [DEPLOYMENT.md](DEPLOYMENT.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)
- [README.md](../README.md)

---

**Chúc bạn test thành công! 🚀**

