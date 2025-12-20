# 📋 Kế Hoạch Prompt Chi Tiết cho Dự Án eShelf

Dưới đây là danh sách các prompt được tổ chức theo từng giai đoạn, mỗi prompt đủ cụ thể để hoàn thành trong giới hạn token.

> **Hướng dẫn đọc:**
> - ✅ **Kết quả:** Bạn sẽ có gì sau khi hoàn thành prompt
> - 🧪 **Test:** Cách kiểm tra code hoạt động đúng
> - ➡️ **Tiếp theo:** Điều kiện để chuyển sang prompt kế tiếp

---

## 🎯 PHASE 1: FRONTEND ENHANCEMENT

### Prompt 1.1 - User Profile Page
```
Dựa trên cấu trúc hiện tại của eShelf (React + Vite + TailwindCSS), hãy tạo:
1. Component UserProfile.jsx trong src/pages/
2. Component ProfileSidebar.jsx, ProfileStats.jsx trong src/components/user/
3. Tích hợp routing trong main.jsx
4. Bao gồm: Avatar, thông tin cá nhân, thống kê đọc sách, danh sách yêu thích
5. Sử dụng pattern giống các page hiện có (BookDetail.jsx, Feedback.jsx)
```

**✅ Kết quả đạt được:**
- Trang Profile tại route `/profile`
- Hiển thị avatar, tên, email, bio của user
- Sidebar menu: Thông tin, Yêu thích, Lịch sử, Cài đặt
- Stats cards: Số sách đã đọc, Thời gian đọc, Sách yêu thích
- Mock data user để demo

**🧪 Cách test:**
```bash
npm run dev
# Truy cập http://localhost:5173/profile
# ✓ Trang hiển thị không lỗi console (F12)
# ✓ Avatar và thông tin user hiển thị đúng
# ✓ Click các tab sidebar → nội dung thay đổi
# ✓ Responsive: F12 → toggle device toolbar
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Trang /profile render không lỗi
- [ ] Navigate từ Header đến Profile OK
- [ ] UI hiển thị đầy đủ các sections

---

### Prompt 1.2 - Collections & Favorites
```
Tạo tính năng Collections và Favorites cho eShelf:
1. Component Collections.jsx (page) - hiển thị các bộ sưu tập sách
2. Component CollectionCard.jsx, CreateCollectionModal.jsx
3. Tích hợp với data structure từ book-details.json
4. UI: Grid layout, add/remove books, rename collection
5. Lưu state bằng localStorage (tạm thời trước khi có backend)
```

**✅ Kết quả đạt được:**
- Trang `/collections` hiển thị bộ sưu tập
- Modal tạo collection mới (tên, mô tả)
- Grid cards cho mỗi collection + số lượng sách
- Nút "Add to Collection" trong BookDetail
- Favorites là 1 collection mặc định
- Data lưu localStorage, persist sau refresh

**🧪 Cách test:**
```bash
npm run dev
# 1. Vào /collections → thấy "Favorites" mặc định
# 2. Click "Create Collection" → nhập tên → OK
# 3. Vào /book/1 → Click "Add to Collection" → chọn
# 4. Quay lại /collections → số sách tăng
# 5. Refresh trang → data vẫn còn
# 6. F12 → Application → Local Storage → thấy data
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] CRUD collection hoạt động
- [ ] Add/remove book from collection OK
- [ ] Data persist sau refresh

---

### Prompt 1.3 - Reading Progress Tracker
```
Tạo tính năng theo dõi tiến độ đọc sách:
1. Component ReadingProgress.jsx trong BookDetail.jsx
2. Component ReadingHistory.jsx (page) - lịch sử đọc
3. Progress bar, bookmark position, last read timestamp
4. Tích hợp với Reading.jsx page hiện có
5. Lưu progress vào localStorage với structure phù hợp
```

**✅ Kết quả đạt được:**
- Progress bar trong BookDetail (0-100%)
- Tự động save trang đang đọc khi rời Reading page
- Nút "Continue Reading" với trang cuối đọc
- Trang `/reading-history` với danh sách đang đọc
- Timestamp "Đọc lần cuối: 2 giờ trước"
- Filter: Đang đọc, Đã xong, Tất cả

**🧪 Cách test:**
```bash
npm run dev
# 1. Vào /book/1 → Click "Read" → đọc vài trang
# 2. Quay lại /book/1 → thấy progress bar cập nhật
# 3. Nút "Continue from page X" xuất hiện
# 4. Vào /reading-history → thấy sách vừa đọc
# 5. F12 → Application → localStorage key: "eshelf_reading_progress"
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Progress tự động lưu
- [ ] Reading history hiển thị chính xác
- [ ] Continue reading về đúng trang

---

### Prompt 1.4 - Dark Mode Implementation
```
Implement Dark Mode cho eShelf:
1. Tạo ThemeContext.jsx và ThemeProvider
2. Update tailwind.config.js với dark mode classes
3. Tạo ThemeToggle component trong Header
4. Apply dark classes cho tất cả components hiện có
5. Persist theme preference trong localStorage
```

**✅ Kết quả đạt được:**
- Toggle button (sun/moon icon) trong Header
- Toàn bộ app chuyển dark/light theme
- Background, text, cards, buttons đều đổi màu
- Theme persist sau refresh
- Respect system preference lần đầu

**🧪 Cách test:**
```bash
npm run dev
# 1. Click toggle theme → toàn app đổi màu
# 2. Refresh → theme vẫn giữ nguyên
# 3. Kiểm tra tất cả pages: Home, BookDetail, Login...
# 4. Không có text bị "biến mất" (trắng trên trắng)
# 5. F12 → Application → localStorage → "eshelf_theme"
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Toggle hoạt động mượt
- [ ] Tất cả pages có dark styles
- [ ] Không có contrast issues

---

### Prompt 1.5 - Admin Panel (Part 1 - Layout & Dashboard)
```
Tạo Admin Panel cho eShelf - Phần 1:
1. Layout AdminLayout.jsx với Sidebar navigation
2. Dashboard.jsx với statistics cards (tổng sách, users, downloads)
3. Route protection (giả lập role-based)
4. Cấu trúc thư mục src/admin/
5. Sử dụng Recharts hoặc Chart.js cho biểu đồ
```

**✅ Kết quả đạt được:**
- Route `/admin` với layout riêng (sidebar + content)
- Sidebar: Dashboard, Books, Users, Genres, Feedback
- Dashboard cards: Total Books, Users, Downloads, Reviews
- Line chart: Downloads theo tháng
- Pie chart: Books theo genre
- Protected route (redirect nếu không phải admin)

