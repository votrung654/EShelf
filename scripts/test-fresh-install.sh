#!/bin/bash

# Test script for fresh installation
# Simulates a new user cloning and setting up the project

set -e

echo "=========================================="
echo "Testing Fresh Installation"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

command -v node >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Node.js is required but not installed.${NC}"; exit 1; }
command -v npm >/dev/null 2>&1 || { echo -e "${RED}[ERROR] npm is required but not installed.${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${YELLOW}[WARNING] Docker not found. Backend will need manual setup.${NC}"; }
command -v docker-compose >/dev/null 2>&1 || { echo -e "${YELLOW}[WARNING] Docker Compose not found. Backend will need manual setup.${NC}"; }

NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}[ERROR] Node.js version must be >= 18. Current: $(node -v)${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Prerequisites OK${NC}"
echo ""

# Check if we're in the project root
if [ ! -f "package.json" ]; then
    echo -e "${RED}[ERROR] Please run this script from the project root directory${NC}"
    exit 1
fi

# Test 1: Frontend dependencies
echo -e "${YELLOW}Test 1: Installing frontend dependencies...${NC}"
if npm install --silent; then
    echo -e "${GREEN}[OK] Frontend dependencies installed${NC}"
else
    echo -e "${RED}[FAIL] Frontend dependencies installation failed${NC}"
    exit 1
fi
echo ""

# Test 2: Backend services structure
echo -e "${YELLOW}Test 2: Checking backend services structure...${NC}"
SERVICES=("api-gateway" "auth-service" "book-service" "user-service")
for service in "${SERVICES[@]}"; do
    if [ -d "backend/services/$service" ]; then
        if [ -f "backend/services/$service/package.json" ]; then
            echo -e "${GREEN}[OK] $service structure valid${NC}"
        else
            echo -e "${RED}[FAIL] $service/package.json missing${NC}"
            exit 1
        fi
    else
        echo -e "${RED}[FAIL] $service directory missing${NC}"
        exit 1
    fi
done
echo ""

# Test 3: Docker Compose file
echo -e "${YELLOW}Test 3: Checking Docker Compose configuration...${NC}"
if [ -f "backend/docker-compose.yml" ]; then
    echo -e "${GREEN}[OK] docker-compose.yml found${NC}"
else
    echo -e "${RED}[FAIL] docker-compose.yml missing${NC}"
    exit 1
fi
echo ""

# Test 4: Database schema
echo -e "${YELLOW}Test 4: Checking database schema...${NC}"
if [ -f "backend/database/prisma/schema.prisma" ]; then
    echo -e "${GREEN}[OK] Prisma schema found${NC}"
else
    echo -e "${RED}[FAIL] Prisma schema missing${NC}"
    exit 1
fi
echo ""

# Test 5: ML Service
echo -e "${YELLOW}Test 5: Checking ML Service...${NC}"
if [ -f "backend/services/ml-service/requirements.txt" ]; then
    echo -e "${GREEN}[OK] ML Service structure valid${NC}"
else
    echo -e "${RED}[FAIL] ML Service requirements.txt missing${NC}"
    exit 1
fi
echo ""

# Test 6: Frontend structure
echo -e "${YELLOW}Test 6: Checking frontend structure...${NC}"
if [ -d "src" ] && [ -f "src/main.jsx" ] && [ -f "vite.config.js" ]; then
    echo -e "${GREEN}[OK] Frontend structure valid${NC}"
else
    echo -e "${RED}[FAIL] Frontend structure invalid${NC}"
    exit 1
fi
echo ""

# Test 7: Documentation files
echo -e "${YELLOW}Test 7: Checking documentation...${NC}"
DOCS=("README.md" "SETUP.md" "DEVELOPMENT_GUIDE.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}[OK] $doc found${NC}"
    else
        echo -e "${YELLOW}[WARNING] $doc missing${NC}"
    fi
done
echo ""

# Test 8: Docker build (if Docker is available)
if command -v docker >/dev/null 2>&1 && command -v docker-compose >/dev/null 2>&1; then
    echo -e "${YELLOW}Test 8: Testing Docker Compose build (dry-run)...${NC}"
    cd backend
    if docker-compose config >/dev/null 2>&1; then
        echo -e "${GREEN}[OK] Docker Compose configuration valid${NC}"
    else
        echo -e "${RED}[FAIL] Docker Compose configuration invalid${NC}"
        cd ..
        exit 1
    fi
    cd ..
    echo ""
fi

# Summary
echo "=========================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start backend: cd backend && docker-compose up -d"
echo "2. Start frontend: npm run dev"
echo "3. Open browser: http://localhost:5173"
echo ""

