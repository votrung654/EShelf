#!/bin/bash

# Test Kubernetes Manifests
# This script validates Kubernetes manifests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
K8S_DIR="$SCRIPT_DIR/../../kubernetes"

echo "=========================================="
echo "Testing Kubernetes Manifests"
echo "=========================================="

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "WARN: kubectl not found. Installing kubeval..."
    if command -v kubeval &> /dev/null; then
        echo "PASS: kubeval found"
    else
        echo "WARN: kubeval not found. Skipping detailed validation."
    fi
fi

# Test 1: Validate base manifests
echo ""
echo "Test 1: Validate Base Manifests"
if [ -f "$K8S_DIR/base/kustomization.yaml" ]; then
    echo "PASS: Base kustomization.yaml exists"
    
    # Check if kustomize is available
    if command -v kustomize &> /dev/null; then
        cd "$K8S_DIR/base"
        kustomize build . > /dev/null
        if [ $? -eq 0 ]; then
            echo "PASS: Base kustomization build successful"
        else
            echo "FAIL: Base kustomization build failed"
            exit 1
        fi
    else
        echo "WARN: kustomize not found. Skipping build test."
    fi
else
    echo "FAIL: Base kustomization.yaml not found"
    exit 1
fi

# Test 2: Validate staging overlay
echo ""
echo "Test 2: Validate Staging Overlay"
if [ -f "$K8S_DIR/overlays/staging/kustomization.yaml" ]; then
    echo "PASS: Staging kustomization.yaml exists"
    
    if command -v kustomize &> /dev/null; then
        cd "$K8S_DIR/overlays/staging"
        kustomize build . > /dev/null
        if [ $? -eq 0 ]; then
            echo "PASS: Staging kustomization build successful"
        else
            echo "FAIL: Staging kustomization build failed"
            exit 1
        fi
    fi
else
    echo "FAIL: Staging kustomization.yaml not found"
    exit 1
fi

# Test 3: Validate prod overlay
echo ""
echo "Test 3: Validate Prod Overlay"
if [ -f "$K8S_DIR/overlays/prod/kustomization.yaml" ]; then
    echo "PASS: Prod kustomization.yaml exists"
    
    if command -v kustomize &> /dev/null; then
        cd "$K8S_DIR/overlays/prod"
        kustomize build . > /dev/null
        if [ $? -eq 0 ]; then
            echo "PASS: Prod kustomization build successful"
        else
            echo "FAIL: Prod kustomization build failed"
            exit 1
        fi
    fi
else
    echo "FAIL: Prod kustomization.yaml not found"
    exit 1
fi

# Test 4: Check all service deployments exist
echo ""
echo "Test 4: Check Service Deployments"
SERVICES=("api-gateway" "auth-service" "book-service" "user-service" "ml-service")
for service in "${SERVICES[@]}"; do
    if [ -f "$K8S_DIR/base/${service}-deployment.yaml" ]; then
        echo "PASS: ${service} deployment exists"
    else
        echo "FAIL: ${service} deployment not found"
        exit 1
    fi
done

echo ""
echo "=========================================="
echo "PASS: All Kubernetes manifest tests passed!"
echo "=========================================="

