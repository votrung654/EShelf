# Trả Lời Câu Hỏi Bảo Mật

## 1. Repo Private có đủ an toàn không?

### CẢNH BÁO: Repo Private KHÔNG đủ an toàn nếu có thông tin nhạy cảm trong Git History!

**Lý do:**
1. **Git History vĩnh viễn**: Ngay cả khi bạn xóa file trong commit mới nhất, thông tin vẫn tồn tại trong lịch sử commit
2. **Ai có quyền truy cập repo đều có thể xem history**: 
   - Collaborators hiện tại
   - Collaborators trong tương lai
   - Nếu repo được chuyển từ private sang public
   - Nếu GitHub bị hack (rất hiếm nhưng có thể xảy ra)
3. **GitHub có thể cache**: GitHub có thể cache các commit trong một thời gian

### Giải pháp tạm thời (cho đến khi xóa history):

1. **Đặt repo là private** ✓ (Bạn đã làm)
2. **Rotate (đổi) ngay lập tức** tất cả credentials đã bị lộ:
   - Đổi password AWS Academy
   - Revoke và tạo lại API keys (nếu có)
   - Đổi database passwords (nếu có)
3. **Xóa khỏi Git history** càng sớm càng tốt (xem `SECURITY_GIT_HISTORY.md`)
4. **Không thêm collaborators mới** cho đến khi xóa xong history

### Checklist an toàn:

- [x] Repo đã được đặt là private
- [ ] Đã rotate tất cả credentials bị lộ
- [ ] Đã xóa thông tin nhạy cảm khỏi Git history
- [ ] Đã force push sau khi xóa
- [ ] Đã thông báo collaborators (nếu có)

## 2. Project có file biến môi trường đầy đủ chưa?

### Đã bổ sung đầy đủ!

**Các file đã tạo:**
1. **`.env.example`** (root) - Template cho toàn bộ project
2. **`backend/.env.example`** - Template cho backend services
3. **`ENV_SETUP_GUIDE.md`** - Hướng dẫn chi tiết setup
4. **`scripts/test-env-setup.ps1`** - Script kiểm tra setup

**Các biến môi trường đã được cấu hình:**
- ✅ Frontend: `VITE_API_URL`
- ✅ Backend Services: Ports, URLs, JWT secrets
- ✅ Database: `DATABASE_URL`, `POSTGRES_*`
- ✅ CORS: `ALLOWED_ORIGINS`
- ✅ Redis: `REDIS_*`
- ✅ AWS: `AWS_*` (nếu cần)
- ✅ Rate Limiting: `RATE_LIMIT_*`

**Docker Compose đã được cập nhật:**
- ✅ Tất cả services sử dụng biến môi trường
- ✅ Không còn hardcode credentials (trừ giá trị mặc định fallback)
- ✅ Hỗ trợ đọc từ file `.env`

## 3. Kiểm tra và Test

### Chạy script kiểm tra:

```powershell
.\scripts\test-env-setup.ps1
```

Script này sẽ kiểm tra:
- File `.env.example` có tồn tại không
- File `.env` có được ignore không
- Docker Compose có sử dụng biến môi trường không
- Code có hardcode credentials không
- Code có sử dụng `process.env` không

### Test chức năng:

1. **Tạo file .env:**
   ```powershell
   Copy-Item .env.example .env
   Copy-Item backend\.env.example backend\.env
   ```

2. **Cập nhật giá trị trong `.env`:**
   - Đổi `JWT_SECRET` và `JWT_REFRESH_SECRET`
   - Đổi `POSTGRES_PASSWORD`
   - Cập nhật `DATABASE_URL` nếu cần

3. **Start services:**
   ```powershell
   cd backend
   docker-compose up -d
   ```

4. **Test kết nối:**
   ```powershell
   # Test API Gateway
   curl http://localhost:3000/health
   
   # Test Auth Service
   curl http://localhost:3001/health
   
   # Test login (sử dụng credentials từ seed)
   curl -X POST http://localhost:3000/api/auth/login `
     -H "Content-Type: application/json" `
     -d '{"email":"admin@eshelf.com","password":"Admin123!"}'
   ```

## 4. Các thông tin nhạy cảm còn lại

### ✅ Đã xử lý:
- AWS credentials trong `DEMO_GUIDE.md` - Đã có script để xóa (`remove-sensitive-data.ps1`)
- Database password trong `docker-compose.yml` - Đã chuyển sang biến môi trường
- JWT secrets - Đã chuyển sang biến môi trường

### Còn lại (nhưng chấp nhận được):
- **Seed files có hardcoded passwords** (`Admin123!`, `User123!`):
  - Đây là passwords mặc định cho demo/testing
  - Chỉ được sử dụng khi chạy seed
  - Không ảnh hưởng đến production nếu không chạy seed
  - **Khuyến nghị**: Nên chuyển sang biến môi trường nếu muốn an toàn hơn

### Lưu ý về Seed Files:

Các file seed (`backend/*/prisma/seed.js`) có hardcoded passwords:
- `Admin123!` - Password mặc định cho admin user
- `User123!` - Password mặc định cho demo user

**Đây là OK cho development**, nhưng nếu muốn an toàn hơn, có thể:
1. Sử dụng biến môi trường: `ADMIN_PASSWORD`, `USER_PASSWORD`
2. Hoặc generate random passwords và in ra console

## 5. Kết luận

### Đã hoàn thành:
1. Tạo file `.env.example` đầy đủ
2. Cập nhật `docker-compose.yml` sử dụng biến môi trường
3. Tạo script kiểm tra setup
4. Tạo tài liệu hướng dẫn

### Cần làm thêm:
1. **Xóa thông tin nhạy cảm khỏi Git history** (xem `SECURITY_GIT_HISTORY.md`)
2. **Rotate credentials** đã bị lộ
3. **Test lại toàn bộ chức năng** sau khi setup biến môi trường

### Next Steps:

1. **Ngay lập tức:**
   - Rotate AWS Academy credentials
   - Tạo file `.env` từ `.env.example`
   - Đổi tất cả giá trị mặc định

2. **Sớm nhất có thể:**
   - Xóa thông tin nhạy cảm khỏi Git history
   - Force push (thông báo collaborators trước)

3. **Trước khi deploy production:**
   - Chạy `.\scripts\test-env-setup.ps1`
   - Test toàn bộ chức năng
   - Sử dụng secrets management service (AWS Secrets Manager, etc.)

