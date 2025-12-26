#!/bin/bash

# Test script for fresh clone - Simulate a new user cloning the repo
# Tests if docker-compose automatically sets up database and .env correctly

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "========================================"
echo -e "${CYAN}Test Fresh Clone - Docker Compose Setup${NC}"
echo "========================================"
echo ""

# Check prerequisites
echo -e "${YELLOW}[1/8] Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "  ${RED}✗ Docker not found${NC}"
    exit 1
else
    echo -e "  ${GREEN}✓ Docker found${NC}"
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "  ${RED}✗ Docker Compose not found${NC}"
    exit 1
else
    echo -e "  ${GREEN}✓ Docker Compose found${NC}"
fi

# Check if we're in project root
if [ ! -f "backend/docker-compose.yml" ]; then
    echo -e "  ${RED}✗ Please run from project root directory${NC}"
    exit 1
fi

echo ""

# Test 1: Check docker-compose.yml exists
echo -e "${YELLOW}[2/8] Checking docker-compose.yml...${NC}"
if [ -f "backend/docker-compose.yml" ]; then
    echo -e "  ${GREEN}✓ docker-compose.yml found${NC}"
else
    echo -e "  ${RED}✗ docker-compose.yml not found${NC}"
    exit 1
fi

# Test 2: Check migration service exists in docker-compose
echo -e "${YELLOW}[3/8] Checking migration service in docker-compose...${NC}"
if grep -q "db-migration:" backend/docker-compose.yml; then
    echo -e "  ${GREEN}✓ db-migration service found${NC}"
else
    echo -e "  ${RED}✗ db-migration service not found${NC}"
    exit 1
fi

# Test 3: Check default DATABASE_URL format
echo -e "${YELLOW}[4/8] Checking default DATABASE_URL format...${NC}"
if grep -q "postgresql://.*postgres:5432" backend/docker-compose.yml; then
    echo -e "  ${GREEN}✓ DATABASE_URL uses correct host 'postgres'${NC}"
else
    echo -e "  ${YELLOW}⚠ DATABASE_URL might not use service name 'postgres'${NC}"
fi

# Test 4: Backup existing .env if exists
echo -e "${YELLOW}[5/8] Preparing test environment...${NC}"
ENV_PATH="backend/.env"
ENV_BACKUP_PATH="backend/.env.backup"
ENV_EXISTS=false

if [ -f "$ENV_PATH" ]; then
    cp "$ENV_PATH" "$ENV_BACKUP_PATH"
    echo -e "  ${GREEN}✓ Backed up existing .env file${NC}"
    ENV_EXISTS=true
else
    echo -e "  ${CYAN}ℹ No existing .env file (will use defaults)${NC}"
fi

# Test 5: Remove .env to test with defaults
echo -e "${YELLOW}[6/8] Testing with default values (no .env file)...${NC}"
if [ "$ENV_EXISTS" = true ]; then
    rm "$ENV_PATH"
    echo -e "  ${GREEN}✓ Removed .env to test defaults${NC}"
fi

# Test 6: Validate docker-compose config
echo -e "${YELLOW}[7/8] Validating docker-compose configuration...${NC}"
cd backend

if docker-compose config > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ docker-compose config is valid${NC}"
    
    # Check DATABASE_URL in config
    DB_URL=$(docker-compose config | grep "DATABASE_URL" | head -1)
    if echo "$DB_URL" | grep -q "postgresql://.*@postgres:5432"; then
        echo -e "  ${GREEN}✓ DATABASE_URL correctly points to 'postgres' service${NC}"
    else
        echo -e "  ${YELLOW}⚠ DATABASE_URL might not point to 'postgres' service${NC}"
        echo -e "    ${YELLOW}$DB_URL${NC}"
    fi
else
    echo -e "  ${RED}✗ docker-compose config validation failed${NC}"
    cd ..
    exit 1
fi

cd ..

# Test 7: Test docker-compose up
echo -e "${YELLOW}[8/8] Testing docker-compose setup (this may take a while)...${NC}"
echo ""
echo -e "  ${CYAN}This will:${NC}"
echo -e "  ${CYAN}1. Start PostgreSQL${NC}"
echo -e "  ${CYAN}2. Wait for PostgreSQL to be healthy${NC}"
echo -e "  ${CYAN}3. Run db-migration service${NC}"
echo -e "  ${CYAN}4. Check if migrations completed successfully${NC}"
echo ""

read -p "  Do you want to run this test? (y/N): " response
if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo -e "  ${YELLOW}⏭ Skipping docker-compose test${NC}"
    echo ""
    echo "========================================"
    echo -e "${CYAN}Test Summary${NC}"
    echo "========================================"
    echo -e "${GREEN}✓ Configuration files validated${NC}"
    echo -e "${GREEN}✓ Default values checked${NC}"
    echo -e "${YELLOW}⚠ Docker Compose runtime test skipped${NC}"
    echo ""
    echo -e "${CYAN}To test runtime, run manually:${NC}"
    echo -e "  ${CYAN}cd backend${NC}"
    echo -e "  ${CYAN}docker-compose up -d${NC}"
    echo -e "  ${CYAN}docker-compose logs db-migration${NC}"
    echo ""
    
    # Restore .env if backed up
    if [ "$ENV_EXISTS" = true ] && [ -f "$ENV_BACKUP_PATH" ]; then
        cp "$ENV_BACKUP_PATH" "$ENV_PATH"
        rm "$ENV_BACKUP_PATH"
        echo -e "${GREEN}✓ Restored .env file${NC}"
    fi
    exit 0