**🧪 Cách test:**
```bash
npm run dev
# 1. Truy cập /admin → redirect về /login (chưa login)
# 2. F12 → Console → localStorage.setItem('eshelf_user', JSON.stringify({role:"admin"}))
# 3. Refresh /admin → thấy dashboard
# 4. Charts render với mock data
# 5. Click sidebar items → URL thay đổi
# 6. Thu nhỏ browser → sidebar collapse (responsive)
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Layout admin riêng biệt
- [ ] Dashboard hiển thị stats + charts
- [ ] Route protection hoạt động

---

### Prompt 1.6 - Admin Panel (Part 2 - Book Management)
```
Tạo Admin Panel - Phần 2 - Quản lý sách:
1. BookManagement.jsx - danh sách sách với DataTable
2. AddBookForm.jsx, EditBookModal.jsx
3. CRUD operations (mock với JSON data)
4. Upload cover image preview
5. Filter, search, pagination
```

**✅ Kết quả đạt được:**
- Table sách: Cover, Title, Author, Genre, Actions
- Search box filter real-time
- Pagination (10 items/page)
- Modal Add Book với preview cover image
- Modal Edit Book với pre-fill data
- Delete confirmation modal
- Toast notifications cho actions

**🧪 Cách test:**
```bash
npm run dev
# 1. /admin/books → thấy table với data
# 2. Search "Harry" → filter đúng kết quả
# 3. Click "Add Book" → fill form → Preview image
# 4. Submit → sách mới xuất hiện trong table
# 5. Click Edit → sửa title → Save → table update
# 6. Click Delete → confirm → sách biến mất
# 7. Pagination: click page 2 → data thay đổi
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] CRUD hoàn chỉnh
- [ ] Search + pagination hoạt động
- [ ] Form validation hiển thị lỗi

---

### Prompt 1.7 - PWA Configuration
```
Cấu hình PWA cho eShelf:
1. Tạo manifest.json với icons và theme
2. Service Worker cho offline caching
3. Update vite.config.js với vite-plugin-pwa
4. Caching strategy cho static assets và book data
5. Install prompt component
```

**✅ Kết quả đạt được:**
- App có thể "Add to Home Screen" trên mobile
- Offline: trang đã visit vẫn load được
- Icon app trên home screen
- Splash screen khi mở
- Install banner/prompt
- Cache static assets (JS, CSS, images)

**🧪 Cách test:**
```bash
npm run build && npm run preview
# 1. F12 → Application → Manifest → thấy config
# 2. F12 → Lighthouse → Generate report → PWA section
# 3. Network → check "Offline" → refresh → trang vẫn load
# 4. Mobile Chrome → menu → "Add to Home Screen"
# 5. Mở app từ home screen → fullscreen, no browser bar
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Lighthouse PWA score > 90
- [ ] Installable trên mobile
- [ ] Offline mode hoạt động

---

### Prompt 1.8 - Fix Search Functionality Issues
```
Khắc phục các lỗi tìm kiếm trong eShelf:

**Issues cần fix:**
1. Tên sách hiển thị sai so với tên gốc trong kết quả tìm kiếm
2. Click vào sách mở tab mới thay vì navigate trong cùng tab
3. Nút yêu thích + lưu bộ sưu tập bị thừa hoặc chưa hoạt động
4. Các nút chức năng cũ (Feedback, About,...) bị mất

**Yêu cầu:**
1. Kiểm tra và sửa Search.jsx:
   - Đảm bảo hiển thị đúng book.title từ data
   - Sử dụng Link từ react-router-dom thay vì <a> tag
   - Format lại search result cards

2. Loại bỏ hoặc hoàn thiện các nút chưa có chức năng:
   - Nếu chức năng chưa ready → tạm ẩn hoặc disable
   - Nếu giữ lại → kết nối với logic collections/favorites đã có

3. Khôi phục các navigation links bị mất:
   - Feedback link trong Header/Footer
   - About, Contact, Terms links
   - Đảm bảo tất cả routes vẫn hoạt động

4. Kiểm tra BookCard component:
   - Consistent behavior giữa Home, Search, Collections
   - Không mở tab mới khi navigate
```

**✅ Kết quả đạt được:**
- Search results hiển thị đúng tên sách từ book-details.json
- Click vào sách navigate trong cùng tab (không mở tab mới)
- Nút yêu thích/collections hoạt động đúng hoặc được ẩn
- Tất cả menu links (Feedback, About,...) được khôi phục
- Navigation consistent trên toàn app

**🧪 Cách test:**
```bash
npm run dev

# Test 1: Search functionality
# 1. Vào trang chủ → search box
# 2. Gõ "Harry" → Enter
# 3. ✓ Kết quả hiển thị đúng tên sách
# 4. Click vào 1 sách
# 5. ✓ Giữ nguyên tab, URL thay đổi /book/:id
# 6. F12 → Network → không có request mở tab mới

# Test 2: Action buttons
# 1. Tại trang Search results
# 2. Hover vào các book cards
# 3. ✓ Nút favorite hoạt động (icon đổi màu)
# 4. ✓ Nút "Add to Collection" mở modal
# 5. Hoặc các nút chưa ready bị ẩn/disabled

# Test 3: Navigation links
# 1. Check Header → có link Feedback
# 2. Click Feedback → /feedback page mở
# 3. Check Footer → có About, Contact, Terms
# 4. ✓ Tất cả links navigate đúng
# 5. Không có 404 errors

# Test 4: Console errors
# F12 → Console → không có errors màu đỏ
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Search results chính xác 100%
- [ ] Không có tab mới mở
- [ ] Navigation links đầy đủ
- [ ] Không có console errors

**📝 Code hints:**
```jsx
// ❌ WRONG - Opens new tab
<a href={`/book/${book.id}`} target="_blank">

// ✅ CORRECT - Navigate in same tab
<Link to={`/book/${book.id}`}>

// Display correct title
<h3>{book.title}</h3>  // Not book.name or hardcoded

// Conditional rendering for incomplete features
{isFeatureReady ? (
  <button onClick={handleAddToFavorites}>❤️</button>
) : null}
```

---

## 🎯 PHASE 2: BACKEND SERVICES

### Prompt 2.1 - Project Setup & API Gateway
```
Setup Backend cho eShelf với Node.js:
1. Cấu trúc thư mục backend/services/api-gateway/
2. Express.js setup với middleware (cors, helmet, morgan)
3. Rate limiting configuration
4. Request validation với Joi/Zod
5. Error handling middleware
6. Dockerfile cho service
```

**✅ Kết quả đạt được:**
- Folder: `backend/services/api-gateway/`
- Express server chạy port 3000
- Middleware: CORS, Helmet, Morgan logger
- Rate limiter: 100 requests/15min per IP
- Zod validation schemas
- Centralized error handler
- GET /health endpoint
- Dockerfile multi-stage build

