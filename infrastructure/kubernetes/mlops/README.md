# Thiết lập MLOps cho eShelf

## Các thành phần

- **MLflow:** Model tracking và registry
- **Model Training Pipeline:** Huấn luyện mô hình tự động qua GitHub Actions
- **Model Deployment Pipeline:** Canary deployment cho ML models

## Thiết lập

### 1. Triển khai MLflow

```bash
# Tạo namespace
kubectl create namespace mlops

# Triển khai MLflow
kubectl apply -f mlflow-deployment.yaml

# Đợi MLflow sẵn sàng
kubectl wait --for=condition=available --timeout=300s deployment/mlflow -n mlops

# Port forward để truy cập UI
kubectl port-forward svc/mlflow -n mlops 5000:5000
```

Truy cập MLflow UI: http://localhost:5000

### 2. Cấu hình S3/MinIO cho Artifacts

MLflow cần S3-compatible storage cho artifacts. Bạn có thể dùng:
- AWS S3
- MinIO (self-hosted)

Cập nhật `mlflow-deployment.yaml` với S3 credentials.

### 3. Thiết lập GitHub Secrets

Thêm vào GitHub repository secrets:
- `MLFLOW_TRACKING_URI`: http://mlflow.mlops.svc.cluster.local:5000
- `AWS_ACCESS_KEY_ID`: (cho S3)
- `AWS_SECRET_ACCESS_KEY`: (cho S3)
- `KUBECONFIG`: (kubeconfig đã encode base64)

### 4. Huấn luyện Model

Models được huấn luyện tự động khi:
- Code trong `backend/services/ml-service/` thay đổi
- Kích hoạt thủ công qua workflow_dispatch

### 5. Triển khai Model

Models được triển khai qua canary deployment:
1. Triển khai canary (10% traffic)
2. Chạy smoke tests
3. Promote lên production nếu tests pass
4. Rollback nếu thất bại

## Các loại Model

- **Recommender Model:** Collaborative filtering cho gợi ý sách
- **Similarity Model:** Phát hiện tương đồng dựa trên nội dung
- **Reading Time Model:** Ước tính thời gian đọc dựa trên số trang và thể loại

## Giám sát

Giám sát hiệu suất model qua:
- MLflow UI (metrics, parameters, artifacts)
- Prometheus (model serving metrics)
- Custom dashboards trong Grafana
