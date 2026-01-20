# Test Fresh Clone - Hướng Dẫn

Script này test xem một người mới clone repo về có thể setup thành công không, đặc biệt là:
- Docker Compose có tự động setup database không
- Migration service có chạy đúng không
- Có cần file .env không (test với default values)

## Cách Chạy

### Windows (PowerShell)
```powershell
.\scripts\test-fresh-clone.ps1
```

Với options:
```powershell
# Clean up containers trước khi test
.\scripts\test-fresh-clone.ps1 -Clean

# Skip build (nhanh hơn nếu images đã có)
.\scripts\test-fresh-clone.ps1 -SkipBuild
```

### Linux/Mac (Bash)
```bash
chmod +x scripts/test-fresh-clone.sh
./scripts/test-fresh-clone.sh
```

## Script Sẽ Làm Gì

1. **Kiểm tra prerequisites**: Docker, Docker Compose
2. **Kiểm tra cấu hình**: docker-compose.yml, migration service
3. **Backup .env hiện tại** (nếu có)
4. **Xóa .env** để test với default values
5. **Validate docker-compose config**
6. **Chạy docker-compose up** (nếu bạn đồng ý)
7. **Kiểm tra**:
   - PostgreSQL có healthy không
   - Migration service có chạy thành công không
   - Database tables có được tạo không
   - Các services có start sau migration không
8. **Restore .env** (nếu đã backup)

## Kết Quả Mong Đợi

Nếu test pass, nghĩa là:
- Một người mới clone repo về **KHÔNG CẦN** tạo file .env
- Docker Compose sẽ tự động:
  - Start PostgreSQL với default values
  - Chạy migrations tự động
  - Tạo database tables
  - Start các services sau khi migration xong

## Troubleshooting

Nếu test fail:

1. **Kiểm tra logs**:
   ```bash
   cd backend
   docker-compose logs db-migration
   docker-compose logs postgres
   ```

2. **Kiểm tra DATABASE_URL**:
   ```bash
   cd backend
   docker-compose config | grep DATABASE_URL
   ```
   Phải có dạng: `postgresql://eshelf:eshelf123@postgres:5432/eshelf?schema=public`

3. **Clean và test lại**:
   ```bash
   cd backend
   docker-compose down -v
   cd ..
   .\scripts\test-fresh-clone.ps1 -Clean
   ```

## Lưu Ý

- Script sẽ **backup và restore** file `.env` của bạn nếu có
- Script sẽ **hỏi xác nhận** trước khi chạy docker-compose (có thể mất vài phút)
- Bạn có thể chọn **skip runtime test** nếu chỉ muốn validate config