**🧪 Cách test:**
```bash
cd backend/services/api-gateway
npm install && npm run dev

# Terminal 2:
curl http://localhost:3000/health
# → {"status":"ok","timestamp":"..."}

# Test rate limit (Windows PowerShell):
for ($i=1; $i -le 105; $i++) { curl http://localhost:3000/health }
# → Sau 100 requests: "Too many requests"

# Test Docker:
docker build -t eshelf-gateway .
docker run -p 3000:3000 eshelf-gateway
curl http://localhost:3000/health
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Server start không lỗi
- [ ] Health check response OK
- [ ] Rate limiting hoạt động
- [ ] Docker build thành công

---

### Prompt 2.2 - Auth Service
```
Tạo Auth Service cho eShelf:
1. Cấu trúc backend/services/auth-service/
2. JWT authentication với access/refresh tokens
3. Routes: POST /register, POST /login, POST /refresh, POST /logout
4. Password hashing với bcrypt
5. Validation và error responses
6. Dockerfile và docker-compose integration
```

**✅ Kết quả đạt được:**
- Auth service chạy port 3001
- POST /register: hash password, return tokens
- POST /login: verify password, return tokens
- POST /refresh: return new access token
- POST /logout: invalidate refresh token
- Token expiry: Access 15m, Refresh 7d
- Error codes: 401, 400, 409 (duplicate)

**🧪 Cách test:**
```bash
cd backend/services/auth-service
npm install && npm run dev

# Register:
curl -X POST http://localhost:3001/register ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@test.com\",\"password\":\"123456\",\"username\":\"test\"}"
# → {"accessToken":"...","refreshToken":"..."}

# Login:
curl -X POST http://localhost:3001/login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"test@test.com\",\"password\":\"123456\"}"
# → {"accessToken":"...","refreshToken":"..."}

# Duplicate email → 409 error
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Register/Login hoạt động
- [ ] JWT tokens valid (paste vào jwt.io)
- [ ] Refresh token flow OK

---

### Prompt 2.3 - User Service
```
Tạo User Service cho eShelf:
1. Cấu trúc backend/services/user-service/
2. Routes: GET/PUT /profile, GET /reading-history, GET/POST /favorites
3. User preferences management
4. Integration với Auth Service (verify token)
5. Database models (Prisma/Sequelize schema)
```

**✅ Kết quả đạt được:**
- User service chạy port 3002
- GET /profile: user info (auth required)
- PUT /profile: update user info
- GET /favorites: list favorite books
- POST /favorites: add book to favorites
- DELETE /favorites/:id: remove
- GET /reading-history: list with progress
- JWT middleware verify token

**🧪 Cách test:**
```bash
# Lấy token từ auth service trước
set TOKEN=eyJhbG...

curl http://localhost:3002/profile ^
  -H "Authorization: Bearer %TOKEN%"
# → {"id":1,"email":"...","username":"..."}

curl -X POST http://localhost:3002/favorites ^
  -H "Authorization: Bearer %TOKEN%" ^
  -H "Content-Type: application/json" ^
  -d "{\"bookId\":1}"
# → {"message":"Added to favorites"}

# Không có token:
curl http://localhost:3002/profile
# → 401 {"error":"Unauthorized"}
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Auth middleware hoạt động
- [ ] CRUD favorites OK
- [ ] Reading history lưu được

---

### Prompt 2.4 - Book Service
```
Tạo Book Service cho eShelf:
1. Cấu trúc backend/services/book-service/
2. Routes: CRUD /books, GET /books/search, GET /books/:id/similar
3. File upload to S3 (cover images, PDF files)
4. Pagination và filtering
5. Database models cho books, genres, reviews
```

**✅ Kết quả đạt được:**
- Book service chạy port 3003
- GET /books: pagination (?page=1&limit=10)
- GET /books/:id: detail with reviews
- POST /books: create (admin only)
- PUT /books/:id: update
- DELETE /books/:id: soft delete
- GET /books/search?q=harry&genre=fantasy
- POST /books/:id/upload: file to S3

**🧪 Cách test:**
```bash
curl "http://localhost:3003/books?page=1&limit=5"
# → {"data":[...],"total":50,"page":1,"totalPages":10}

curl "http://localhost:3003/books/search?q=harry"
# → {"data":[matching books]}

curl http://localhost:3003/books/1
# → {book detail with reviews, genres}

# Upload (với admin token):
curl -X POST http://localhost:3003/books/1/upload ^
  -H "Authorization: Bearer %ADMIN_TOKEN%" ^
  -F "file=@book.pdf"
# → {"url":"https://s3.../book.pdf"}
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] CRUD books hoạt động
- [ ] Search + filter OK
- [ ] Pagination đúng format

---

### Prompt 2.5 - Search Service với Elasticsearch
```
Tạo Search Service cho eShelf:
1. Cấu trúc backend/services/search-service/
2. Elasticsearch client setup
3. Index mapping cho books
4. Full-text search với filters (genre, year, language)
5. Autocomplete suggestions
6. docker-compose với Elasticsearch container
```

**✅ Kết quả đạt được:**
- Search service chạy port 3004
- Elasticsearch container
- Index "books" với proper mapping
- GET /search?q=harry → full-text search
- Filters: ?genre=fantasy&year=2020
- GET /autocomplete?q=har → suggestions
- Highlight matching text in results

**🧪 Cách test:**
```bash
docker-compose up -d elasticsearch
npm run dev

curl "http://localhost:3004/search?q=harry%20potter"
# → {"hits":[...],"total":5,"took":12}

curl "http://localhost:3004/autocomplete?q=har"
# → ["Harry Potter","Haruki Murakami",...]

# Check Elasticsearch direct:
curl http://localhost:9200/books/_search
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Elasticsearch container healthy
- [ ] Search returns results
- [ ] Autocomplete response < 100ms

---

### Prompt 2.6 - Notification Service
```
Tạo Notification Service cho eShelf:
1. Cấu trúc backend/services/notification-service/
2. Email notifications với AWS SES hoặc Nodemailer
3. In-app notifications với WebSocket
4. Notification templates
5. Queue system với Bull/Redis
```

**✅ Kết quả đạt được:**
- Notification service chạy port 3005
- Email templates: Welcome, Password Reset
- POST /notifications/email: queue email job
- WebSocket endpoint: real-time notifications
- GET /notifications: list user notifications
- PUT /notifications/:id/read: mark as read
- Redis queue cho async email sending

**🧪 Cách test:**
```bash
docker-compose up -d redis
npm run dev

curl -X POST http://localhost:3005/notifications/email ^
  -H "Content-Type: application/json" ^
  -d "{\"to\":\"test@test.com\",\"template\":\"welcome\"}"
# → {"jobId":"123","status":"queued"}

# WebSocket test (browser console):
const ws = new WebSocket('ws://localhost:3005');
ws.onmessage = (e) => console.log(e.data);

# Check Redis queue:
redis-cli LLEN bull:email:waiting
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Email queue hoạt động
- [ ] WebSocket connected
- [ ] Notifications CRUD OK

---

## 🎯 PHASE 3: DATABASE

