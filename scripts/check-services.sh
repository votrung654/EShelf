#!/bin/bash

# Check all eShelf services health
echo "Checking eShelf services health..."
echo "====================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

check_service() {
    local name=$1
    local url=$2
    
    echo -n "Checking $name... "
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}[OK]${NC}"
        return 0
    else
        echo -e "${RED}[DOWN]${NC}"
        return 1
    fi
}

# Check services
check_service "Frontend       " "http://localhost:5173"
check_service "API Gateway    " "http://localhost:3000/health"
check_service "Auth Service   " "http://localhost:3001/health"
check_service "Book Service   " "http://localhost:3002/health"
check_service "User Service   " "http://localhost:3003/health"
check_service "ML Service     " "http://localhost:8000/health"

echo ""
echo "====================================="

# Check Docker containers if using Docker Compose
if command -v docker >/dev/null 2>&1; then
    echo ""
    echo "Docker containers:"
    docker ps --filter "name=backend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No Docker containers running"
fi

echo ""
echo "Full service info:"
echo "  Frontend:     http://localhost:5173"
echo "  API Gateway:  http://localhost:3000"
echo "  ML API Docs:  http://localhost:8000/docs"

