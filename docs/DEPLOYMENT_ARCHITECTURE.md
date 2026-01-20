# Deployment Architecture - Frontend vs Backend

## Vấn đề ban đầu

**Trước đây:**
- ✅ Backend services: Deploy lên Kubernetes cluster
- ❌ Frontend: Chỉ chạy local (Vite dev server)
- ❌ Frontend kết nối API qua `localhost:3000`

### Tại sao đây là vấn đề?

1. **Không production-ready**: Frontend local không thể truy cập từ bên ngoài
2. **CORS issues**: Frontend local gọi API trên cluster sẽ gặp CORS
3. **Không có CI/CD**: Frontend không được tự động deploy
4. **Khó scale**: Không thể scale frontend
5. **Bảo mật**: Phải expose API Gateway ra ngoài
6. **Không có CDN**: Static assets không được cache tốt

## Giải pháp đã triển khai

**Bây giờ:**
- ✅ Backend services: Deploy lên Kubernetes cluster
- ✅ Frontend: Deploy lên Kubernetes cluster (Nginx serving React build)
- ✅ Ingress: Route traffic tới frontend và API Gateway

### Kiến trúc mới

```
                    Internet
                       ↓
              Ingress Controller
                       ↓
        ┌──────────────┴──────────────┐
        ↓                             ↓
   Frontend Service              API Gateway Service
   (Nginx + React)               (Node.js)
        ↓                             ↓
   Static Files              Backend Services
   (HTML/CSS/JS)            (Auth/Book/User/ML)
```

### Luồng request

1. **Frontend request**: `GET /` → Ingress → Frontend Service → Nginx → `index.html`
2. **API request**: `GET /api/books` → Ingress → API Gateway → Book Service

## So sánh: Development vs Production

### Development (Local)
```bash
# Frontend chạy local
npm run dev  # Vite dev server trên port 5173

# Backend chạy trong Docker
docker compose up -d

# Frontend kết nối tới: http://localhost:3000/api
```

**Ưu điểm:**
- Hot reload nhanh
- Dễ debug
- Không cần build

**Nhược điểm:**
- Chỉ dùng được cho development
- Không thể test production-like environment

### Production (Kubernetes)
```bash
# Build frontend image
docker build --build-arg VITE_API_URL=https://api.eshelf.com/api -t eshelf/frontend:latest .

# Deploy lên cluster
kubectl apply -k infrastructure/kubernetes/overlays/prod
```

**Ưu điểm:**
- Production-ready
- Có thể scale
- Có CDN và caching
- Bảo mật tốt hơn
- CI/CD tự động

**Nhược điểm:**
- Cần build trước khi deploy
- Không có hot reload

## Best Practices

### 1. Environment Variables

Vite chỉ inject env vars lúc **build time**, không phải runtime:

```dockerfile
# Dockerfile
ARG VITE_API_URL
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build
```

```bash
# Build với API URL
docker build --build-arg VITE_API_URL=https://api.eshelf.com/api .
```

### 2. Ingress Configuration

Frontend và API nên cùng domain, khác path:

```yaml
# Ingress
rules:
- host: eshelf.com
  http:
    paths:
    - path: /          # Frontend
      backend: frontend
    - path: /api       # API Gateway
      backend: api-gateway
```

Frontend sẽ gọi API bằng relative path: `/api/books` thay vì `https://api.eshelf.com/api/books`

### 3. CORS Configuration

API Gateway chỉ cần allow origin của frontend:

```javascript
// API Gateway
const allowedOrigins = [
  'https://eshelf.com',      // Production frontend
  'http://localhost:5173'    // Development
];
```

### 4. Static Assets Caching

Nginx config cache static assets:

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

## Migration Path

### Bước 1: Development (Hiện tại)
- Frontend local, Backend Docker
- ✅ Đang hoạt động tốt

### Bước 2: Staging
- Frontend và Backend đều trên Kubernetes
- Test production-like environment

### Bước 3: Production
- Frontend và Backend trên Kubernetes
- Có Ingress, SSL, CDN

## Kết luận

**Trước:** Frontend local + Backend cluster = ❌ Không production-ready

**Sau:** Frontend cluster + Backend cluster = ✅ Production-ready

Việc deploy frontend lên cluster là **bắt buộc** cho production environment, nhưng vẫn có thể giữ frontend local cho development.






