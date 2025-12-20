# eShelf API Gateway

API Gateway service for eShelf platform with rate limiting, validation, and security middleware.

## Quick Start

```bash
# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Start development server
npm run dev

# Start production server
npm start
```

## Troubleshooting

### Port Already in Use

If you see `EADDRINUSE` error:

**Windows:**
```bash
# Find process using port 3000
netstat -ano | findstr :3000

# Kill the process (replace <PID> with actual PID)
taskkill /PID <PID> /F
```

**Linux/Mac:**
```bash
# Kill process using port 3000
lsof -ti:3000 | xargs kill -9
```

**Or use a different port:**
```bash
PORT=3001 npm run dev
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 3000 | Server port |
| NODE_ENV | development | Environment |
| RATE_LIMIT_WINDOW_MS | 900000 | Rate limit window (15 min) |
| RATE_LIMIT_MAX_REQUESTS | 100 | Max requests per window |
| ALLOWED_ORIGINS | localhost:5173 | CORS allowed origins |

## Testing

```bash
# Health check
curl http://localhost:3000/health

# API info
curl http://localhost:3000/

# Test rate limiting (>100 requests)
for i in {1..105}; do curl -s http://localhost:3000/health; done
```

## Docker

```bash
# Build image
docker build -t eshelf/api-gateway .

# Run container
docker run -p 3000:3000 --env-file .env eshelf/api-gateway

# Check health
docker ps  # Should show "healthy" status
```

## Features

- ✅ Express.js server
- ✅ CORS configuration
- ✅ Helmet security headers
- ✅ Morgan HTTP logger
- ✅ Rate limiting (100 req/15min)
- ✅ Zod request validation
- ✅ Centralized error handling
- ✅ Health check endpoints
- ✅ Multi-stage Dockerfile
