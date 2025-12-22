# eShelf Backend Services

Microservices architecture for eShelf platform.

## Services Overview

| Service | Port | Description |
|---------|------|-------------|
| API Gateway | 3000 | API routing, rate limiting, CORS |
| Auth Service | 3001 | JWT authentication, user registration |
| Book Service | 3002 | Book CRUD, search, reviews |
| User Service | 3003 | Profile, favorites, collections, history |
| ML Service | 8000 | Recommendations, similarity, predictions |

## Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Option 2: Manual Start

Each service in separate terminal:

```bash
# Auth Service
cd services/auth-service
npm install && npm run dev

# Book Service
cd services/book-service
npm install && npm run dev

# User Service
cd services/user-service
npm install && npm run dev

# ML Service
cd services/ml-service
pip install -r requirements.txt
uvicorn src.main:app --reload
```

## Environment Setup

Each service needs a `.env` file. Copy from `.env.example`:

```bash
# For each service
cd services/auth-service
cp .env.example .env

cd services/book-service
cp .env.example .env

# ... repeat for other services
```

## Database Setup

```bash
cd database
npm install

# Generate Prisma Client
npm run db:generate

# Run migrations
npm run db:migrate

# Seed data
npm run db:seed
```

## Health Checks

```bash
curl http://localhost:3000/health  # API Gateway
curl http://localhost:3001/health  # Auth Service
curl http://localhost:3002/health  # Book Service
curl http://localhost:3003/health  # User Service
curl http://localhost:8000/health  # ML Service
```

## Architecture

```
API Gateway (3000)
    ├── /api/auth → Auth Service (3001)
    ├── /api/books → Book Service (3002)
    ├── /api/genres → Book Service (3002)
    ├── /api/profile → User Service (3003)
    ├── /api/favorites → User Service (3003)
    ├── /api/collections → User Service (3003)
    ├── /api/reading-history → User Service (3003)
    └── /api/ml → ML Service (8000)
```

## Development

### Adding New Service

1. Create service directory: `services/new-service/`
2. Add to `docker-compose.yml`
3. Add routes to API Gateway
4. Update this README

### Running Tests

```bash
# Run tests for specific service
cd services/auth-service
npm test

# Run all tests
npm run test:all
```

## Troubleshooting

### Port already in use

```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### Docker issues

```bash
# Rebuild containers
docker-compose up -d --build

# Remove all containers and volumes
docker-compose down -v

# Clean Docker system
docker system prune -a
```

## Production Deployment

See [PLAN.md](../PLAN.md) for Kubernetes deployment instructions.

