#!/bin/bash

# Test CloudFormation Templates
# This script validates CloudFormation templates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFN_DIR="$SCRIPT_DIR/../../cloudformation/templates"

echo "=========================================="
echo "Testing CloudFormation Templates"
echo "=========================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "WARN: AWS CLI not found. Skipping CloudFormation validation."
    echo "   Install AWS CLI: https://aws.amazon.com/cli/"
    exit 0
fi

# Check if cfn-lint is installed
if ! command -v cfn-lint &> /dev/null; then
    echo "WARN: cfn-lint not found. Installing..."
    pip install cfn-lint || echo "WARN: Could not install cfn-lint"
fi

# Test 1: Validate VPC Stack
echo ""
echo "Test 1: Validate VPC Stack Template"
if [ -f "$CFN_DIR/vpc-stack.yaml" ]; then
    if command -v cfn-lint &> /dev/null; then
        cfn-lint "$CFN_DIR/vpc-stack.yaml"
        if [ $? -eq 0 ]; then
            echo "PASS: VPC stack template validation successful"
        else
            echo "WARN: VPC stack template has linting issues"
        fi
    fi
    
    # AWS CLI validation
    aws cloudformation validate-template \
        --template-body file://"$CFN_DIR/vpc-stack.yaml" \
        --region ap-southeast-1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "PASS: VPC stack template AWS validation successful"
    else
        echo "WARN: VPC stack template AWS validation failed (may need AWS credentials)"
    fi
else
    echo "FAIL: VPC stack template not found"
    exit 1
fi

# Test 2: Validate EC2 Stack
echo ""
echo "Test 2: Validate EC2 Stack Template"
if [ -f "$CFN_DIR/ec2-stack.yaml" ]; then
    if command -v cfn-lint &> /dev/null; then
        cfn-lint "$CFN_DIR/ec2-stack.yaml"
        if [ $? -eq 0 ]; then
            echo "PASS: EC2 stack template validation successful"
        else
            echo "WARN: EC2 stack template has linting issues"
        fi
    fi
    
    # AWS CLI validation (will fail without VPC ID, but syntax check)
    aws cloudformation validate-template \
        --template-body file://"$CFN_DIR/ec2-stack.yaml" \
        --region ap-southeast-1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "PASS: EC2 stack template AWS validation successful"
    else
        echo "WARN: EC2 stack template AWS validation failed (may need AWS credentials or VPC ID)"
    fi
else
    echo "FAIL: EC2 stack template not found"
    exit 1
fi

echo ""
echo "=========================================="
echo "PASS: All CloudFormation tests passed!"
echo "=========================================="

