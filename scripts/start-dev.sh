#!/bin/bash

# Start development environment without Docker
echo "Starting eShelf Development Environment..."

# Start API Gateway
echo "Starting API Gateway on port 3000..."
cd backend/services/api-gateway
npm install > /dev/null 2>&1
PORT=3000 npm run dev &

# Start Auth Service
echo "Starting Auth Service on port 3001..."
cd ../auth-service
npm install > /dev/null 2>&1
PORT=3001 npm run dev &

# Start Book Service
echo "Starting Book Service on port 3002..."
cd ../book-service
npm install > /dev/null 2>&1
PORT=3002 npm run dev &

# Start User Service
echo "Starting User Service on port 3003..."
cd ../user-service
npm install > /dev/null 2>&1
PORT=3003 npm run dev &

# Start ML Service
echo "Starting ML Service on port 8000..."
cd ../ml-service
pip install -r requirements.txt > /dev/null 2>&1
uvicorn src.main:app --host 0.0.0.0 --port 8000 &

# Start Frontend
echo "Starting Frontend on port 5173..."
cd ../../../
npm install > /dev/null 2>&1
npm run dev &

echo ""
echo "[OK] All services starting..."
echo ""
echo "URLs:"
echo "   Frontend:    http://localhost:5173"
echo "   API Gateway: http://localhost:3000"
echo ""
echo "Press Ctrl+C to stop all services"
wait


