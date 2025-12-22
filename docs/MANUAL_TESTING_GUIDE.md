# 🧪 Hướng dẫn Test Thủ Công (Manual Testing)

Hướng dẫn chi tiết cách test từng component bằng tay trước khi chuyển sang phần Ops.

---

## 📋 Mục lục

1. [Chuẩn bị](#chuẩn-bị)
2. [Test Frontend (FE)](#1-test-frontend-fe)
3. [Test Backend Services (BE)](#2-test-backend-services-be)
4. [Test Database](#3-test-database)
5. [Test ML-AI Service](#4-test-ml-ai-service)
6. [Test Integration](#5-test-integration)
7. [Checklist cuối cùng](#checklist-cuối-cùng)

---

## Chuẩn bị

### Bước 1: Start tất cả services

**Terminal 1 - Backend (Docker Compose):**
```bash
cd backend
docker-compose up -d
```

**Terminal 2 - Frontend:**
```bash
npm run dev
```

### Bước 2: Kiểm tra services đang chạy

```bash
# Check Docker containers
docker ps

# Bạn sẽ thấy các containers:
# - backend-api-gateway-1
# - backend-auth-service-1
# - backend-book-service-1
# - backend-user-service-1
# - backend-ml-service-1
# - backend-postgres-1
# - backend-redis-1
```

---

## 1. Test Frontend (FE)

### Test 1.1: Kiểm tra Frontend có chạy không

**Mở browser:** http://localhost:5173

**Kiểm tra:**
- ✅ Page load được, không có lỗi console
- ✅ UI hiển thị đúng (header, navigation, etc.)
- ✅ Không có lỗi 404 hoặc blank page

**Nếu lỗi:**
- Check terminal xem có error không
- Check port 5173 có bị chiếm không: `netstat -ano | findstr :5173` (Windows)

### Test 1.2: Test Navigation

**Thực hiện:**
1. Click vào các menu items (Home, Books, Login, etc.)
2. URL có thay đổi đúng không
3. Page có load đúng không

**Kết quả mong đợi:**
- ✅ Navigation hoạt động mượt
- ✅ URL thay đổi đúng
- ✅ Không có lỗi routing

### Test 1.3: Test API Calls

**Mở Developer Tools (F12) → Network tab**

**Thực hiện:**
1. Reload page (F5)
2. Xem các API calls trong Network tab
3. Check status code của mỗi request

**Kết quả mong đợi:**
- ✅ API calls có status 200 (OK) hoặc 201 (Created)
- ✅ Không có 404 (Not Found) hoặc 500 (Server Error)
- ✅ Response data có format đúng (JSON)

**Ví dụ requests bạn sẽ thấy:**
```
GET http://localhost:3000/api/books?limit=20  → 200 OK
GET http://localhost:3000/api/genres          → 200 OK
```

### Test 1.4: Test Build Production

**Terminal:**
```bash
npm run build
```

**Kiểm tra:**
- ✅ Build thành công không có lỗi
- ✅ Folder `dist/` được tạo
- ✅ Có các file: `index.html`, `assets/`, etc.

**Nếu lỗi:**
- Check lỗi trong terminal
- Fix lỗi trước khi tiếp tục

---

## 2. Test Backend Services (BE)

### Test 2.1: API Gateway (Port 3000)

**Mở browser hoặc dùng curl:**

```bash
# Test health endpoint
curl http://localhost:3000/health
```

**Hoặc mở browser:** http://localhost:3000/health

**Kết quả mong đợi:**
```json
{
  "status": "ok",
  "service": "api-gateway",
  "timestamp": "..."
}
```

**Nếu lỗi:**
- Check Docker container: `docker ps | grep api-gateway`
- Check logs: `docker logs backend-api-gateway-1`

### Test 2.2: Auth Service (Port 3001)

**Test 1: Health Check**
```bash
curl http://localhost:3001/health
```

**Test 2: Register User**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "username": "testuser",
    "name": "Test User"
  }'
```

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "email": "test@example.com",
      "username": "testuser"
    }
  }
}
```

**Test 3: Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": {
    "user": {...},
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "..."
  }
}
```

**Lưu token này lại để test các API cần authentication!**

**Nếu lỗi:**
- Check container: `docker ps | grep auth-service`
- Check logs: `docker logs backend-auth-service-1`

### Test 2.3: Book Service (Port 3002)

**Test 1: Health Check**
```bash
curl http://localhost:3002/health
```

**Test 2: Get All Books**
```bash
curl http://localhost:3000/api/books?limit=5
```

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": {
    "books": [...],
    "pagination": {
      "page": 1,
      "limit": 5,
      "total": 100
    }
  }
}
```

**Test 3: Search Books**
```bash
curl "http://localhost:3000/api/books/search?q=harry"
```

**Test 4: Get Book by ID**
```bash
# Lấy một book_id từ kết quả trên
curl http://localhost:3000/api/books/<book_id>
```

**Nếu lỗi:**
- Check container: `docker ps | grep book-service`
- Check logs: `docker logs backend-book-service-1`

### Test 2.4: User Service (Port 3003)

**Test 1: Health Check**
```bash
curl http://localhost:3003/health
```

**Test 2: Get User Profile (Cần token)**
```bash
# Thay <access_token> bằng token từ login ở trên
curl http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <access_token>"
```

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "...",
      "email": "test@example.com",
      "username": "testuser"
    }
  }
}
```

**Nếu lỗi 401 (Unauthorized):**
- Token đã hết hạn hoặc không hợp lệ
- Login lại để lấy token mới

**Nếu lỗi:**
- Check container: `docker ps | grep user-service`
- Check logs: `docker logs backend-user-service-1`

---

## 3. Test Database

### Test 3.1: PostgreSQL Connection

**Cách 1: Dùng Docker exec**
```bash
docker exec -it backend-postgres-1 psql -U eshelf -d eshelf
```

**Nếu vào được psql prompt:**
```sql
-- List all tables
\dt

-- Check users table
SELECT COUNT(*) FROM users;

-- Check books table
SELECT COUNT(*) FROM books;

-- Exit
\q
```

**Kết quả mong đợi:**
- ✅ Kết nối thành công
- ✅ Có các tables: users, books, genres, reviews, etc.
- ✅ Tables có data (COUNT > 0)

**Cách 2: Dùng psql client (nếu có cài)**
```bash
psql -h localhost -U eshelf -d eshelf
# Password: eshelf123 (hoặc password bạn đã set)
```

### Test 3.2: Check Prisma Schema

**Terminal:**
```bash
cd backend/database
cat prisma/schema.prisma
```

**Kiểm tra:**
- ✅ File tồn tại
- ✅ Có các models: User, Book, Genre, Review, etc.

### Test 3.3: Check Prisma Client

**Terminal:**
```bash
cd backend/database
ls -la node_modules/.prisma/client
```

**Hoặc:**
```bash
cd backend/database
npm run db:generate
```

**Kết quả mong đợi:**
- ✅ Prisma Client đã được generate
- ✅ Không có lỗi

### Test 3.4: Test Database Queries qua API

**Test qua Book Service:**
```bash
# Get books - sẽ query database
curl http://localhost:3000/api/books?limit=1
```

**Nếu có data trả về → Database connection OK!**

### Test 3.5: Redis (Optional - cho caching)

**Test connection:**
```bash
docker exec -it backend-redis-1 redis-cli ping
```

**Kết quả mong đợi:**
```
PONG
```

**Nếu không có Redis cũng OK, đây là optional component.**

---

## 4. Test ML-AI Service

### Test 4.1: Health Check

**Browser hoặc curl:**
```bash
curl http://localhost:8000/health
```

**Hoặc mở browser:** http://localhost:8000/health

**Kết quả mong đợi:**
```json
{
  "status": "ok",
  "service": "ml-service",
  "models": {
    "recommender": true,
    "similarity": true
  }
}
```

**Nếu models: false → Models chưa được load, nhưng service vẫn chạy OK.**

### Test 4.2: API Documentation

**Mở browser:** http://localhost:8000/docs

**Kiểm tra:**
- ✅ FastAPI Swagger UI hiển thị
- ✅ Có các endpoints: `/health`, `/recommendations`, `/similar`, `/estimate-time`
- ✅ Có thể test trực tiếp trên UI

### Test 4.3: Recommendations Endpoint

**Cách 1: Dùng curl**
```bash
curl -X POST http://localhost:8000/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "n_items": 10
  }'
