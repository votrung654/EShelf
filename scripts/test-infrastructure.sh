#!/bin/bash

# Infrastructure Test Cases for Lab 1
echo "🧪 Running Infrastructure Tests..."
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Test function
test_case() {
    local name=$1
    local command=$2
    
    echo -n "Testing: $name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}[PASS]${NC}"
        ((PASS++))
    else
        echo -e "${RED}[FAIL]${NC}"
        ((FAIL++))
    fi
}

# VPC Tests
echo ""
echo "=== VPC Tests ==="
test_case "Terraform initialized" "terraform -chdir=infrastructure/terraform/environments/dev init -backend=false"
test_case "Terraform validate" "terraform -chdir=infrastructure/terraform/environments/dev validate"
test_case "Terraform format" "terraform -chdir=infrastructure/terraform/environments/dev fmt -check -recursive"

# Module Tests
echo ""
echo "=== Module Tests ==="
test_case "VPC module exists" "test -f infrastructure/terraform/modules/vpc/main.tf"
test_case "EC2 module exists" "test -f infrastructure/terraform/modules/ec2/main.tf"
test_case "Security Groups module exists" "test -f infrastructure/terraform/modules/security-groups/main.tf"

# Docker Tests
echo ""
echo "=== Docker Tests ==="
test_case "API Gateway Dockerfile" "docker build -t test-api-gateway backend/services/api-gateway"
test_case "Auth Service Dockerfile" "docker build -t test-auth-service backend/services/auth-service"
test_case "Book Service Dockerfile" "docker build -t test-book-service backend/services/book-service"

# Results
echo ""
echo "=================================="
echo "Test Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi


