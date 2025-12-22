# Deployment Guide

Hướng dẫn triển khai eShelf lên môi trường production.

## Prerequisites

- AWS Account với appropriate permissions
- Terraform >= 1.5
- kubectl configured
- Docker
- Helm 3

## Step 1: Deploy Infrastructure (Lab 1)

### Option A: Terraform

```bash
cd infrastructure/terraform/environments/dev

# Initialize
terraform init

# Create terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars với values của bạn

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Save outputs
terraform output > outputs.txt
```

### Option B: CloudFormation

```bash
cd infrastructure/cloudformation

# Deploy VPC
aws cloudformation create-stack \
  --stack-name eshelf-vpc-dev \
  --template-body file://templates/vpc-stack.yaml

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name eshelf-vpc-dev

# Deploy EC2
aws cloudformation create-stack \
  --stack-name eshelf-ec2-dev \
  --template-body file://templates/ec2-stack.yaml \
  --parameters ParameterKey=KeyPairName,ParameterValue=your-key
```

## Step 2: Setup Kubernetes Cluster

### Option A: EKS (Recommended)

```bash
# Create EKS cluster
eksctl create cluster \
  --name eshelf-cluster \
  --region ap-southeast-1 \
  --nodegroup-name eshelf-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5

# Configure kubectl
aws eks update-kubeconfig \
  --name eshelf-cluster \
  --region ap-southeast-1
```

### Option B: K3s on EC2

```bash
# SSH to bastion
ssh -i key.pem ec2-user@<bastion-ip>

# From bastion, SSH to app servers and install K3s
# Use k3s-ansible playbook (see gopygiangvien.md)
```

## Step 3: Setup Container Registry

### Option A: Harbor

```bash
# Deploy Harbor with Helm
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor \
  --set expose.type=loadBalancer \
  --set externalURL=https://harbor.yourdomain.com
```

### Option B: AWS ECR

```bash
# Create ECR repositories
aws ecr create-repository --repository-name eshelf/api-gateway
aws ecr create-repository --repository-name eshelf/auth-service
aws ecr create-repository --repository-name eshelf/book-service
aws ecr create-repository --repository-name eshelf/user-service
aws ecr create-repository --repository-name eshelf/ml-service
```

## Step 4: Build and Push Images

```bash
# Login to registry
docker login harbor.yourdomain.com
# Or for ECR
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com

# Build and push
cd backend/services/api-gateway
docker build -t harbor.yourdomain.com/eshelf/api-gateway:v1.0.0 .
docker push harbor.yourdomain.com/eshelf/api-gateway:v1.0.0

# Repeat for other services
```

## Step 5: Deploy to Kubernetes

### Using Kustomize

```bash
# Update image references in overlays
cd infrastructure/kubernetes/overlays/prod

# Edit kustomization.yaml with your registry URLs

# Deploy
kubectl apply -k .

# Verify
kubectl get pods -n eshelf
kubectl get services -n eshelf
```

### Using Helm

```bash
cd infrastructure/helm

# Install
helm install eshelf ./eshelf \
  --namespace eshelf \
  --create-namespace \
  -f values-production.yaml

# Upgrade
helm upgrade eshelf ./eshelf \
  -f values-production.yaml
```

## Step 6: Setup ArgoCD (GitOps)

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Create application
argocd app create eshelf \
  --repo https://github.com/levanvux/eShelf.git \
  --path infrastructure/kubernetes/overlays/prod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace eshelf
```

## Step 7: Setup Monitoring

```bash
# Install Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Grafana
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
# Default: admin/prom-operator
```

## Step 8: Configure DNS

```bash
# Get LoadBalancer URL
kubectl get ingress -n eshelf

# Add DNS record in Route 53
# eshelf.yourdomain.com → ALB DNS name
```

## Step 9: Setup SSL/TLS

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
kubectl apply -f infrastructure/kubernetes/cert-issuer.yaml

# Ingress will automatically request certificate
```

## Step 10: Verify Deployment

```bash
# Check all pods running
kubectl get pods -n eshelf

# Check services
kubectl get svc -n eshelf

# Check ingress
kubectl get ingress -n eshelf

# Test endpoints
curl https://eshelf.yourdomain.com/health
```

## Rollback Procedure

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/api-gateway -n eshelf

# Rollback to previous version
kubectl rollout undo deployment/api-gateway -n eshelf

# Rollback to specific revision
kubectl rollout undo deployment/api-gateway --to-revision=2 -n eshelf
```

### ArgoCD Rollback

```bash
# Sync to previous commit
argocd app sync eshelf --revision <previous-commit-hash>

# Or rollback in UI
```

### Terraform Rollback

```bash
# Revert to previous state
terraform state pull > backup.tfstate
terraform apply -state=previous.tfstate
```

## Monitoring Deployment

### Check Logs

```bash
# Pod logs
kubectl logs -f deployment/api-gateway -n eshelf

# All pods in namespace
kubectl logs -f -l app=api-gateway -n eshelf
```

### Check Metrics

```bash
# Access Grafana
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

# View dashboards:
# - Kubernetes Cluster
# - Application Metrics
# - Node Metrics
```

## Troubleshooting

### Pods CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n eshelf

# Describe pod
kubectl describe pod <pod-name> -n eshelf

# Check events
kubectl get events -n eshelf --sort-by='.lastTimestamp'
```

### Service Not Accessible

```bash
# Check service endpoints
kubectl get endpoints -n eshelf

# Port forward for testing
kubectl port-forward svc/api-gateway 3000:3000 -n eshelf

# Check ingress
kubectl describe ingress -n eshelf
```

### Database Connection Issues

```bash
# Check database pod
kubectl get pods -n eshelf | grep postgres

# Check connection from app pod
kubectl exec -it <app-pod> -n eshelf -- sh
# Inside pod:
nc -zv postgres-service 5432
```

## Maintenance

### Update Application

```bash
# Build new image
docker build -t harbor.yourdomain.com/eshelf/api-gateway:v1.1.0 .
docker push harbor.yourdomain.com/eshelf/api-gateway:v1.1.0

# Update manifest (GitOps way)
cd infrastructure/kubernetes/overlays/prod
yq eval '.spec.template.spec.containers[0].image = "harbor.yourdomain.com/eshelf/api-gateway:v1.1.0"' \
  -i api-gateway-deployment.yaml

git add .
git commit -m "chore: update api-gateway to v1.1.0"
git push

# ArgoCD will auto-sync
```

### Scale Services

```bash
# Manual scaling
kubectl scale deployment api-gateway --replicas=5 -n eshelf

# Auto-scaling
kubectl autoscale deployment api-gateway \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n eshelf
```

### Backup Database

```bash
# Backup PostgreSQL
kubectl exec -it postgres-pod -n eshelf -- \
  pg_dump -U eshelf eshelf > backup-$(date +%Y%m%d).sql

# Upload to S3
aws s3 cp backup-$(date +%Y%m%d).sql s3://eshelf-backups/
```

---

*For more details, see [PLAN.md](../PLAN.md)*