```

**Cách 2: Dùng Swagger UI**
1. Mở http://localhost:8000/docs
2. Click vào `/recommendations` endpoint
3. Click "Try it out"
4. Nhập:
   ```json
   {
     "user_id": "test-user-123",
     "n_items": 10
   }
   ```
5. Click "Execute"

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": [
    {
      "book_id": "...",
      "title": "...",
      "score": 0.85
    },
    ...
  ]
}
```

**Nếu trả về empty array → OK, chỉ là chưa có data để recommend.**

### Test 4.4: Similar Books Endpoint

```bash
curl -X POST http://localhost:8000/similar \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": "9780099908401",
    "n_items": 6
  }'
```

**Hoặc test trên Swagger UI:** http://localhost:8000/docs

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": [
    {
      "book_id": "...",
      "title": "...",
      "similarity": 0.92
    },
    ...
  ]
}
```

### Test 4.5: Reading Time Estimation

```bash
curl -X POST http://localhost:8000/estimate-time \
  -H "Content-Type: application/json" \
  -d '{
    "pages": 300,
    "genre": "Văn Học"
  }'
```

**Kết quả mong đợi:**
```json
{
  "success": true,
  "data": {
    "minutes": 300,
    "hours": 5.0,
    "formatted": "5h 0m"
  }
}
```

### Test 4.6: ML Service qua API Gateway

```bash
curl -X POST http://localhost:3000/api/ml/recommendations \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "n_items": 5
  }'