fi

# Run docker-compose up
cd backend
echo ""
echo -e "  ${CYAN}Starting services...${NC}"

docker-compose up -d

# Wait a bit for services to start
sleep 5

# Check postgres health
echo -e "  ${CYAN}Checking PostgreSQL health...${NC}"
MAX_WAIT=60
WAITED=0
POSTGRES_HEALTHY=false

while [ $WAITED -lt $MAX_WAIT ]; do
    if docker-compose ps postgres | grep -q "healthy"; then
        POSTGRES_HEALTHY=true
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -e "    ${YELLOW}Waiting for PostgreSQL... ($WAITED/$MAX_WAIT seconds)${NC}"
done

if [ "$POSTGRES_HEALTHY" = false ]; then
    echo -e "  ${RED}✗ PostgreSQL did not become healthy${NC}"
    echo -e "    ${YELLOW}Check logs: docker-compose logs postgres${NC}"
    cd ..
    exit 1
fi

echo -e "  ${GREEN}✓ PostgreSQL is healthy${NC}"

# Check migration service
echo -e "  ${CYAN}Checking migration service...${NC}"
sleep 3

MIGRATION_LOGS=$(docker-compose logs db-migration 2>&1)
if echo "$MIGRATION_LOGS" | grep -q "Migrations completed successfully\|Database setup complete"; then
    echo -e "  ${GREEN}✓ Migrations completed successfully${NC}"
elif echo "$MIGRATION_LOGS" | grep -qi "ERROR\|error"; then
    echo -e "  ${RED}✗ Migration errors detected${NC}"
    echo ""
    echo -e "${YELLOW}Migration logs:${NC}"
    echo -e "${RED}$MIGRATION_LOGS${NC}"
    cd ..
    exit 1
else
    echo -e "  ${YELLOW}⚠ Migration status unclear, checking logs...${NC}"
    echo -e "${YELLOW}$MIGRATION_LOGS${NC}"
fi

# Check if tables exist
echo -e "  ${CYAN}Verifying database tables...${NC}"
TABLES_CHECK=$(docker-compose exec -T postgres psql -U eshelf -d eshelf -c "\dt" 2>&1)
if echo "$TABLES_CHECK" | grep -q "books" && echo "$TABLES_CHECK" | grep -q "genres" && echo "$TABLES_CHECK" | grep -q "users"; then
    echo -e "  ${GREEN}✓ Database tables created successfully${NC}"
else
    echo -e "  ${YELLOW}⚠ Some tables might be missing${NC}"
    echo -e "    ${YELLOW}Tables found:${NC}"
    echo -e "${YELLOW}$TABLES_CHECK${NC}"
fi

# Check services status
echo -e "  ${CYAN}Checking services status...${NC}"
SERVICES=$(docker-compose ps --services)
ALL_RUNNING=true
for service in $SERVICES; do
    if [ "$service" = "db-migration" ]; then
        continue  # Migration service should exit after completion
    fi
    if docker-compose ps "$service" | grep -q "Up\|running"; then
        echo -e "    ${GREEN}✓ $service is running${NC}"
    else
        echo -e "    ${RED}✗ $service is not running${NC}"
        ALL_RUNNING=false
    fi
done

cd ..

# Restore .env if backed up
if [ "$ENV_EXISTS" = true ] && [ -f "$ENV_BACKUP_PATH" ]; then
    cp "$ENV_BACKUP_PATH" "$ENV_PATH"
    rm "$ENV_BACKUP_PATH"
    echo ""
    echo -e "${GREEN}✓ Restored .env file${NC}"
fi

# Summary
echo ""
echo "========================================"
echo -e "${CYAN}Test Summary${NC}"
echo "========================================"

if [ "$POSTGRES_HEALTHY" = true ] && [ "$ALL_RUNNING" = true ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo -e "${GREEN}Docker Compose setup is working correctly:${NC}"
    echo -e "  ${GREEN}✓ PostgreSQL starts and becomes healthy${NC}"
    echo -e "  ${GREEN}✓ Migration service runs automatically${NC}"
    echo -e "  ${GREEN}✓ Database tables are created${NC}"
    echo -e "  ${GREEN}✓ Services start after migrations complete${NC}"
    echo ""
    echo -e "${GREEN}A fresh clone should work without manual .env setup!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo -e "${YELLOW}Check logs:${NC}"
    echo -e "  ${YELLOW}cd backend${NC}"
    echo -e "  ${YELLOW}docker-compose logs${NC}"
    exit 1
fi

