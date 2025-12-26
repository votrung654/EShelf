# Hướng Dẫn Clone và Chạy Project

## Người Mới Clone Repo - Chạy Ngay Được

### Quy Trình Đơn Giản

```bash
# 1. Clone repository (bất kỳ branch nào)
git clone https://github.com/votrung654/EShelf.git
cd EShelf

# 2. Chọn branch (nếu muốn dùng feature branch)
git checkout feature/test-pr-pipeline
# Hoặc dùng main branch:
# git checkout main

# 3. Start Backend (tự động setup database)
cd backend
docker-compose up -d

# 4. Đợi database setup (khoảng 30 giây)
# Kiểm tra logs:
docker-compose logs db-migration

# 5. Start Frontend (terminal mới)
cd ..
npm install
npm run dev
```

### Kết Quả

Sau khi chạy `docker-compose up -d`:
- PostgreSQL database tự động tạo
- Database schema tự động tạo (migrations)
- 40 sách tự động seed từ JSON
- Users tự động tạo (admin, demo)
- Tất cả services tự động start
- Không cần chạy lệnh thủ công nào

### Truy Cập

- **Frontend:** http://localhost:5173
- **API Gateway:** http://localhost:3000
- **Admin Login:** admin@eshelf.com / Admin123!
- **User Login:** user@eshelf.com / User123!

## Về Git Branches

### Có Thể Clone Bất Kỳ Branch Nào

**Câu trả lời: CÓ, bạn có thể clone và dùng feature branch!**

```bash
# Clone và checkout feature branch ngay
git clone -b feature/test-pr-pipeline https://github.com/votrung654/EShelf.git
cd EShelf
cd backend
docker-compose up -d
```

Hoặc clone rồi checkout sau:

```bash
git clone https://github.com/votrung654/EShelf.git
cd EShelf
git checkout feature/test-pr-pipeline
cd backend
docker-compose up -d
```

### Cập Nhật Từ Feature Branch

**Câu trả lời: CÓ, bạn có thể pull và cập nhật từ feature branch!**

```bash
# Nếu đã clone feature branch
cd EShelf
git pull origin feature/test-pr-pipeline

# Rebuild nếu có thay đổi
cd backend
docker-compose build
docker-compose up -d
```

### So Sánh Main vs Feature Branch

| Branch | Nội Dung | Khi Nào Dùng |
|--------|----------|--------------|
| `main` | Code ổn định, đã test | Production, demo ổn định |
| `feature/test-pr-pipeline` | Code mới nhất, có database auto-setup | Development, test tính năng mới |

**Lưu ý:**
- Feature branch có **đầy đủ code** như main branch
- Feature branch có **thêm tính năng mới** (database auto-setup)
- Có thể dùng feature branch để test tính năng mới trước khi merge vào main

## Workflow Khuyến Nghị

### Cho Người Mới Clone

1. **Clone main branch** (nếu muốn code ổn định):
   ```bash
   git clone https://github.com/votrung654/EShelf.git
   cd EShelf/backend
   docker-compose up -d
   ```

2. **Clone feature branch** (nếu muốn test tính năng mới):
   ```bash
   git clone -b feature/test-pr-pipeline https://github.com/votrung654/EShelf.git
   cd EShelf/backend
   docker-compose up -d
   ```

### Cho Người Đã Clone

1. **Cập nhật từ main**:
   ```bash
   git checkout main
   git pull origin main
   cd backend
   docker-compose build
   docker-compose up -d
   ```

2. **Cập nhật từ feature branch**:
   ```bash
   git checkout feature/test-pr-pipeline
   git pull origin feature/test-pr-pipeline
   cd backend
   docker-compose build
   docker-compose up -d
   ```

## Lưu Ý Quan Trọng

### Khi Pull Code Mới

1. **Nếu có thay đổi database schema:**
   ```bash
   cd backend
   docker-compose build  # Rebuild để generate Prisma client mới
   docker-compose up -d
   ```

2. **Nếu chỉ thay đổi code (không đổi schema):**
   ```bash
   cd backend
   git pull
   docker-compose restart  # Chỉ restart, không cần rebuild
   ```

3. **Nếu muốn reset database (xóa dữ liệu):**
   ```bash
   cd backend
   docker-compose down -v  # Xóa volumes
   docker-compose up -d     # Tạo lại từ đầu
   ```

## Tóm Tắt

1. **Clone về chạy được ngay?** → **CÓ!**
   - Chỉ cần: `git clone` → `cd backend` → `docker-compose up -d`
   - Database tự động setup, không cần làm gì thêm

2. **Dùng feature branch được không?** → **CÓ!**
   - Feature branch có đầy đủ code
   - Có thể clone và dùng như main branch
   - Có thể pull và cập nhật từ feature branch

3. **Cần main branch không?** → **KHÔNG BẮT BUỘC**
   - Có thể dùng feature branch để test tính năng mới
   - Main branch chỉ là code ổn định hơn

## Kết Luận

**Người mới clone repo:**
- Clone bất kỳ branch nào
- Chạy `docker-compose up -d` là xong
- Database tự động setup đầy đủ
- Không cần cấu hình thủ công

**Người đã clone:**
- Có thể pull từ feature branch
- Không cần chuyển sang main branch
- Chỉ cần rebuild nếu schema thay đổi