### Prompt 3.1 - Database Schema Design
```
Thiết kế Database Schema cho eShelf với PostgreSQL:
1. Tạo database/schemas/schema.sql với tất cả tables
2. ERD diagram description
3. Indexes cho performance
4. Foreign keys và constraints
5. Seed data scripts
Bao gồm: users, books, genres, reviews, collections, reading_history, notifications
```

**✅ Kết quả đạt được:**
- File schema.sql với CREATE TABLE statements
- 12+ tables: users, books, genres, reviews, collections...
- Primary keys, foreign keys, constraints
- Indexes trên frequently queried columns
- seed.sql với sample data (50+ books, 10 users)
- ERD description trong SQL comments

**🧪 Cách test:**
```bash
# Start PostgreSQL (docker hoặc local)
psql -U postgres
CREATE DATABASE eshelf;
\c eshelf
\i database/schemas/schema.sql
# → Tables created successfully

\dt  # List all tables
\i database/schemas/seed.sql
SELECT * FROM books LIMIT 5;
# → Sample data hiển thị

# Test FK constraint:
INSERT INTO reviews (user_id, book_id, rating) VALUES (999, 1, 5);
# → Error: FK violation (user 999 không tồn tại)
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Tất cả tables created
- [ ] Foreign keys hoạt động
- [ ] Seed data inserted

---

### Prompt 3.2 - Prisma/Sequelize Setup
```
Setup ORM cho eShelf Backend:
1. Prisma schema file với tất cả models
2. Migration scripts
3. Seed data với Prisma
4. Connection pooling configuration
5. Shared database types package
```

**✅ Kết quả đạt được:**
- prisma/schema.prisma với all models
- prisma/migrations/ với versioned migrations
- prisma/seed.ts với sample data
- Connection pool: 10 connections default
- Environment variable DATABASE_URL
- TypeScript types generated

**🧪 Cách test:**
```bash
cd backend
npm install

npx prisma generate
# → Generated Prisma Client

npx prisma migrate dev --name init
# → Migrations applied

npx prisma db seed
# → Seeding finished

npx prisma studio
# → Browser opens: http://localhost:5555
# → Xem và edit data trực tiếp
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Prisma generate thành công
- [ ] Migrations chạy được
- [ ] Prisma Studio hiển thị data

---

### Prompt 3.3 - Database Migrations
```
Tạo Migration System cho eShelf:
1. Cấu trúc database/migrations/
2. Initial migration với all tables
3. Rollback scripts
4. CI/CD integration cho migrations
5. Environment-specific configurations
```

**✅ Kết quả đạt được:**
- Folder migrations/ với timestamp naming
- Script migrate.sh: run pending migrations
- Script rollback.sh: revert last migration
- GitHub Action step cho auto-migrate
- Config files: dev/staging/prod
- Migration history tracking table

**🧪 Cách test:**
```bash
# Run migrations:
./scripts/migrate.sh
# → Applied 3 migrations

# Check history:
psql -c "SELECT * FROM _migrations"
# → List all applied migrations

# Rollback:
./scripts/rollback.sh
# → Reverted: 20240101_create_users

# Dry run:
./scripts/migrate.sh --dry-run
# → Would apply: 20240102_add_reviews
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Migrate + rollback hoạt động
- [ ] Migration history tracked
- [ ] CI integration ready

---

## 🎯 PHASE 4: ML/AI FEATURES

### Prompt 4.1 - ML Service Setup
```
Setup ML Service với Python FastAPI:
1. Cấu trúc backend/services/ml-service/
2. FastAPI application với Pydantic models
3. Endpoints: /recommendations, /similar-books, /health
4. MLflow integration setup
5. Dockerfile với Python dependencies
```

**✅ Kết quả đạt được:**
- FastAPI app chạy port 8000
- GET /health: status + model version
- POST /recommendations: user_id → list books
- POST /similar-books: book_id → similar books
- Pydantic models cho request/response
- MLflow client configured
- Dockerfile multi-stage build

**🧪 Cách test:**
```bash
cd backend/services/ml-service
pip install -r requirements.txt
uvicorn main:app --reload

curl http://localhost:8000/health
# → {"status":"ok","model_version":"1.0.0"}

curl -X POST http://localhost:8000/recommendations ^
  -H "Content-Type: application/json" ^
  -d "{\"user_id\":\"user123\",\"n\":5}"
# → {"books":[1,5,12,23,45]}

# Swagger docs:
start http://localhost:8000/docs
# → Interactive API documentation
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] FastAPI chạy được
- [ ] Endpoints trả về mock data
- [ ] Swagger docs accessible

---

### Prompt 4.2 - Recommendation System
```
Implement Recommendation System cho eShelf:
1. Collaborative Filtering model với Surprise/LightFM
2. Training script với sample data
3. Model serialization và loading
4. API endpoint integration
5. A/B testing setup
```

**✅ Kết quả đạt được:**
- Training script: train_recommender.py
- Model: Collaborative Filtering (SVD algorithm)
- Saved model: models/recommender.pkl
- API endpoint loads và serves model
- A/B testing: 50% ML recommendations, 50% popular
- Metrics logged to MLflow

**🧪 Cách test:**
```bash
# Train model:
python training/train_recommender.py
# → Model saved to models/recommender.pkl
# → RMSE: 0.89, MAE: 0.68

# Start MLflow UI:
mlflow ui
# → http://localhost:5000 → See experiment runs

# Test API:
curl -X POST http://localhost:8000/recommendations ^
  -d "{\"user_id\":\"user123\",\"n\":5}"
# → Real predictions from trained model
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Model trained successfully
- [ ] API serves real predictions
- [ ] MLflow tracking hoạt động

---

### Prompt 4.3 - Content-Based Similarity
```
Implement Similar Books feature:
1. TF-IDF vectorization cho book descriptions
2. Cosine similarity calculation
3. Caching với Redis
4. API endpoint với pagination
5. Fallback strategy khi không đủ data
```

**✅ Kết quả đạt được:**
- TF-IDF vectors cho all book descriptions
- Precomputed similarity matrix
- Redis cache: book_id → similar_book_ids
- GET /similar-books/:id → top 10 similar
- Fallback: same genre books nếu no data
- Cache TTL: 24 hours

**🧪 Cách test:**
```bash
# Precompute similarities:
python scripts/compute_similarities.py
# → Processed 1000 books, saved to Redis

# API test:
curl http://localhost:8000/similar-books/1
# → {"similar":[{"id":5,"score":0.89},{"id":12,"score":0.76},...]}

# Check Redis cache:
redis-cli GET similar:book:1
# → "[5,12,23,45,67]"

# Performance:
time curl http://localhost:8000/similar-books/1
# → Response time < 50ms (cached)
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Similarity scores reasonable (0.5-1.0)
- [ ] Redis cache hoạt động
- [ ] Fallback hoạt động khi no cache

---

### Prompt 4.4 - Genre Classification (Optional)
```
Implement Auto Genre Classification:
1. BERT fine-tuning script cho genre classification
2. Model serving với FastAPI
3. Batch processing pipeline
4. Confidence threshold handling
5. Human review queue
```

