# Auth Service

Authentication service for eShelf platform.

## Features

- User registration with validation
- JWT-based authentication (access + refresh tokens)
- Password hashing with bcrypt
- Token refresh mechanism
- Password reset flow

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login user |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/logout` | Logout user |
| POST | `/api/auth/forgot-password` | Request password reset |
| POST | `/api/auth/reset-password` | Reset password |
| GET | `/api/auth/me` | Get current user |

## Setup

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Edit .env with your values
# Start service
npm run dev
```

## Environment Variables

```env
PORT=3001
NODE_ENV=development
JWT_SECRET=your-secret-key
JWT_REFRESH_SECRET=your-refresh-secret
ALLOWED_ORIGINS=http://localhost:5173
```

## Docker

```bash
docker build -t eshelf/auth-service .
docker run -p 3001:3001 --env-file .env eshelf/auth-service
```

