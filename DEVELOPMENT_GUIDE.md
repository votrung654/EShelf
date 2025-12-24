# Hướng dẫn phát triển các chức năng còn lại

Tài liệu này mô tả các chức năng còn thiếu và hướng dẫn cách phát triển chúng.

## 1. Reviews & Ratings

### Backend (Book Service)

**Routes cần thêm:**
- `POST /api/books/:bookId/reviews` - Tạo review
- `GET /api/books/:bookId/reviews` - Lấy danh sách reviews
- `PUT /api/reviews/:reviewId` - Cập nhật review
- `DELETE /api/reviews/:reviewId` - Xóa review

**Controller:**
- Tạo `backend/services/book-service/src/controllers/reviewController.js`
- Sử dụng Prisma để lưu vào bảng `Review`
- Validate rating (1-5), content (optional)

**Schema đã có:**
```prisma
model Review {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  bookId    String   @map("book_id")
  rating    Int
  content   String?
  createdAt DateTime @default(now()) @map("created_at")
  updatedAt DateTime @updatedAt @map("updated_at")
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  book Book @relation(fields: [bookId], references: [id], onDelete: Cascade)
  
  @@unique([userId, bookId])
  @@map("reviews")
}
```

### Frontend

**Components cần tạo:**
- `src/components/book/ReviewForm.jsx` - Form để viết review
- `src/components/book/ReviewList.jsx` - Hiển thị danh sách reviews
- `src/components/book/StarRating.jsx` - Component đánh giá sao

**Pages cần cập nhật:**
- `src/pages/BookDetail.jsx` - Thêm section reviews

**API Client:**
- Thêm `reviewsAPI` vào `src/services/api.js`

## 2. Notifications

### Backend (User Service)

**Routes:**
- `GET /api/notifications` - Lấy danh sách notifications
- `PUT /api/notifications/:id/read` - Đánh dấu đã đọc
- `DELETE /api/notifications/:id` - Xóa notification

**Controller:**
- Tạo `backend/services/user-service/src/controllers/notificationController.js`
- Sử dụng Prisma với bảng `Notification`

**Schema đã có:**
```prisma
model Notification {
  id        String   @id @default(uuid())
  userId    String   @map("user_id")
  type      String
  title     String
  message   String
  read      Boolean  @default(false)
  createdAt DateTime @default(now()) @map("created_at")
  
  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  @@map("notifications")
}
```

### Frontend

**Components:**
- `src/components/notification/NotificationBell.jsx` - Icon chuông thông báo
- `src/components/notification/NotificationDropdown.jsx` - Dropdown hiển thị notifications
- `src/pages/Notifications.jsx` - Trang quản lý notifications

## 3. Reading Progress Tracking (Nâng cao)

### Backend

**Cải thiện:**
- Thêm endpoint `GET /api/reading-history/stats` - Thống kê chi tiết
- Thêm endpoint `GET /api/reading-history/streak` - Chuỗi ngày đọc liên tiếp
- Thêm tính toán reading time dựa trên số trang thực tế

### Frontend

**Components:**
- `src/components/reading/ReadingStats.jsx` - Biểu đồ thống kê đọc
- `src/components/reading/ReadingStreak.jsx` - Hiển thị chuỗi ngày đọc
- Cải thiện `src/pages/ReadingHistory.jsx` với filters và sorting

## 4. Advanced Search Filters

### Backend (Book Service)

**Cải thiện `searchBooks` controller:**
- Thêm filter theo rating (min rating)
- Thêm filter theo số trang (min/max pages)
- Thêm filter theo ngôn ngữ (đã có, cần test)
- Thêm sắp xếp (sort by: newest, rating, title, popularity)

### Frontend

**Cải thiện `src/pages/Search.jsx`:**
- Thêm UI cho các filters mới
- Thêm dropdown sắp xếp
- Thêm pagination

## 5. Admin Features

### Backend

**User Service - Admin Routes (đã có, cần test):**
- `GET /api/users` - Lấy danh sách users (với pagination, search)
- `GET /api/users/:id` - Chi tiết user
- `PUT /api/users/:id` - Cập nhật user (role, emailVerified, etc.)
- `DELETE /api/users/:id` - Xóa user

**Book Service - Admin Routes (đã có, cần test):**
- `POST /api/books` - Tạo sách mới
- `PUT /api/books/:id` - Cập nhật sách
- `DELETE /api/books/:id` - Xóa sách

### Frontend

**Admin Pages cần hoàn thiện:**
- `src/admin/pages/AdminUsers.jsx` - Quản lý users (CRUD)
- `src/admin/pages/AdminGenres.jsx` - Quản lý genres
- Cải thiện `src/admin/pages/Dashboard.jsx` - Thêm charts và metrics

## 6. ML/AI Features

### Backend (ML Service)

**Cần implement:**
- `POST /api/ml/estimate-time` - Đã có, cần test
- `POST /api/ml/recommendations` - Đã có, cần cải thiện model
- `POST /api/ml/similar` - Đã có, cần test
- `POST /api/ml/trending` - Sách đang trending (dựa trên views, favorites, reviews)

### Frontend

**Cần tích hợp:**
- Hiển thị "Trending Books" trên HomePage
- Cải thiện UI cho recommendations
- Thêm "People also read" section

## 7. Performance & Optimization

### Backend

- Thêm Redis caching cho:
  - Book search results
  - Genre lists
  - Popular books
- Thêm pagination cho tất cả list endpoints
- Thêm database indexes cho các queries thường dùng

### Frontend

- Implement lazy loading cho images
- Thêm skeleton loaders
- Optimize bundle size (code splitting)
- Implement service worker cho offline support

## 8. Testing

### Backend

**Unit Tests:**
- Controller tests (Jest)
- Service tests
- Middleware tests

**Integration Tests:**
- API endpoint tests
- Database integration tests

### Frontend

**Unit Tests:**
- Component tests (React Testing Library)
- Hook tests
- Utility function tests

**E2E Tests:**
- User flows (Playwright/Cypress)
- Critical paths (login, search, add to collection)

## 9. Security

### Backend

- Rate limiting (đã có, cần fine-tune)
- Input validation (express-validator)
- SQL injection prevention (Prisma đã handle)
- XSS prevention
- CORS configuration (đã có, cần review)

### Frontend

- Input sanitization
- XSS prevention
- Secure token storage
- HTTPS enforcement

## 10. Documentation

- API documentation (Swagger/OpenAPI)
- Component documentation (Storybook)
- Deployment guides
- Troubleshooting guides

## Thứ tự ưu tiên

1. **Reviews & Ratings** - Tính năng cốt lõi cho user engagement
2. **Admin Users Management** - Hoàn thiện admin panel
3. **Advanced Search** - Cải thiện UX
4. **Notifications** - Tăng user retention
5. **ML Features** - Trending books, improved recommendations
6. **Performance** - Redis caching, pagination
7. **Testing** - Đảm bảo chất lượng code
8. **Security** - Hardening
9. **Documentation** - Hỗ trợ phát triển lâu dài

## Lưu ý khi phát triển

1. **Luôn migrate database trước khi thêm features mới:**
   ```bash
   cd backend/database/prisma
   npx prisma migrate dev --name add_feature_name
   ```

2. **Test API endpoints với Postman/Thunder Client trước khi tích hợp frontend**

3. **Follow existing patterns:**
   - Controller structure
   - Error handling
   - Response format (`{ success: true, data: ... }`)

4. **Update API Gateway routes nếu cần**

5. **Update frontend API client (`src/services/api.js`)**

6. **Test với Docker Compose để đảm bảo tất cả services hoạt động**