**✅ Kết quả đạt được:**
- Fine-tuned BERT model cho 20 genres
- POST /classify: text → predicted genre
- Confidence < 0.7 → queue for human review
- Batch endpoint: /classify-batch
- Model size: ~200MB, inference < 100ms

**🧪 Cách test:**
```bash
# Train (takes ~2 hours on GPU):
python training/train_classifier.py
# → Accuracy: 0.87, F1: 0.85

# Test single:
curl -X POST http://localhost:8000/classify ^
  -d "{\"text\":\"A wizard boy discovers he has magical powers...\"}"
# → {"genre":"fantasy","confidence":0.94}

# Low confidence:
curl -X POST http://localhost:8000/classify ^
  -d "{\"text\":\"Random unclear text here...\"}"
# → {"genre":"unknown","confidence":0.3,"needs_review":true}
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Model accuracy > 85%
- [ ] API serves predictions
- [ ] Review queue accessible

---

## 🎯 PHASE 5: DEVOPS - LAB 1 (Infrastructure as Code)

### Prompt 5.1 - Terraform VPC Module
```
Tạo Terraform VPC Module cho eShelf (Lab 1 - 3 điểm):
1. infrastructure/terraform/modules/vpc/main.tf
2. VPC với CIDR 10.0.0.0/16
3. Public subnets (10.0.1.0/24, 10.0.2.0/24) trong 2 AZs
4. Private subnets (10.0.10.0/24, 10.0.11.0/24)
5. Internet Gateway
6. variables.tf và outputs.tf
```

**✅ Kết quả đạt được:**
- Module folder: modules/vpc/
- Files: main.tf, variables.tf, outputs.tf
- VPC với DNS enabled
- 2 public + 2 private subnets (multi-AZ)
- Internet Gateway attached to VPC
- Proper resource tagging

**🧪 Cách test:**
```bash
cd infrastructure/terraform/modules/vpc

# Validate syntax:
terraform init
terraform validate
# → Success! The configuration is valid.

# Check formatting:
terraform fmt -check
# → No changes needed

# Security scan:
checkov -d . --framework terraform
# → Passed: 10, Failed: 0

# Plan (in environments/dev):
cd ../../environments/dev
terraform plan -target=module.vpc
# → Plan: 7 to add, 0 to change, 0 to destroy
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] terraform validate pass
- [ ] terraform plan shows expected resources
- [ ] Checkov no critical failures

---

### Prompt 5.2 - Terraform Route Tables & NAT
```
Tạo Terraform Route Tables và NAT Gateway (Lab 1 - 3 điểm):
1. infrastructure/terraform/modules/networking/
2. Public route table với route to IGW
3. Private route table với route to NAT Gateway
4. NAT Gateway trong public subnet
5. Elastic IP cho NAT Gateway
6. Subnet associations
```

**✅ Kết quả đạt được:**
- Module folder: modules/networking/
- Public route table → Internet Gateway
- Private route table → NAT Gateway
- NAT Gateway in public subnet
- Elastic IP allocated
- Route table associations complete

**🧪 Cách test:**
```bash
terraform plan -target=module.networking
# → Plan: 6 to add

terraform apply -target=module.networking
# → NAT Gateway: nat-0abc123...

# Verify in AWS Console or CLI:
aws ec2 describe-nat-gateways --region us-east-1
# → State: "available"

# Test from private EC2 (after EC2 created):
ssh ec2-user@private-ip
curl https://google.com
# → Should work (through NAT)
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] NAT Gateway state: available
- [ ] Route tables associated
- [ ] Private subnet can access internet

---

### Prompt 5.3 - Terraform EC2 Module
```
Tạo Terraform EC2 Module (Lab 1 - 2 điểm):
1. infrastructure/terraform/modules/ec2/
2. Bastion Host (Public EC2) trong public subnet
3. App Server (Private EC2) trong private subnet
4. Key pair configuration
5. User data scripts
6. AMI data source (Amazon Linux 2)
```

**✅ Kết quả đạt được:**
- Module folder: modules/ec2/
- Bastion Host: t3.micro, public IP, public subnet
- App Server: t3.small, private IP only, private subnet
- Key pair resource or data source
- User data: install Docker, Node.js
- AMI: latest Amazon Linux 2023

**🧪 Cách test:**
```bash
terraform apply -target=module.ec2

# Get outputs:
terraform output bastion_public_ip
# → 54.x.x.x

# SSH to Bastion:
ssh -i key.pem ec2-user@54.x.x.x
# → Welcome to Amazon Linux!

# From Bastion, SSH to private:
ssh ec2-user@10.0.10.x
# → Connected!

# Verify user data:
docker --version
# → Docker version 24.x
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Bastion accessible via SSH
- [ ] Private EC2 only via Bastion
- [ ] User data executed successfully

---

### Prompt 5.4 - Terraform Security Groups
```
Tạo Terraform Security Groups (Lab 1 - 2 điểm):
1. infrastructure/terraform/modules/security-groups/
2. Bastion SG: SSH (22) from my IP only
3. App SG: SSH from Bastion SG, Port 3000 from Bastion
4. ALB SG: HTTP/HTTPS from anywhere
5. Proper egress rules
6. Best practices annotations
```

**✅ Kết quả đạt được:**
- Module folder: modules/security-groups/
- bastion_sg: ingress 22 from var.my_ip
- app_sg: ingress 22 from bastion_sg, 3000 from bastion_sg
- alb_sg: ingress 80, 443 from 0.0.0.0/0
- All SGs: egress to anywhere
- Comments explaining each rule

**🧪 Cách test:**
```bash
# Security scan:
checkov -d modules/security-groups/
# → Passed: CKV_AWS_23 (ingress restricted)

terraform apply -target=module.security_groups

# Test SSH from allowed IP:
ssh -i key.pem ec2-user@bastion-ip
# → Success

# Test SSH from different IP (use VPN or ask friend):
ssh -i key.pem ec2-user@bastion-ip
# → Connection timeout

# Test app access from bastion:
curl http://private-ec2:3000
# → Should work
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] SSH only from your IP
- [ ] Private EC2 only accessible via Bastion
- [ ] Checkov pass

---

### Prompt 5.5 - Terraform Environment Configuration
```
Tạo Terraform Environment Setup:
1. infrastructure/terraform/environments/dev/main.tf
2. Module calls với variable values
3. Backend configuration (S3 + DynamoDB)
4. terraform.tfvars template
5. .gitignore cho sensitive files
```

**✅ Kết quả đạt được:**
- environments/dev/main.tf with module calls
- variables.tf with environment variables
- terraform.tfvars.example (template)
- backend.tf: S3 bucket + DynamoDB lock table
- .gitignore: *.tfvars, .terraform/, *.tfstate

**🧪 Cách test:**
```bash
cd infrastructure/terraform/environments/dev

