# Thiết lập AWS CodePipeline cho eShelf

## Yêu cầu

- AWS CLI đã cấu hình
- GitHub personal access token
- Docker Hub credentials (tùy chọn)
- Truy cập Kubernetes cluster (cho deployment)

## Triển khai

### 1. Tạo Stack

```bash
aws cloudformation create-stack \
  --stack-name eshelf-codepipeline \
  --template-body file://codepipeline-stack.yaml \
  --parameters \
    ParameterKey=GitHubOwner,ParameterValue=votrung654 \
    ParameterKey=GitHubRepo,ParameterValue=EShelf \
    ParameterKey=GitHubBranch,ParameterValue=main \
    ParameterKey=GitHubToken,ParameterValue=ghp_xxxxxxxxxxxx \
    ParameterKey=DockerHubUsername,ParameterValue=<username> \
    ParameterKey=DockerHubPassword,ParameterValue=<password> \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 2. Lưu Kubernetes Config trong Secrets Manager

```bash
# Encode kubeconfig
cat ~/.kube/config | base64 > kubeconfig.b64

# Tạo secret
aws secretsmanager create-secret \
  --name kubeconfig \
  --secret-binary fileb://kubeconfig.b64 \
  --region us-east-1
```

### 3. Cập nhật CodeBuild Deploy Project

Deploy project tham chiếu đến secret. Kiểm tra:
- Tên secret khớp: `kubeconfig`
- Region khớp với AWS region của bạn
- CodeBuild role có quyền đọc secret

## Pipeline Flow

1. **Source Stage**: Giám sát GitHub repository để phát hiện thay đổi
2. **Build Stage**: Build Docker images cho tất cả services
3. **Deploy Stage**: Triển khai lên Kubernetes cluster

## Thực thi thủ công

```bash
# Khởi động pipeline execution
aws codepipeline start-pipeline-execution \
  --name eshelf-codepipeline-pipeline \
  --region us-east-1
```

## Giám sát

Xem trạng thái pipeline trong AWS Console:
- CodePipeline → Pipelines → eshelf-codepipeline-pipeline

## Dọn dẹp

```bash
aws cloudformation delete-stack \
  --stack-name eshelf-codepipeline \
  --region us-east-1
```