```

**Kiểm tra:**
- ✅ Request đi qua API Gateway
- ✅ Gateway route đúng đến ML Service
- ✅ Response trả về đúng format

---

## 5. Test Integration

### Test 5.1: End-to-End Flow - User Registration & Login

**Bước 1: Register**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e@test.com",
    "password": "E2ETest123!",
    "username": "e2etest",
    "name": "E2E Test User"
  }'
```

**Lưu lại response, lấy `accessToken`**

**Bước 2: Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "e2e@test.com",
    "password": "E2ETest123!"
  }'
```

**Bước 3: Get Profile (dùng token)**
```bash
# Thay <token> bằng accessToken từ login
curl http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <token>"
```

**Kết quả mong đợi:**
- ✅ Register thành công
- ✅ Login thành công, có token
- ✅ Get profile thành công với token

### Test 5.2: Frontend → Backend Integration

**Mở browser:** http://localhost:5173

**Thực hiện:**
1. **Register/Login** qua UI
   - Điền form
   - Submit
   - Check Network tab xem request có thành công không
   - Check response có token không

2. **Search Books**
   - Gõ từ khóa vào search box
   - Check Network tab: `GET /api/books/search?q=...`
   - Check response có books không

3. **View Book Detail**
   - Click vào một book
   - Check Network tab: `GET /api/books/<id>`
   - Check page hiển thị đúng thông tin

4. **Get Recommendations**
   - Nếu có button "Recommendations"
   - Click và check Network tab
   - Check response có recommendations không

**Kết quả mong đợi:**
- ✅ Tất cả API calls thành công (status 200)
- ✅ UI update đúng sau mỗi action
- ✅ Không có lỗi console

### Test 5.3: Services Communication

**Test API Gateway routing:**

```bash
# Test routing đến Book Service
curl http://localhost:3000/api/books

# Test routing đến Auth Service
curl -X POST http://localhost:3000/api/auth/login ...

# Test routing đến User Service
curl http://localhost:3000/api/users/profile -H "Authorization: Bearer ..."

# Test routing đến ML Service
curl -X POST http://localhost:3000/api/ml/recommendations ...
```

**Kiểm tra:**
- ✅ Tất cả requests đi qua API Gateway (port 3000)
- ✅ Gateway route đúng đến từng service
- ✅ Response trả về đúng

---

## Checklist cuối cùng

Sau khi test xong, đánh dấu các mục sau:

### Frontend ✅
- [ ] Frontend chạy tại http://localhost:5173
- [ ] UI render đúng, không lỗi
- [ ] Navigation hoạt động
- [ ] API calls thành công (check Network tab)
- [ ] Build production thành công

### Backend Services ✅
- [ ] API Gateway (3000) - health check OK
- [ ] Auth Service (3001) - register/login OK
- [ ] Book Service (3002) - get/search books OK
- [ ] User Service (3003) - get profile OK (với token)
- [ ] Tất cả services trả về HTTP 200

### Database ✅
- [ ] PostgreSQL connection OK
- [ ] Tables tồn tại (users, books, genres, etc.)
- [ ] Có thể query data
- [ ] Prisma schema OK
- [ ] Prisma Client generated

### ML-AI Service ✅
- [ ] ML Service (8000) - health check OK
- [ ] Models loaded (recommender, similarity)
- [ ] Recommendations endpoint hoạt động
- [ ] Similar books endpoint hoạt động
- [ ] Reading time estimation hoạt động
- [ ] API docs accessible tại /docs

### Integration ✅
- [ ] Frontend → API Gateway → Services OK
- [ ] Authentication flow hoàn chỉnh
- [ ] End-to-end flow hoạt động
- [ ] Services giao tiếp với nhau OK

---

## Kết luận

Nếu tất cả checklist trên đều ✅ → **Hệ thống sẵn sàng cho phần Ops!**

Bạn có thể tiếp tục với:
- Infrastructure as Code (Terraform, CloudFormation)
- CI/CD Pipeline (GitHub Actions, Jenkins)
- Kubernetes Deployment
- Monitoring & Logging

---

## Troubleshooting

### Service không chạy
```bash
# Check containers
docker ps

# Check logs
docker logs <container-name>

# Restart
docker-compose restart <service-name>
```

### Database connection failed
```bash
# Check PostgreSQL
docker ps | grep postgres

# Check connection
docker exec -it backend-postgres-1 psql -U eshelf -d eshelf
```

### API trả về 500
- Check logs của service đó
- Check database connection
- Check environment variables

### Frontend không load
- Check terminal có lỗi không
- Check port 5173 có bị chiếm không
- Clear cache và reload

---

**Chúc bạn test thành công! 🚀**