# Copy and edit tfvars:
copy terraform.tfvars.example terraform.tfvars
# Edit with your values

# Initialize with S3 backend:
terraform init
# → Backend: S3, Lock: DynamoDB

# Full plan:
terraform plan
# → Shows all resources from all modules

# Apply:
terraform apply
# → All infrastructure created

# Check state in S3:
aws s3 ls s3://eshelf-terraform-state/
# → dev/terraform.tfstate
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] S3 backend configured
- [ ] State locking works (run 2 applies)
- [ ] Full infrastructure deploys

---

### Prompt 5.6 - CloudFormation VPC Stack
```
Tạo CloudFormation VPC Template:
1. infrastructure/cloudformation/templates/vpc-stack.yaml
2. Tương đương với Terraform VPC module
3. Parameters cho customization
4. Outputs cho cross-stack references
5. Proper resource naming
```

**✅ Kết quả đạt được:**
- vpc-stack.yaml với AWSTemplateFormatVersion
- Parameters: Environment, VpcCIDR, SubnetCIDRs
- Resources: VPC, 4 Subnets, IGW, attachments
- Outputs: VpcId, SubnetIds (exported for cross-stack)
- Conditions for optional resources
- Metadata for parameter grouping

**🧪 Cách test:**
```bash
# Validate template:
aws cloudformation validate-template ^
  --template-body file://vpc-stack.yaml
# → {"Parameters":[...]}

# Lint:
cfn-lint vpc-stack.yaml
# → 0 errors, 0 warnings

# Create stack:
aws cloudformation create-stack ^
  --stack-name eshelf-vpc-dev ^
  --template-body file://vpc-stack.yaml ^
  --parameters ParameterKey=Environment,ParameterValue=dev

# Check outputs:
aws cloudformation describe-stacks ^
  --stack-name eshelf-vpc-dev ^
  --query "Stacks[0].Outputs"
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] cfn-lint pass
- [ ] Stack creates successfully
- [ ] Outputs exported correctly

---

### Prompt 5.7 - CloudFormation EC2 Stack
```
Tạo CloudFormation EC2 Template:
1. infrastructure/cloudformation/templates/ec2-stack.yaml
2. Bastion và App Server EC2
3. Reference VPC stack outputs
4. Security Groups inline hoặc separate stack
5. IAM Instance Profile
```

**✅ Kết quả đạt được:**
- ec2-stack.yaml với nested references
- Fn::ImportValue cho VPC stack outputs
- Bastion EC2 + App Server EC2
- Security Groups inline
- IAM Role + Instance Profile
- UserData script (base64 encoded)

**🧪 Cách test:**
```bash
# Lint:
cfn-lint ec2-stack.yaml
# → 0 errors

# Create stack (after VPC stack):
aws cloudformation create-stack ^
  --stack-name eshelf-ec2-dev ^
  --template-body file://ec2-stack.yaml ^
  --capabilities CAPABILITY_IAM

# Get Bastion IP:
aws cloudformation describe-stacks ^
  --stack-name eshelf-ec2-dev ^
  --query "Stacks[0].Outputs[?OutputKey=='BastionPublicIP'].OutputValue"

# SSH test:
ssh -i key.pem ec2-user@<bastion-ip>
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Stack creates with IAM capability
- [ ] Cross-stack references work
- [ ] SSH accessible

---

### Prompt 5.8 - Infrastructure Test Cases
```
Tạo Test Cases cho Infrastructure (Lab 1):
1. infrastructure/terraform/tests/test_infrastructure.sh
2. Test VPC exists và configured correctly
3. Test Public EC2 reachable via SSH
4. Test Private EC2 only via Bastion
5. Test NAT Gateway (private EC2 can curl google.com)
6. Test Security Groups rules
```

**✅ Kết quả đạt được:**
- test_infrastructure.sh với all tests
- Separate scripts: test_vpc.sh, test_ec2.sh, test_security.sh
- Exit codes for CI integration
- Colored output: PASS (green), FAIL (red)
- Verbose mode with -v flag

**🧪 Cách test:**
```bash
cd infrastructure/tests
chmod +x *.sh

./test_infrastructure.sh
# → [PASS] VPC exists with correct CIDR
# → [PASS] Bastion SSH accessible
# → [PASS] Private EC2 via Bastion only
# → [PASS] NAT Gateway working
# → [PASS] Security Groups configured
# → All tests: 6/6 passed

# CI mode (exit code only):
./test_infrastructure.sh --ci
echo $?
# → 0 (success) or 1 (failure)
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] All tests pass
- [ ] Scripts executable
- [ ] CI exit codes correct

---

## 🎯 PHASE 6: DEVOPS - LAB 2 (CI/CD Automation)

### Prompt 6.1 - GitHub Actions Terraform Pipeline
```
Tạo GitHub Actions cho Terraform (Lab 2 - 3 điểm):
1. .github/workflows/terraform.yml
2. Checkov security scan
3. Terraform fmt, validate, plan
4. Terraform apply on main branch
5. PR comment với plan output
6. AWS credentials từ secrets
```

**✅ Kết quả đạt được:**
- Workflow triggers on push/PR to main
- Jobs: checkov → terraform-plan → terraform-apply
- Checkov results as PR comment/artifact
- Terraform plan output in PR comment
- Apply only on merge to main
- OIDC authentication with AWS (no static keys)

**🧪 Cách test:**
```bash
# Create feature branch:
git checkout -b feature/test-infra
# Make a change to .tf file
git push origin feature/test-infra

# Create PR:
gh pr create --title "Test infra change"

# Check Actions tab:
# → Checkov scan ✓
# → Terraform plan ✓
# → PR comment with plan output

# Merge PR:
# → Terraform apply runs
# → Resources created/updated in AWS
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Checkov scan runs
- [ ] Plan output in PR comment
- [ ] Apply only on main merge

---

### Prompt 6.2 - CloudFormation CodePipeline
```
Tạo AWS CodePipeline cho CloudFormation (Lab 2 - 3 điểm):
1. infrastructure/cloudformation/pipeline-stack.yaml
2. CodeCommit hoặc GitHub source
3. CodeBuild với cfn-lint và taskcat
4. CloudFormation deploy stage
5. buildspec.yml configuration
```

**✅ Kết quả đạt được:**
- pipeline-stack.yaml defines CodePipeline
- Source stage: GitHub webhook (or CodeCommit)
- Build stage: cfn-lint + taskcat validation
- Deploy stage: CreateChangeSet → ExecuteChangeSet
- buildspec.yml for CodeBuild
- taskcat.yml for integration testing

