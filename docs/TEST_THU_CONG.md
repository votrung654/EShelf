# 🧪 Hướng Dẫn Test Thủ Công Bằng Tay

Hướng dẫn từng bước test FE, BE, Database, ML-AI trước khi chuyển sang Ops.

---

## 🚀 Bước 1: Chuẩn bị

### Start services:

**Terminal 1:**
```bash
cd backend
docker-compose up -d
```

**Terminal 2:**
```bash
npm run dev
```

**Kiểm tra:**
```bash
docker ps
# Phải thấy: api-gateway, auth-service, book-service, user-service, ml-service, postgres, redis
```

---

## 📱 Bước 2: Test Frontend (FE)

### 2.1 Mở browser: http://localhost:5173

**Kiểm tra:**
- ✅ Page load được, không lỗi
- ✅ UI hiển thị đúng
- ✅ Mở F12 → Console tab: không có lỗi màu đỏ

### 2.2 Test Navigation

- Click các menu: Home, Books, Login
- ✅ URL thay đổi đúng
- ✅ Page load đúng

### 2.3 Test API Calls

**Mở F12 → Network tab:**
- Reload page (F5)
- Xem các requests
- ✅ Status code = 200 (xanh) hoặc 201
- ❌ Không có 404 (đỏ) hoặc 500 (đỏ)

**Ví dụ requests bạn sẽ thấy:**
```
GET http://localhost:3000/api/books → 200 OK
GET http://localhost:3000/api/genres → 200 OK
```

### 2.4 Test Build

```bash
npm run build
```

**Kiểm tra:**
- ✅ Build thành công, không lỗi
- ✅ Có folder `dist/`

---

## 🔧 Bước 3: Test Backend Services (BE)

### 3.1 API Gateway (Port 3000)

**Mở browser:** http://localhost:3000/health

**Hoặc dùng curl:**
```bash
curl http://localhost:3000/health
```

**Kết quả mong đợi:**
```json
{"status": "ok", "service": "api-gateway"}
```

### 3.2 Auth Service - Register

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"Test123!\",\"username\":\"testuser\",\"name\":\"Test User\"}"
```

**Kết quả:** Phải có `"success": true`

### 3.3 Auth Service - Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@example.com\",\"password\":\"Test123!\"}"
```

**Kết quả:** Phải có `"accessToken"` - **Lưu token này lại!**

### 3.4 Book Service - Get Books

```bash
curl http://localhost:3000/api/books?limit=5
```

**Kết quả:** Phải có mảng `books` với data

### 3.5 User Service - Get Profile (Cần token)

```bash
# Thay <token> bằng token từ login ở trên
curl http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <token>"
```

**Kết quả:** Phải có thông tin user

### 3.6 Health Checks các services

```bash
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Book Service
curl http://localhost:3003/health  # User Service
```

**Tất cả phải trả về:** `{"status": "ok"}`

---

## 🗄️ Bước 4: Test Database

### 4.1 Kết nối PostgreSQL

```bash
docker exec -it backend-postgres-1 psql -U eshelf -d eshelf
```

**Trong psql, chạy:**
```sql
\dt                    -- List tables
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM books;
\q                     -- Exit
```

**Kết quả mong đợi:**
- ✅ Kết nối thành công
- ✅ Có các tables: users, books, genres, reviews, etc.
- ✅ Tables có data (COUNT > 0)

### 4.2 Check Prisma

```bash
cd backend/database
cat prisma/schema.prisma
```

**Kiểm tra:** File tồn tại, có các models

### 4.3 Test Database qua API

```bash
curl http://localhost:3000/api/books?limit=1
```

**Nếu có data trả về → Database OK!**

---

## 🤖 Bước 5: Test ML-AI Service

### 5.1 Health Check

**Mở browser:** http://localhost:8000/health

**Hoặc:**
```bash
curl http://localhost:8000/health
```

**Kết quả mong đợi:**
```json
{
  "status": "ok",
  "models": {
    "recommender": true,
    "similarity": true
  }
}
```

### 5.2 API Documentation

**Mở browser:** http://localhost:8000/docs

**Kiểm tra:**
- ✅ Swagger UI hiển thị
- ✅ Có các endpoints: `/recommendations`, `/similar`, `/estimate-time`

### 5.3 Test Recommendations

**Cách 1: Dùng Swagger UI**
1. Mở http://localhost:8000/docs
2. Click `/recommendations` → "Try it out"
3. Nhập:
   ```json
   {
     "user_id": "test-user",
     "n_items": 10
   }
   ```
4. Click "Execute"

