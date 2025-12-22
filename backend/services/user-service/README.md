# User Service

User management service for eShelf platform.

## Features

- User profile management
- Favorites management
- Collections (custom book lists)
- Reading history tracking
- Reading progress

## API Endpoints

All endpoints require authentication (Bearer token).

### Profile

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/profile` | Get user profile |
| PUT | `/api/profile` | Update profile |
| PUT | `/api/profile/avatar` | Update avatar |
| GET | `/api/profile/stats` | Get user statistics |

### Favorites

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/favorites` | Get all favorites |
| POST | `/api/favorites/:bookId` | Add to favorites |
| DELETE | `/api/favorites/:bookId` | Remove from favorites |
| GET | `/api/favorites/check/:bookId` | Check if favorited |

### Collections

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/collections` | Get all collections |
| POST | `/api/collections` | Create collection |
| GET | `/api/collections/:id` | Get collection details |
| PUT | `/api/collections/:id` | Update collection |
| DELETE | `/api/collections/:id` | Delete collection |
| POST | `/api/collections/:id/books/:bookId` | Add book to collection |
| DELETE | `/api/collections/:id/books/:bookId` | Remove book |

### Reading History

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/reading-history` | Get reading history |
| POST | `/api/reading-history` | Save reading progress |
| GET | `/api/reading-history/:bookId` | Get book progress |
| DELETE | `/api/reading-history/:bookId` | Delete book history |

## Setup

```bash
npm install
npm run dev
```

