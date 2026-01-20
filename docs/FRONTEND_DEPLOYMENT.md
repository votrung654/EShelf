# Frontend Deployment Guide

## Tổng quan

Frontend của eShelf được deploy lên Kubernetes cluster cùng với các backend services để đảm bảo:
- **Tính nhất quán**: Tất cả services cùng một môi trường
- **Bảo mật**: Không cần expose API Gateway ra ngoài
- **Hiệu suất**: CDN và caching cho static assets
- **Quản lý**: CI/CD pipeline thống nhất

## Kiến trúc

```
Internet
   ↓
Ingress Controller (NGINX)
   ├── / → Frontend Service (Nginx serving React build)
   └── /api → API Gateway Service
```

## Build và Deploy

### 1. Build Docker Image

```bash
# Build với build arg cho API URL
docker build \
  --build-arg VITE_API_URL=https://api.eshelf.example.com/api \
  -t eshelf/frontend:latest \
  .

# Hoặc sử dụng registry
docker build \
  --build-arg VITE_API_URL=https://api.eshelf.example.com/api \
  -t localhost:8080/eshelf/frontend:latest \
  .
```

### 2. Push to Registry

```bash
docker push localhost:8080/eshelf/frontend:latest
```

### 3. Deploy to Kubernetes

```bash
# Development
kubectl apply -k infrastructure/kubernetes/base

# Production
kubectl apply -k infrastructure/kubernetes/overlays/prod
```

## Cấu hình

### Environment Variables

Frontend sử dụng build-time environment variables (Vite):

- `VITE_API_URL`: URL của API Gateway
  - Development: `http://localhost:3000/api`
  - Production: `https://api.eshelf.example.com/api`

### Ingress Configuration

Cập nhật `infrastructure/kubernetes/base/ingress.yaml` với domain thực tế:

```yaml
spec:
  rules:
  - host: eshelf.example.com  # Thay bằng domain thực tế
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 3000
```

## Development vs Production

### Development (Local)
- Chạy `npm run dev` để có hot reload
- Frontend kết nối tới `http://localhost:3000/api`
- Phù hợp cho development và testing

### Production (Kubernetes)
- Frontend được build và serve bằng Nginx
- Frontend kết nối tới API Gateway qua service name
- Có Ingress để expose ra ngoài
- Có SSL/TLS certificate

## CI/CD Integration

Thêm stage vào Jenkinsfile để build và deploy frontend:

```groovy
stage('Build Frontend') {
    steps {
        sh '''
            docker build \
              --build-arg VITE_API_URL=${API_URL} \
              -t ${DOCKER_REGISTRY}/${PROJECT_NAME}/frontend:${env.GIT_COMMIT_SHORT} \
              .
        '''
    }
}
```

## Troubleshooting

### Frontend không load được
1. Kiểm tra pod status: `kubectl get pods -n eshelf -l app=frontend`
2. Kiểm tra logs: `kubectl logs -n eshelf -l app=frontend`
3. Kiểm tra service: `kubectl get svc -n eshelf frontend`

### API calls fail
1. Kiểm tra `VITE_API_URL` trong build
2. Kiểm tra Ingress routing
3. Kiểm tra CORS settings trong API Gateway

### Static assets không load
1. Kiểm tra nginx.conf
2. Kiểm tra build output trong `/usr/share/nginx/html`
3. Kiểm tra Ingress path configuration

## Best Practices

1. **Build-time variables**: Vite chỉ inject env vars lúc build, không phải runtime
2. **Cache busting**: Vite tự động hash filenames cho cache busting
3. **CDN**: Có thể serve static assets từ CDN (S3 + CloudFront)
4. **Health checks**: Frontend có `/health` endpoint cho Kubernetes probes
5. **Resource limits**: Đặt limits phù hợp cho Nginx container






