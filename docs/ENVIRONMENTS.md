# Multi-Environment Deployment Guide

## Tổng quan

Project eShelf hỗ trợ 3 môi trường deployment:
- **Development (dev)**: Môi trường phát triển, ít replicas, debug mode
- **Staging**: Môi trường test trước production, gần giống production
- **Production (prod)**: Môi trường chính thức, nhiều replicas, tối ưu performance

## Cấu trúc

```
infrastructure/kubernetes/
├── base/                    # Base configuration (shared)
│   ├── frontend-deployment.yaml
│   ├── api-gateway-deployment.yaml
│   ├── auth-service-deployment.yaml
│   ├── book-service-deployment.yaml
│   ├── user-service-deployment.yaml
│   ├── ml-service-deployment.yaml
│   └── ingress.yaml
└── overlays/
    ├── dev/                 # Development environment
    │   ├── kustomization.yaml
    │   └── ingress-patch.yaml
    ├── staging/             # Staging environment
    │   ├── kustomization.yaml
    │   ├── ingress-patch.yaml
    │   └── *-patch.yaml (resource patches)
    └── prod/                # Production environment
        ├── kustomization.yaml
        ├── ingress-patch.yaml
        └── *-patch.yaml (resource patches)
```

## So sánh các môi trường

| Feature | Development | Staging | Production |
|---------|------------|---------|------------|
| **Namespace** | `eshelf-dev` | `eshelf-staging` | `eshelf-prod` |
| **Frontend Replicas** | 1 | 1 | 2 |
| **API Gateway Replicas** | 1 | 2 | 3 |
| **Backend Replicas** | 1 | 2 | 3 |
| **ML Service Replicas** | 1 | 1 | 2 |
| **Image Tag** | `dev` | `staging` | `prod` |
| **NODE_ENV** | `development` | `staging` | `production` |
| **LOG_LEVEL** | `debug` | `info` | `warn` |
| **SSL/TLS** | ❌ No | ✅ Yes (staging cert) | ✅ Yes (prod cert) |
| **Domain** | `dev.eshelf.local` | `staging.eshelf.example.com` | `eshelf.example.com` |
| **Resource Limits** | Low | Medium | High |
| **Auto-scaling** | ❌ No | ⚠️ Optional | ✅ Yes |

## Development Environment

### Đặc điểm
- **Mục đích**: Development và testing nhanh
- **Replicas**: 1 cho tất cả services
- **Resources**: Thấp nhất để tiết kiệm
- **Logging**: Debug mode, chi tiết nhất

### Deploy

```bash
# Build images với tag dev
docker build --build-arg VITE_API_URL=http://api-gateway:3000/api -t harbor-core.harbor.svc.cluster.local/eshelf/frontend:dev .

# Deploy
kubectl apply -k infrastructure/kubernetes/overlays/dev

# Check status
kubectl get pods -n eshelf-dev
kubectl get svc -n eshelf-dev
kubectl get ingress -n eshelf-dev
```

### Access
- Frontend: `http://dev.eshelf.local` (cần thêm vào `/etc/hosts`)
- API: `http://dev.eshelf.local/api`

## Staging Environment

### Đặc điểm
- **Mục đích**: Test trước khi release production
- **Replicas**: 2 cho backend services, 1 cho frontend và ML
- **Resources**: Trung bình
- **Logging**: Info level

### Deploy

```bash
# Build images với tag staging
docker build --build-arg VITE_API_URL=https://staging.eshelf.example.com/api -t eshelf/frontend:staging .

# Push to registry
docker push eshelf/frontend:staging

# Deploy
kubectl apply -k infrastructure/kubernetes/overlays/staging

# Check status
kubectl get pods -n eshelf-staging
kubectl rollout status deployment/frontend -n eshelf-staging
```

### Access
- Frontend: `https://staging.eshelf.example.com`
- API: `https://staging.eshelf.example.com/api`

## Production Environment

### Đặc điểm
- **Mục đích**: Môi trường chính thức cho end users
- **Replicas**: 2-3 cho tất cả services
- **Resources**: Cao nhất, tối ưu performance
- **Logging**: Warn level, chỉ log errors
- **Security**: SSL/TLS, rate limiting, security headers

### Deploy

