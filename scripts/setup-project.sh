#!/bin/bash

# Setup script for eShelf project
echo "Setting up eShelf project..."
echo "================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

command -v node >/dev/null 2>&1 || { echo "[ERROR] Node.js is required but not installed."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "[ERROR] npm is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "[WARNING] Docker not found. Backend will need manual setup."; }

echo -e "${GREEN}[OK] Prerequisites OK${NC}"
echo ""

# Install frontend dependencies
echo -e "${BLUE}Installing frontend dependencies...${NC}"
npm install
echo -e "${GREEN}[OK] Frontend dependencies installed${NC}"
echo ""

# Setup backend services
echo -e "${BLUE}Setting up backend services...${NC}"

services=("api-gateway" "auth-service" "book-service" "user-service")

for service in "${services[@]}"; do
    echo "  Installing $service..."
    cd "backend/services/$service"
    
    if [ -f ".env.example" ]; then
        if [ ! -f ".env" ]; then
            cp .env.example .env
            echo "    Created .env file"
        fi
    fi
    
    npm install > /dev/null 2>&1
    cd - > /dev/null
done

echo -e "${GREEN}[OK] Backend services setup complete${NC}"
echo ""

# Setup ML service
echo -e "${BLUE}Setting up ML service...${NC}"
if command -v python3 >/dev/null 2>&1; then
    cd backend/services/ml-service
    pip install -r requirements.txt > /dev/null 2>&1
    cd - > /dev/null
    echo -e "${GREEN}[OK] ML service setup complete${NC}"
else
    echo "[WARNING] Python not found. ML service needs manual setup."
fi
echo ""

# Setup database
echo -e "${BLUE}Setting up database...${NC}"
cd backend/database
npm install > /dev/null 2>&1
if [ -f ".env.example" ]; then
    if [ ! -f ".env" ]; then
        cp .env.example .env
        echo "  Created database .env file"
    fi
fi
cd - > /dev/null
echo -e "${GREEN}[OK] Database setup complete${NC}"
echo ""

# Summary
echo "================================"
echo -e "${GREEN}[OK] Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Start frontend:  npm run dev"
echo "  2. Start backend:   cd backend && docker-compose up -d"
echo "  3. Open browser:    http://localhost:5173"
echo ""
echo "See QUICKSTART.md for more details."

