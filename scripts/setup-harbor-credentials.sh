#!/bin/bash

# Harbor Registry Credentials Setup Script
# Creates Kubernetes secrets for Harbor registry access

set -e

HARBOR_REGISTRY=${HARBOR_REGISTRY:-harbor.yourdomain.com}
HARBOR_USERNAME=${HARBOR_USERNAME:-admin}
HARBOR_PASSWORD=${HARBOR_PASSWORD:-}
NAMESPACE=${NAMESPACE:-default}

if [ -z "$HARBOR_PASSWORD" ]; then
    echo "Error: HARBOR_PASSWORD environment variable is required"
    exit 1
fi

echo "Setting up Harbor credentials for registry: $HARBOR_REGISTRY"

# Create docker-registry secret
kubectl create secret docker-registry harbor-registry-secret \
    --docker-server=$HARBOR_REGISTRY \
    --docker-username=$HARBOR_USERNAME \
    --docker-password=$HARBOR_PASSWORD \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Harbor credentials created in namespace: $NAMESPACE"

# Create secret for ArgoCD Image Updater
kubectl create secret generic harbor-creds \
    --from-literal=username=$HARBOR_USERNAME \
    --from-literal=password=$HARBOR_PASSWORD \
    --namespace=argocd \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Harbor credentials created for ArgoCD Image Updater"

