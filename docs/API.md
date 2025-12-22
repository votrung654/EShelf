# API Documentation

Complete API documentation for eShelf backend services.

## Base URL

```
Development: http://localhost:3000
Production:  https://api.eshelf.yourdomain.com
```

## Authentication

All protected endpoints require Bearer token in Authorization header:

```
Authorization: Bearer <access_token>
```

---

## Auth Service

### Register

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "username": "johndoe",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Đăng ký thành công",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "username": "johndoe",
      "name": "John Doe",
      "role": "user"
    },
    "accessToken": "eyJhbG...",
    "refreshToken": "eyJhbG..."
  }
}
```

### Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!"
}
```

### Refresh Token

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbG..."
}
```

### Get Current User

```http
GET /api/auth/me
Authorization: Bearer <access_token>
```

---

## Book Service

### Get All Books

```http
GET /api/books?page=1&limit=20&sortBy=title&order=asc
```

**Query Parameters:**
- `page` (number): Page number (default: 1)
- `limit` (number): Items per page (default: 20)
- `sortBy` (string): Sort field (title, year, ratingAvg)
- `order` (string): Sort order (asc, desc)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "isbn": "9780099908401",
      "title": "Book Title",
      "author": ["Author Name"],
      "coverUrl": "/images/cover.jpg",
      "ratingAvg": 4.5,
      "viewCount": 1000
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Search Books

```http
GET /api/books/search?q=harry&genre=Fantasy&year=2020&language=vi
```

**Query Parameters:**
- `q` (string): Search query
- `genre` (string): Filter by genre
- `year` (number): Filter by year
- `language` (string): Filter by language
- `page`, `limit`: Pagination

### Get Book by ID

```http
GET /api/books/:id
```

### Create Book (Admin)

```http
POST /api/books
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "title": "New Book",
  "author": ["Author Name"],
  "description": "Book description",
  "genres": ["Fiction", "Adventure"],
  "year": 2024,
  "pages": 300,
  "language": "vi",
  "coverUrl": "/images/cover.jpg",
  "pdfUrl": "/pdfs/book.pdf"
}
```

### Update Book (Admin)

```http
PUT /api/books/:id
Authorization: Bearer <admin_token>
Content-Type: application/json

{
  "title": "Updated Title",
  "description": "Updated description"
}
```

### Delete Book (Admin)

```http
DELETE /api/books/:id
Authorization: Bearer <admin_token>
```

---

## User Service

### Get Profile

```http
GET /api/profile
Authorization: Bearer <access_token>
```

### Update Profile

```http
PUT /api/profile
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "New Name",
  "bio": "My bio"
}
```

### Get Favorites

```http
GET /api/favorites
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": ["book-id-1", "book-id-2"]
}
```

### Add to Favorites

```http
POST /api/favorites/:bookId
Authorization: Bearer <access_token>
```

### Remove from Favorites

```http
DELETE /api/favorites/:bookId
Authorization: Bearer <access_token>
```

### Get Collections

```http
GET /api/collections
Authorization: Bearer <access_token>
```

### Create Collection

```http
POST /api/collections
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "name": "My Collection",
  "description": "Collection description",
  "isPublic": false
}
```

### Add Book to Collection

```http
POST /api/collections/:collectionId/books/:bookId
Authorization: Bearer <access_token>
```

### Get Reading History

```http
GET /api/reading-history
Authorization: Bearer <access_token>
```

### Save Reading Progress

```http
POST /api/reading-history
Authorization: Bearer <access_token>
Content-Type: application/json

{
  "bookId": "book-id",
  "currentPage": 50,
  "totalPages": 300
}
```

---

## ML Service

### Get Recommendations

```http
POST /api/ml/recommendations
Content-Type: application/json

{
  "user_id": "user-id",
  "n_items": 10,
  "exclude_ids": ["book-id-1"]
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "isbn": "9780099908401",
      "title": "Book Title",
      "author": ["Author"],
      "coverUrl": "/images/cover.jpg",
      "score": 0.95
    }
  ]
}
```

### Get Similar Books

```http
POST /api/ml/similar
Content-Type: application/json

{
  "book_id": "9780099908401",
  "n_items": 6
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "isbn": "isbn",
      "title": "Similar Book",
      "similarity": 0.85
    }
  ]
}
```

### Estimate Reading Time

```http
POST /api/ml/estimate-time
Content-Type: application/json

{
  "pages": 300,
  "genre": "Văn Học"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "minutes": 180,
    "hours": 3.0,
    "formatted": "3h 0m"
  }
}
```

---

## Error Responses

### 400 Bad Request

```json
{
  "success": false,
  "message": "Dữ liệu không hợp lệ",
  "errors": [
    {
      "field": "email",
      "message": "Email không hợp lệ"
    }
  ]
}
```

### 401 Unauthorized

```json
{
  "success": false,
  "message": "Token không hợp lệ",
  "code": "TOKEN_EXPIRED"
}
```

### 403 Forbidden

```json
{
  "success": false,
  "message": "Không có quyền truy cập"
}
```

### 404 Not Found

```json
{
  "success": false,
  "message": "Không tìm thấy tài nguyên"
}
```

### 500 Internal Server Error

```json
{
  "success": false,
  "message": "Lỗi server"
}
```

---

## Rate Limiting

- **Limit:** 100 requests per 15 minutes per IP
- **Headers:**
  - `X-RateLimit-Limit`: Total allowed
  - `X-RateLimit-Remaining`: Remaining requests
  - `X-RateLimit-Reset`: Reset timestamp

**Response when exceeded:**
```json
{
  "success": false,
  "message": "Too many requests"
}
```

---

## Testing with cURL

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123!","username":"testuser"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test123!"}'

# Get books (with token)
curl http://localhost:3000/api/books \
  -H "Authorization: Bearer <token>"
```

---

## Postman Collection

Import the Postman collection for easier testing:

```bash
# Export from Postman or create collection
# File: docs/postman/eShelf.postman_collection.json
```

---

*For more details, see service-specific README files in `backend/services/`*

