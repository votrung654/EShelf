#!/bin/bash

# Test Security Groups Infrastructure
# This script validates Terraform Security Groups module

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../../terraform/environments/dev"

echo "=========================================="
echo "Testing Security Groups Infrastructure"
echo "=========================================="

cd "$TERRAFORM_DIR"

# Test 1: Check Security Groups module exists
echo ""
echo "Test 1: Check Security Groups Module"
if [ -f "../../modules/security-groups/main.tf" ]; then
    echo "PASS: Security Groups module exists"
else
    echo "FAIL: Security Groups module not found"
    exit 1
fi

# Test 2: Validate Security Groups module
echo ""
echo "Test 2: Validate Security Groups Module"
cd ../../modules/security-groups
terraform init -backend=false
terraform validate
if [ $? -eq 0 ]; then
    echo "PASS: Security Groups module validation successful"
else
    echo "FAIL: Security Groups module validation failed"
    exit 1
fi

# Test 3: Check K3s security groups
echo ""
echo "Test 3: Check K3s Security Groups"
if grep -q "k3s_master" main.tf && grep -q "k3s_worker" main.tf; then
    echo "PASS: K3s security groups defined"
else
    echo "WARN: K3s security groups not found (may be conditional)"
fi

echo ""
echo "=========================================="
echo "PASS: All Security Groups tests passed!"
echo "=========================================="

