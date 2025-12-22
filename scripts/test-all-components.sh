#!/bin/bash

# ============================================
# eShelf - Comprehensive Component Testing
# Test FE, BE, Database, ML-AI before Ops
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Test results
RESULTS=()

# Helper functions
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

test_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
    RESULTS+=("✅ $1")
}

test_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
    RESULTS+=("❌ $1")
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((WARNINGS++))
    RESULTS+=("⚠️  $1")
}

check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}
    
    response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo -e "\n000")
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        test_pass "$name is running (HTTP $status_code)"
        return 0
    else
        test_fail "$name is not responding (HTTP $status_code)"
        return 1
    fi
}

# ============================================
# 1. FRONTEND TESTING
# ============================================
print_header "1. FRONTEND (React + Vite)"

# Check if frontend is running
if check_service "Frontend" "http://localhost:5173" 200; then
    # Check if it's a React app (has Vite in response or returns HTML)
    if curl -s http://localhost:5173 | grep -q "vite\|react\|root" 2>/dev/null; then
        test_pass "Frontend is serving React application"
    else
        test_warn "Frontend is running but may not be React app"
    fi
else
    test_fail "Frontend is not accessible at http://localhost:5173"
    echo "  → Start with: npm run dev"
fi

# Check frontend build
if [ -d "dist" ] || [ -d "build" ]; then
    test_pass "Frontend build directory exists"
else
    test_warn "Frontend not built yet (run: npm run build)"
fi

# ============================================
# 2. BACKEND SERVICES TESTING
# ============================================
print_header "2. BACKEND SERVICES (Microservices)"

# API Gateway
if check_service "API Gateway" "http://localhost:3000/health" 200; then
    # Test API Gateway routing
    response=$(curl -s http://localhost:3000/health 2>/dev/null || echo "")
    if echo "$response" | grep -q "ok\|status\|gateway" 2>/dev/null; then
        test_pass "API Gateway health endpoint working"
    fi
else
    test_fail "API Gateway not accessible"
    echo "  → Start with: cd backend && docker-compose up -d"
fi

# Auth Service
if check_service "Auth Service" "http://localhost:3001/health" 200; then
    # Test auth endpoints
    response=$(curl -s -X POST http://localhost:3000/api/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"test@test.com","password":"test"}' 2>/dev/null || echo "")
    if echo "$response" | grep -q "error\|success\|invalid" 2>/dev/null; then
        test_pass "Auth Service endpoints are responding"
    fi
else
    test_fail "Auth Service not accessible"
fi

# Book Service
if check_service "Book Service" "http://localhost:3002/health" 200; then
    # Test book endpoints
    response=$(curl -s http://localhost:3000/api/books?limit=1 2>/dev/null || echo "")
    if echo "$response" | grep -q "books\|data\|success" 2>/dev/null; then
        test_pass "Book Service endpoints are responding"
    else
        test_warn "Book Service may not have data yet"
    fi
else
    test_fail "Book Service not accessible"
fi

# User Service
if check_service "User Service" "http://localhost:3003/health" 200; then
    test_pass "User Service is running"
else
    test_fail "User Service not accessible"
fi

# ============================================
# 3. DATABASE TESTING
# ============================================
print_header "3. DATABASE (PostgreSQL + Prisma)"

# Check PostgreSQL connection
if command -v psql >/dev/null 2>&1; then
    if PGPASSWORD=${POSTGRES_PASSWORD:-eshelf123} psql -h localhost -U eshelf -d eshelf -c "SELECT 1;" >/dev/null 2>&1; then
        test_pass "PostgreSQL connection successful"
        
        # Check if tables exist
        table_count=$(PGPASSWORD=${POSTGRES_PASSWORD:-eshelf123} psql -h localhost -U eshelf -d eshelf -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ')
        if [ -n "$table_count" ] && [ "$table_count" -gt 0 ]; then
            test_pass "Database tables exist ($table_count tables)"
        else
            test_warn "No tables found - run migrations: cd backend/database && npm run db:migrate"
        fi
    else
        test_fail "PostgreSQL connection failed"
        echo "  → Check if PostgreSQL is running: docker ps | grep postgres"
        echo "  → Or start with: cd backend && docker-compose up -d postgres"
    fi
else
    # Try Docker exec instead
    if docker ps | grep -q postgres; then
        if docker exec $(docker ps -q -f name=postgres) psql -U eshelf -d eshelf -c "SELECT 1;" >/dev/null 2>&1; then
            test_pass "PostgreSQL connection via Docker successful"
        else
            test_fail "PostgreSQL connection via Docker failed"
        fi
    else
        test_warn "PostgreSQL client not found and container not running"
        echo "  → Install psql or start PostgreSQL container"
    fi
fi

# Check Prisma
if [ -f "backend/database/prisma/schema.prisma" ]; then
    test_pass "Prisma schema file exists"
    
    if [ -d "backend/database/node_modules/.prisma" ] || [ -f "backend/database/node_modules/.prisma/client/package.json" ]; then
        test_pass "Prisma Client generated"
    else
        test_warn "Prisma Client not generated - run: cd backend/database && npm run db:generate"
    fi
else
    test_fail "Prisma schema not found"
fi

# Check Redis (if used)
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli -h localhost ping >/dev/null 2>&1; then
        test_pass "Redis connection successful"
    else
        test_warn "Redis not accessible (optional for caching)"
    fi
else
    # Try Docker exec
    if docker ps | grep -q redis; then
        if docker exec $(docker ps -q -f name=redis) redis-cli ping >/dev/null 2>&1; then
            test_pass "Redis connection via Docker successful"
        else
            test_warn "Redis not responding (optional)"
        fi
    else
        test_warn "Redis not running (optional component)"
    fi
fi

# ============================================
# 4. ML-AI SERVICE TESTING
# ============================================
print_header "4. ML-AI SERVICE (FastAPI)"

# Check ML Service health
if check_service "ML Service" "http://localhost:8000/health" 200; then
    response=$(curl -s http://localhost:8000/health 2>/dev/null || echo "")
    if echo "$response" | grep -q "models\|recommender\|similarity" 2>/dev/null; then
        test_pass "ML Service health check shows models status"
    fi
    
    # Test recommendations endpoint
    rec_response=$(curl -s -X POST http://localhost:8000/recommendations \
        -H "Content-Type: application/json" \
        -d '{"user_id":"test-user","n_items":5}' 2>/dev/null || echo "")
    if echo "$rec_response" | grep -q "success\|data" 2>/dev/null; then
        test_pass "ML Service recommendations endpoint working"
    else
        test_warn "ML Service recommendations may need data"
    fi
    
    # Test similar books endpoint
    similar_response=$(curl -s -X POST http://localhost:8000/similar \
        -H "Content-Type: application/json" \
        -d '{"book_id":"test-book","n_items":5}' 2>/dev/null || echo "")
    if echo "$similar_response" | grep -q "success\|data" 2>/dev/null; then
        test_pass "ML Service similar books endpoint working"
    else
        test_warn "ML Service similar books may need data"
    fi
    
    # Check FastAPI docs
    if curl -s http://localhost:8000/docs >/dev/null 2>&1; then
        test_pass "ML Service API documentation accessible at /docs"
    fi
else
    test_fail "ML Service not accessible"
    echo "  → Start with: cd backend/services/ml-service && uvicorn src.main:app --reload"
fi

# Check Python dependencies
if [ -f "backend/services/ml-service/requirements.txt" ]; then
    test_pass "ML Service requirements.txt exists"
    
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import fastapi, uvicorn, sklearn" 2>/dev/null; then
            test_pass "ML Service Python dependencies installed"
        else
            test_warn "ML Service dependencies not installed - run: pip install -r requirements.txt"
        fi
    else
        test_warn "Python3 not found"
    fi
fi

# ============================================
# 5. INTEGRATION TESTING
# ============================================
print_header "5. INTEGRATION TESTS"

# Test API Gateway -> Services communication
if curl -s http://localhost:3000/health >/dev/null 2>&1; then
    # Test full flow: Frontend -> API Gateway -> Services
    if curl -s http://localhost:3000/api/books?limit=1 >/dev/null 2>&1; then
        test_pass "API Gateway routing to Book Service working"
    fi
    
    if curl -s -X POST http://localhost:3000/api/auth/register \
        -H "Content-Type: application/json" \
        -d '{"email":"test@example.com","password":"Test123!","username":"testuser","name":"Test User"}' >/dev/null 2>&1; then
        test_pass "API Gateway routing to Auth Service working"
    fi
fi

# Test ML Service integration
if curl -s http://localhost:8000/health >/dev/null 2>&1 && curl -s http://localhost:3000/health >/dev/null 2>&1; then
    ml_via_gateway=$(curl -s -X POST http://localhost:3000/api/ml/recommendations \
        -H "Content-Type: application/json" \
        -d '{"user_id":"test","n_items":3}' 2>/dev/null || echo "")
    if echo "$ml_via_gateway" | grep -q "success\|data" 2>/dev/null; then
        test_pass "ML Service accessible via API Gateway"
    else
        test_warn "ML Service may not be configured in API Gateway"
    fi
fi

# ============================================
# SUMMARY
# ============================================
print_header "TEST SUMMARY"

echo ""
echo "Results:"
for result in "${RESULTS[@]}"; do
    echo "  $result"
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "Total Tests: $((PASSED + FAILED + WARNINGS))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo -e "${BLUE}========================================${NC}"

# Exit code
if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ All critical tests passed!${NC}"
    echo -e "${GREEN}Your system is ready for Ops deployment.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed.${NC}"
    echo -e "${YELLOW}Please fix the issues before proceeding to Ops.${NC}"
    exit 1
fi

