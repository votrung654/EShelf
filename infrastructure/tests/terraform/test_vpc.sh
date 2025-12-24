#!/bin/bash

# Test VPC Infrastructure
# This script validates Terraform VPC module

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../../terraform/environments/dev"

echo "=========================================="
echo "Testing VPC Infrastructure"
echo "=========================================="

cd "$TERRAFORM_DIR"

# Test 1: Terraform Init
echo ""
echo "Test 1: Terraform Init"
terraform init -backend=false
if [ $? -eq 0 ]; then
    echo "PASS: Terraform init successful"
else
    echo "FAIL: Terraform init failed"
    exit 1
fi

# Test 2: Terraform Validate
echo ""
echo "Test 2: Terraform Validate"
terraform validate
if [ $? -eq 0 ]; then
    echo "PASS: Terraform validate successful"
else
    echo "FAIL: Terraform validate failed"
    exit 1
fi

# Test 3: Terraform Format Check
echo ""
echo "Test 3: Terraform Format Check"
terraform fmt -check -recursive
if [ $? -eq 0 ]; then
    echo "PASS: Terraform format check passed"
else
    echo "WARN: Terraform format check failed (run 'terraform fmt' to fix)"
fi

# Test 4: Terraform Plan (dry-run)
echo ""
echo "Test 4: Terraform Plan (dry-run)"
terraform plan -var="public_key=dummy" -input=false -out=tfplan
if [ $? -eq 0 ]; then
    echo "PASS: Terraform plan successful"
    rm -f tfplan
else
    echo "FAIL: Terraform plan failed"
    exit 1
fi

echo ""
echo "=========================================="
echo "PASS: All VPC tests passed!"
echo "=========================================="

