# Book Service

Book management service for eShelf platform.

## Features

- Book CRUD operations
- Search and filtering
- Genre management
- Book reviews
- Pagination support

## API Endpoints

### Public Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/books` | Get all books (paginated) |
| GET | `/api/books/search` | Search books |
| GET | `/api/books/featured` | Get featured books |
| GET | `/api/books/popular` | Get popular books |
| GET | `/api/books/:id` | Get book by ID |
| GET | `/api/books/:id/reviews` | Get book reviews |
| GET | `/api/genres` | Get all genres |

### Protected Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/books/:id/reviews` | Add review | User |
| POST | `/api/books` | Create book | Admin |
| PUT | `/api/books/:id` | Update book | Admin |
| DELETE | `/api/books/:id` | Delete book | Admin |

## Setup

```bash
npm install
cp .env.example .env
npm run dev
```

## Docker

```bash
docker build -t eshelf/book-service .
docker run -p 3002:3002 eshelf/book-service
```