```bash
# Build images với tag prod
docker build --build-arg VITE_API_URL=https://eshelf.example.com/api -t eshelf/frontend:prod .

# Push to registry
docker push eshelf/frontend:prod

# Deploy (cần approval)
kubectl apply -k infrastructure/kubernetes/overlays/prod

# Monitor rollout
kubectl rollout status deployment/frontend -n eshelf-prod
kubectl get pods -n eshelf-prod -w
```

### Access
- Frontend: `https://eshelf.example.com`
- API: `https://eshelf.example.com/api`

## Testing Environments

### Validate Configuration

```powershell
# Test tất cả môi trường
.\scripts\test-environments.ps1

# Test từng môi trường
.\scripts\test-environments.ps1 -Environment dev
.\scripts\test-environments.ps1 -Environment staging
.\scripts\test-environments.ps1 -Environment prod
```

### Dry-run Deployment

```bash
# Xem resources sẽ được tạo (không deploy)
kubectl kustomize infrastructure/kubernetes/overlays/dev
kubectl kustomize infrastructure/kubernetes/overlays/staging
kubectl kustomize infrastructure/kubernetes/overlays/prod

# Dry-run apply
kubectl apply -k infrastructure/kubernetes/overlays/dev --dry-run=client
```

## CI/CD Integration

### Jenkins Pipeline

```groovy
stage('Build & Push Images') {
    steps {
        script {
            def env = "${env.BRANCH_NAME}" == "main" ? "prod" : 
                     "${env.BRANCH_NAME}" == "staging" ? "staging" : "dev"
            
            sh """
                docker build --build-arg VITE_API_URL=${API_URL} \
                  -t ${REGISTRY}/eshelf/frontend:${env} .
                docker push ${REGISTRY}/eshelf/frontend:${env}
            """
        }
    }
}

stage('Deploy to Environment') {
    steps {
        script {
            def env = "${env.BRANCH_NAME}" == "main" ? "prod" : 
                     "${env.BRANCH_NAME}" == "staging" ? "staging" : "dev"
            
            sh "kubectl apply -k infrastructure/kubernetes/overlays/${env}"
        }
    }
}
```

### GitHub Actions

```yaml
- name: Deploy to Dev
  if: github.ref == 'refs/heads/develop'
  run: kubectl apply -k infrastructure/kubernetes/overlays/dev

- name: Deploy to Staging
  if: github.ref == 'refs/heads/staging'
  run: kubectl apply -k infrastructure/kubernetes/overlays/staging

- name: Deploy to Production
  if: github.ref == 'refs/heads/main'
  run: kubectl apply -k infrastructure/kubernetes/overlays/prod
```

## Environment Variables

### Build-time (Vite)
- `VITE_API_URL`: API Gateway URL (set khi build Docker image)

### Runtime (Kubernetes)
- `NODE_ENV`: `development` | `staging` | `production`
- `LOG_LEVEL`: `debug` | `info` | `warn`

## Troubleshooting

### Pod không start
```bash
# Check logs
kubectl logs -n eshelf-dev deployment/frontend

# Check events
kubectl describe pod -n eshelf-dev -l app=frontend

# Check resource limits
kubectl top pods -n eshelf-dev
```

### Ingress không hoạt động
```bash
# Check ingress
kubectl get ingress -n eshelf-dev
kubectl describe ingress -n eshelf-dev

# Check ingress controller
kubectl get pods -n ingress-nginx
```

### Image pull errors
```bash
# Check image pull secrets
kubectl get secrets -n eshelf-dev

# Verify image exists
docker pull harbor-core.harbor.svc.cluster.local/eshelf/frontend:dev
```

## Best Practices

1. **Never deploy directly to production**: Luôn test trên staging trước
2. **Use tags**: Dùng semantic versioning cho images (`v1.0.0`, `v1.0.1`)
3. **Monitor deployments**: Sử dụng `kubectl rollout status` để monitor
4. **Rollback strategy**: Luôn có plan rollback nếu deployment fail
5. **Resource limits**: Đặt limits phù hợp cho từng môi trường
6. **Health checks**: Đảm bảo liveness và readiness probes hoạt động
7. **Secrets management**: Dùng Kubernetes Secrets hoặc external secret manager

## Migration Path

1. **Development** → Test features mới
2. **Staging** → Test integration và performance
3. **Production** → Release cho end users

Mỗi bước cần approval và testing kỹ lưỡng.