**🧪 Cách test:**
```bash
# Deploy pipeline stack:
aws cloudformation create-stack ^
  --stack-name eshelf-pipeline ^
  --template-body file://pipeline-stack.yaml ^
  --capabilities CAPABILITY_IAM

# Push a change:
git push origin main

# Check CodePipeline console:
# → Source ✓
# → Build ✓ (cfn-lint, taskcat)
# → Deploy ✓

# Check CodeBuild logs:
aws logs tail /aws/codebuild/eshelf-build --follow
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Pipeline triggers on push
- [ ] cfn-lint + taskcat pass
- [ ] CloudFormation deploys

---

### Prompt 6.3 - Jenkins Pipeline Setup
```
Tạo Jenkins Pipeline cho eShelf (Lab 2 - 4 điểm - Part 1):
1. jenkins/Jenkinsfile
2. Lint & Test stages (parallel)
3. SonarQube analysis stage
4. Docker build stage
5. Environment variables và credentials
```

**✅ Kết quả đạt được:**
- Declarative Jenkinsfile
- Parallel stages: Frontend lint/test, Backend lint/test
- SonarQube scanner integration
- Docker build with build args
- Credentials: AWS, Docker Hub, SonarQube
- Environment variables per stage

**🧪 Cách test:**
```bash
# Start Jenkins:
docker-compose -f jenkins/docker-compose.yml up -d
# → http://localhost:8080

# Create pipeline job:
# → New Item → Pipeline → SCM: Git

# Build Now:
# → Lint & Test (parallel) ✓
# → SonarQube Analysis ✓
# → Docker Build ✓

# Check SonarQube:
start http://localhost:9000
# → Project: eShelf → Quality Gate

# Check Docker images:
docker images | findstr eshelf
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Jenkins pipeline runs end-to-end
- [ ] SonarQube shows results
- [ ] Docker images built

---

### Prompt 6.4 - Jenkins Security Scanning
```
Jenkins Pipeline - Security Scanning (Lab 2 - Part 2):
1. Trivy container scan stage
2. Snyk dependency scan (optional)
3. OWASP dependency check
4. Fail pipeline on HIGH/CRITICAL
5. Report generation
```

**✅ Kết quả đạt được:**
- Trivy stage: scan Docker images
- Snyk stage: scan npm dependencies
- OWASP Dependency Check stage
- Threshold: fail on HIGH or CRITICAL
- HTML reports archived in Jenkins
- Vulnerability summary in build output

**🧪 Cách test:**
```bash
# Run pipeline
# → Security Scan stage:
#   → Trivy: CRITICAL: 0, HIGH: 2, MEDIUM: 5
#   → OWASP: No vulnerabilities found

# View reports:
# → Build → Artifacts → trivy-report.html
# → Build → Artifacts → dependency-check-report.html

# Test failure:
# Add a vulnerable dependency → Rebuild
# → Pipeline fails at Security Scan stage
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Trivy scans complete
- [ ] Reports accessible in Jenkins
- [ ] Fails on HIGH/CRITICAL

---

### Prompt 6.5 - Jenkins Kubernetes Deployment
```
Jenkins Pipeline - K8s Deployment (Lab 2 - Part 3):
1. Push to ECR stage
2. Deploy to Staging với kubectl
3. Integration tests stage
4. Manual approval gate
5. Deploy to Production
6. Rollback on failure
```

**✅ Kết quả đạt được:**
- ECR login và push stage
- Deploy to Staging with kubectl/kustomize
- Integration tests with Newman/Postman
- Manual approval input step
- Deploy to Production
- post { failure { rollback } }

**🧪 Cách test:**
```bash
# Run pipeline:
# → ECR Push ✓
# → Deploy Staging ✓
# → Integration Tests ✓
# → Waiting for approval... (click Proceed)
# → Deploy Production ✓

# Verify Kubernetes:
kubectl get pods -n staging
kubectl get pods -n production
# → New version running

# Test rollback:
# → Deploy a broken image
# → Pipeline fails at Integration Tests
# → Rollback executed automatically
kubectl rollout history deployment/eshelf -n staging
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] ECR push works
- [ ] Staging auto-deploys
- [ ] Manual approval works
- [ ] Rollback tested

---

### Prompt 6.6 - GitHub Actions Frontend CI
```
Tạo GitHub Actions cho Frontend CI:
1. .github/workflows/ci-frontend.yml
2. Install, lint, test, build
3. Upload build artifacts
4. Deploy to S3/CloudFront (staging)
5. Lighthouse performance check
```

**✅ Kết quả đạt được:**
- Workflow on PR to main
- Node.js matrix: 18.x, 20.x
- Steps: install → lint → test → build
- Artifacts: build folder, coverage report
- S3 sync + CloudFront invalidation
- Lighthouse CI with performance budgets

**🧪 Cách test:**
```bash
# Create PR:
git checkout -b feature/ui-update
git push origin feature/ui-update
gh pr create

# Check Actions tab:
# → Matrix: Node 18 ✓, Node 20 ✓
# → Artifacts: build.zip, coverage.zip
# → Lighthouse scores: 92, 98, 95, 100

# Merge to main:
# → Deploys to S3/CloudFront
# → https://staging.eshelf.com
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] All CI steps pass
- [ ] Artifacts uploaded
- [ ] Lighthouse scores > 90

---

### Prompt 6.7 - GitHub Actions Backend CI
```
Tạo GitHub Actions cho Backend CI:
1. .github/workflows/ci-backend.yml
2. Matrix build cho multiple services
3. Unit tests với coverage
4. Docker build và push to ECR
5. Integration tests với docker-compose
```

**✅ Kết quả đạt được:**
- Matrix: api-gateway, auth, user, book services
- Per-service: install → lint → test → coverage
- Docker build with layer caching
- ECR push only on main branch
- Integration tests with testcontainers
- Codecov coverage reports

**🧪 Cách test:**
```bash
# Create PR:
git checkout -b feature/auth-update
# Edit backend/services/auth-service/
git push && gh pr create

# Check Actions:
# → Matrix jobs (parallel):
#   → api-gateway: test ✓, coverage 85%
#   → auth-service: test ✓, coverage 78%
#   → user-service: test ✓, coverage 82%
# → Codecov comment on PR

# Merge to main:
aws ecr describe-images --repository-name eshelf/auth-service
# → New image pushed
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Matrix builds all services
- [ ] Coverage reports generated
- [ ] ECR push on main
- [ ] Integration tests pass

---

## 🎯 PHASE 7: KUBERNETES & ADVANCED DEVOPS

### Prompt 7.1 - Kubernetes Base Manifests
```
Tạo Kubernetes Base Manifests:
1. infrastructure/kubernetes/base/namespace.yaml
2. ConfigMaps và Secrets templates
3. PersistentVolumeClaims
4. NetworkPolicies
5. ResourceQuotas và LimitRanges
```

**✅ Kết quả đạt được:**
- Namespace: eshelf with labels
- ConfigMaps: app-config, feature-flags
- Secrets template: db-credentials (sealed)
- PVCs: postgres-data, elasticsearch-data
- NetworkPolicy: deny-all default, allow specific
- ResourceQuota, LimitRange for namespace

