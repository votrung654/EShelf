#!/bin/bash

# Start all backend services
echo "🚀 Starting eShelf Backend Services..."

# Start with Docker Compose
cd backend
docker-compose up -d

echo "✅ All services started!"
echo ""
echo "📍 Service URLs:"
echo "   API Gateway:  http://localhost:3000"
echo "   Auth Service: http://localhost:3001"
echo "   Book Service: http://localhost:3002"
echo "   User Service: http://localhost:3003"
echo "   ML Service:   http://localhost:8000"
echo "   ML Docs:      http://localhost:8000/docs"
echo ""
echo "📊 Health checks:"
echo "   curl http://localhost:3000/health"