**Cách 2: Dùng curl**
```bash
curl -X POST http://localhost:8000/recommendations \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"test-user\",\"n_items\":10}"
```

**Kết quả:** Phải có `"success": true`

### 5.4 Test Similar Books

```bash
curl -X POST http://localhost:8000/similar \
  -H "Content-Type: application/json" \
  -d "{\"book_id\":\"test-book\",\"n_items\":6}"
```

### 5.5 Test Reading Time

```bash
curl -X POST http://localhost:8000/estimate-time \
  -H "Content-Type: application/json" \
  -d "{\"pages\":300,\"genre\":\"Văn Học\"}"
```

**Kết quả:** Phải có `"minutes"`, `"hours"`, `"formatted"`

### 5.6 Test ML qua API Gateway

```bash
curl -X POST http://localhost:3000/api/ml/recommendations \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"test\",\"n_items\":5}"
```

**Kiểm tra:** Request đi qua Gateway và trả về kết quả

---

## 🔗 Bước 6: Test Integration

### 6.1 End-to-End Flow

**Bước 1: Register**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"e2e@test.com\",\"password\":\"E2ETest123!\",\"username\":\"e2etest\",\"name\":\"E2E Test\"}"
```

**Bước 2: Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"e2e@test.com\",\"password\":\"E2ETest123!\"}"
```

**Lưu `accessToken` từ response**

**Bước 3: Get Profile (dùng token)**
```bash
curl http://localhost:3000/api/users/profile \
  -H "Authorization: Bearer <token>"
```

**Bước 4: Get Books**
```bash
curl http://localhost:3000/api/books?limit=5
```

**Bước 5: Get Recommendations**
```bash
curl -X POST http://localhost:3000/api/ml/recommendations \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"e2etest\",\"n_items\":5}"
```

**Kết quả mong đợi:**
- ✅ Tất cả bước thành công
- ✅ Token hoạt động
- ✅ Services giao tiếp với nhau OK

### 6.2 Test Frontend → Backend

**Mở browser:** http://localhost:5173

**Thực hiện:**
1. **Register/Login** qua UI
   - Mở F12 → Network tab
   - Điền form và submit
   - ✅ Request thành công (status 200)
   - ✅ Response có token

2. **Search Books**
   - Gõ từ khóa và search
   - ✅ Request: `GET /api/books/search?q=...`
   - ✅ Response có books

3. **View Book Detail**
   - Click vào một book
   - ✅ Request: `GET /api/books/<id>`
   - ✅ Page hiển thị đúng

**Kết quả mong đợi:**
- ✅ Tất cả API calls thành công
- ✅ UI update đúng
- ✅ Không có lỗi console

---

## ✅ Checklist Cuối Cùng

Sau khi test xong, đánh dấu:

### Frontend ✅
- [ ] Chạy tại http://localhost:5173
- [ ] UI render đúng, không lỗi
- [ ] Navigation hoạt động
- [ ] API calls thành công (check Network tab)
- [ ] Build production OK

### Backend ✅
- [ ] API Gateway (3000) - health OK
- [ ] Auth Service (3001) - register/login OK
- [ ] Book Service (3002) - get/search OK
- [ ] User Service (3003) - profile OK
- [ ] Tất cả health checks = 200

### Database ✅
- [ ] PostgreSQL connection OK
- [ ] Tables tồn tại
- [ ] Có thể query data
- [ ] Prisma schema OK

### ML-AI ✅
- [ ] ML Service (8000) - health OK
- [ ] Models loaded
- [ ] Recommendations OK
- [ ] Similar books OK
- [ ] API docs tại /docs

### Integration ✅
- [ ] Frontend → Backend OK
- [ ] Authentication flow OK
- [ ] End-to-end flow OK
- [ ] Services giao tiếp OK

---

## 🎯 Kết Luận

**Nếu tất cả checklist ✅ → Sẵn sàng cho Ops!**

Bạn có thể tiếp tục với:
- Terraform/CloudFormation
- CI/CD Pipeline
- Kubernetes
- Monitoring

---

## 🆘 Troubleshooting

### Service không chạy
```bash
docker ps                    # Check containers
docker logs <container>      # Check logs
docker-compose restart       # Restart
```

### Database lỗi
```bash
docker exec -it backend-postgres-1 psql -U eshelf -d eshelf
```

### API lỗi 500
- Check logs: `docker logs <service-name>`
- Check database connection
- Check environment variables

---

**Xem chi tiết:** [MANUAL_TESTING_GUIDE.md](MANUAL_TESTING_GUIDE.md)

**Chúc bạn test thành công! 🚀**