**🧪 Cách test:**
```bash
kubectl apply -f kubernetes/base/

kubectl get ns eshelf
kubectl get configmap,secret,pvc -n eshelf

# Test NetworkPolicy:
kubectl run test --image=nginx -n eshelf
kubectl exec test -- curl api-gateway:3000
# → Timeout (blocked by NetworkPolicy)

# Test ResourceQuota:
kubectl describe quota -n eshelf
# → Used: 2 pods, Limit: 20 pods
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] All base resources created
- [ ] NetworkPolicy blocks unauthorized traffic
- [ ] Quotas enforced

---

### Prompt 7.2 - Kubernetes Deployments
```
Tạo Kubernetes Deployments cho eShelf:
1. infrastructure/kubernetes/deployments/frontend.yaml
2. infrastructure/kubernetes/deployments/api-gateway.yaml
3. Liveness và Readiness probes
4. Resource requests/limits
5. Environment variables từ ConfigMap/Secret
```

**✅ Kết quả đạt được:**
- frontend deployment: 3 replicas, port 80
- api-gateway deployment: 2 replicas, port 3000
- Liveness probe: /health every 10s
- Readiness probe: /ready every 5s
- Resources: requests 100m/128Mi, limits 500m/512Mi
- Env from ConfigMap and Secret references

**🧪 Cách test:**
```bash
kubectl apply -f kubernetes/deployments/

kubectl get pods -n eshelf
# → frontend-xxx Running (3)
# → api-gateway-xxx Running (2)

kubectl describe pod frontend-xxx -n eshelf | findstr -A5 Liveness
# → Liveness: http-get /health

kubectl top pods -n eshelf
# → CPU/Memory within limits

kubectl logs api-gateway-xxx -n eshelf
# → Server started, env vars loaded
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] All pods Running
- [ ] Probes passing (no restarts)
- [ ] Env vars loaded correctly

---

### Prompt 7.3 - Kubernetes Services & Ingress
```
Tạo Kubernetes Services và Ingress:
1. infrastructure/kubernetes/services/ cho mỗi deployment
2. infrastructure/kubernetes/ingress/ingress.yaml
3. TLS configuration
4. Path-based routing
5. Annotations cho ALB/Nginx Ingress
```

**✅ Kết quả đạt được:**
- ClusterIP services for each deployment
- Ingress with host-based routing
- TLS with cert-manager (Let's Encrypt)
- Path routing: / → frontend, /api → api-gateway
- ALB/Nginx annotations for health checks

**🧪 Cách test:**
```bash
kubectl apply -f kubernetes/services/
kubectl apply -f kubernetes/ingress/

kubectl get svc -n eshelf
# → frontend ClusterIP, api-gateway ClusterIP

kubectl get ingress -n eshelf
# → ADDRESS: abc123.elb.amazonaws.com

# Test routing:
curl https://eshelf.com
# → Frontend HTML

curl https://eshelf.com/api/health
# → {"status":"ok"}

# Check TLS:
curl -vI https://eshelf.com 2>&1 | findstr "SSL certificate"
# → SSL certificate verify ok
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Services accessible internally
- [ ] Ingress routes correctly
- [ ] TLS working (HTTPS green lock)

---

### Prompt 7.4 - Kubernetes HPA & Kustomize
```
Tạo HPA và Kustomize overlays:
1. infrastructure/kubernetes/hpa/ cho frontend, api-gateway
2. infrastructure/kubernetes/kustomize/base/
3. infrastructure/kubernetes/kustomize/overlays/staging/
4. infrastructure/kubernetes/kustomize/overlays/production/
5. Environment-specific patches
```

**✅ Kết quả đạt được:**
- HPA: min 2, max 10, target CPU 70%
- kustomize/base/ with all resources
- staging overlay: 1 replica, dev config
- production overlay: 3 replicas, prod config
- Patches for replicas, resources, env

**🧪 Cách test:**
```bash
# Deploy staging:
kubectl apply -k kubernetes/kustomize/overlays/staging/

kubectl get hpa -n eshelf-staging
# → frontend: 2/10 replicas, 45% CPU

# Load test:
hey -n 1000 -c 50 https://staging.eshelf.com

kubectl get pods -n eshelf-staging -w
# → Pods scaling from 2 to 5...

# Compare overlays:
kustomize build overlays/staging > /tmp/staging.yaml
kustomize build overlays/production > /tmp/prod.yaml
diff /tmp/staging.yaml /tmp/prod.yaml
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] HPA scales pods under load
- [ ] Overlays produce different configs
- [ ] Patches applied correctly

---

### Prompt 7.5 - Helm Chart
```
Tạo Helm Chart cho eShelf:
1. infrastructure/helm/eshelf/Chart.yaml
2. values.yaml với default values
3. templates/ cho deployments, services, ingress
4. values-staging.yaml, values-production.yaml
5. _helpers.tpl cho common labels
```

**✅ Kết quả đạt được:**
- Chart.yaml with metadata, version
- values.yaml: image, replicas, resources, ingress
- templates/: deployment, service, ingress, hpa, configmap
- _helpers.tpl: common labels, fullname
- values-staging.yaml, values-production.yaml

**🧪 Cách test:**
```bash
cd infrastructure/helm

# Lint:
helm lint eshelf/
# → 1 chart(s) linted, 0 chart(s) failed

# Template (dry-run):
helm template eshelf/ -f eshelf/values-staging.yaml
# → Rendered manifests printed

# Install:
helm install eshelf-staging eshelf/ ^
  -f eshelf/values-staging.yaml ^
  -n staging --create-namespace

helm list -n staging
# → NAME: eshelf-staging, STATUS: deployed

# Upgrade:
helm upgrade eshelf-staging eshelf/ -f eshelf/values-staging.yaml
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] helm lint passes
- [ ] Template renders correctly
- [ ] Install/upgrade works

---

### Prompt 7.6 - ArgoCD GitOps Setup
```
Cấu hình ArgoCD cho eShelf:
1. ArgoCD Application manifests
2. ApplicationSet cho multi-environment
3. Sync policies và auto-sync
4. Notifications configuration
5. RBAC cho team access
```

**✅ Kết quả đạt được:**
- Application: eshelf-staging, eshelf-production
- ApplicationSet: auto-generate apps from Git repo
- Sync policies: automatic, with pruning
- Notifications: Slack, Email on sync status
- RBAC: read/write access cho từng team

**🧪 Cách test:**
```bash
# Apply ArgoCD apps:
kubectl apply -f argocd/apps/

# Check ArgoCD UI:
# → http://localhost:8080
# → Login with admin/password

# Sync application:
argocd app sync eshelf-staging

# Check logs:
kubectl logs -l app.kubernetes.io/instance=eshelf-staging -n eshelf
```

**➡️ Sẵn sàng tiếp theo khi:**
- [ ] Applications synced in ArgoCD
- [ ] Auto-sync hoạt động
- [ ] Notifications nhận được

---