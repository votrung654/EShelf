# 🧪 Hướng dẫn Test Components trước khi chuyển sang Ops

## Tổng quan

Bạn đã có script test tự động để kiểm tra tất cả components trước khi chuyển sang phần Ops (DevOps/Infrastructure).

## Cách sử dụng

### 1. Chạy Test Tự động

**Linux/Mac:**
```bash
npm run test:all
```

**Windows (PowerShell):**
```powershell
npm run test:all:win
```

**Hoặc chạy trực tiếp:**
```bash
# Linux/Mac
bash scripts/test-all-components.sh

# Windows
powershell -ExecutionPolicy Bypass -File scripts/test-all-components.ps1
```

### 2. Script sẽ test:

✅ **Frontend (FE)**
- React app có chạy không
- Build có thành công không
- UI có render đúng không

✅ **Backend Services (BE)**
- API Gateway (port 3000)
- Auth Service (port 3001)
- Book Service (port 3002)
- User Service (port 3003)
- Health checks
- API endpoints

✅ **Database**
- PostgreSQL connection
- Tables tồn tại
- Prisma schema & client
- Redis (optional)

✅ **ML-AI Service**
- FastAPI service (port 8000)
- Models loaded (recommender, similarity)
- API endpoints hoạt động
- Documentation accessible

✅ **Integration**
- Frontend → API Gateway → Services
- Services giao tiếp với nhau
- End-to-end flow

## Kết quả mong đợi

Sau khi chạy script, bạn sẽ thấy:

```
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

## Trước khi chạy test

Đảm bảo tất cả services đang chạy:

```bash
# Start backend services
cd backend
docker-compose up -d

# Start frontend (terminal khác)
npm run dev
```

## Nếu có lỗi

Script sẽ chỉ ra:
- ❌ **FAIL**: Lỗi nghiêm trọng cần fix
- ⚠️ **WARN**: Cảnh báo, có thể bỏ qua nếu không quan trọng

Xem chi tiết troubleshooting trong: [docs/TESTING_GUIDE.md](TESTING_GUIDE.md)

## Checklist trước khi chuyển sang Ops

- [ ] Frontend build thành công
- [ ] Tất cả backend services health check OK
- [ ] Database có schema và data
- [ ] ML Service models loaded
- [ ] Integration tests pass
- [ ] API endpoints hoạt động
- [ ] Authentication flow hoàn chỉnh

## Tài liệu tham khảo

- [TESTING_GUIDE.md](TESTING_GUIDE.md) - Hướng dẫn chi tiết
- [README.md](../README.md) - Tổng quan dự án
- [QUICKSTART.md](../QUICKSTART.md) - Hướng dẫn chạy nhanh

---

**Chúc bạn test thành công! 🚀**

