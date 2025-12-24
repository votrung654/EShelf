#!/bin/bash

# Run All Infrastructure Tests
# This script runs all infrastructure test suites

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Running All Infrastructure Tests"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

# Run Terraform tests
echo "=== Terraform Tests ==="
if [ -f "$SCRIPT_DIR/terraform/test_vpc.sh" ]; then
    bash "$SCRIPT_DIR/terraform/test_vpc.sh" && ((PASSED++)) || ((FAILED++))
fi
if [ -f "$SCRIPT_DIR/terraform/test_ec2.sh" ]; then
    bash "$SCRIPT_DIR/terraform/test_ec2.sh" && ((PASSED++)) || ((FAILED++))
fi
if [ -f "$SCRIPT_DIR/terraform/test_security_groups.sh" ]; then
    bash "$SCRIPT_DIR/terraform/test_security_groups.sh" && ((PASSED++)) || ((FAILED++))
fi

echo ""
echo "=== CloudFormation Tests ==="
if [ -f "$SCRIPT_DIR/cloudformation/test_templates.sh" ]; then
    bash "$SCRIPT_DIR/cloudformation/test_templates.sh" && ((PASSED++)) || ((FAILED++))
fi

echo ""
echo "=== Kubernetes Tests ==="
if [ -f "$SCRIPT_DIR/kubernetes/test_manifests.sh" ]; then
    bash "$SCRIPT_DIR/kubernetes/test_manifests.sh" && ((PASSED++)) || ((FAILED++))
fi

echo ""
echo "=========================================="
echo "Test Results: $PASSED passed, $FAILED failed"
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo "PASS: All tests passed!"
    exit 0
else
    echo "FAIL: Some tests failed"
    exit 1
fi

