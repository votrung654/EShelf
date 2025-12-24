#!/bin/bash

# Test EC2 Infrastructure
# This script validates Terraform EC2 module

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../../terraform/environments/dev"

echo "=========================================="
echo "Testing EC2 Infrastructure"
echo "=========================================="

cd "$TERRAFORM_DIR"

# Test 1: Check EC2 module exists
echo ""
echo "Test 1: Check EC2 Module"
if [ -f "../../modules/ec2/main.tf" ]; then
    echo "✅ EC2 module exists"
else
    echo "❌ EC2 module not found"
    exit 1
fi

# Test 2: Validate EC2 module
echo ""
echo "Test 2: Validate EC2 Module"
cd ../../modules/ec2
terraform init -backend=false
terraform validate
if [ $? -eq 0 ]; then
    echo "✅ EC2 module validation successful"
else
    echo "❌ EC2 module validation failed"
    exit 1
fi

# Test 3: Check variables
echo ""
echo "Test 3: Check Required Variables"
cd "$TERRAFORM_DIR"
terraform init -backend=false
terraform validate -var="public_key=dummy" -var="create_k3s_cluster=true"
if [ $? -eq 0 ]; then
    echo "✅ EC2 variables validation successful"
else
    echo "❌ EC2 variables validation failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All EC2 tests passed!"
echo "=========================================="

