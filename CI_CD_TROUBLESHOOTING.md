# CI/CD Troubleshooting Guide

## 1. Terraform Format Check Fail

### Vấn đề:
`terraform fmt -check -recursive` fail với lỗi "Terraform exited with code 3"

### Nguyên nhân:
- File có dòng trống thừa ở cuối
- Line endings không đúng (CRLF vs LF)
- Indentation không đúng

### Giải pháp:
```powershell
# Chạy terraform fmt để tự động format
cd infrastructure/terraform/environments/dev
terraform fmt -recursive

# Hoặc format từng file
terraform fmt main.tf outputs.tf
```

**Lưu ý:** Nếu không có terraform CLI, có thể:
1. Sử dụng GitHub Actions để format tự động
2. Hoặc đảm bảo file kết thúc bằng 1 dòng trống (không phải 2+ dòng)

## 2. Checkov Security Scan - 12 Errors

### Vấn đề:
Checkov tìm thấy 12 lỗi bảo mật nhưng job vẫn **PASS** (có tick xanh)

### Nguyên nhân:
Workflow có `soft_fail: true`, nên Checkov không fail pipeline dù có errors.

### Các lỗi và cách xử lý:

#### ✅ False Positives (Có thể bỏ qua):
1. **CKV2_AWS_5**: "Security Groups are attached to another resource"
   - **Lý do:** Security groups sẽ được attach khi tạo EC2 instances
   - **Giải pháp:** Thêm comment `# checkov:skip=CKV2_AWS_5:Security groups will be attached when EC2 instances are created`

2. **CKV2_AWS_19**: "EIP addresses allocated to a VPC are attached to EC2 instances"
   - **Lý do:** EIP sẽ được attach khi tạo NAT Gateway
   - **Giải pháp:** Thêm comment `# checkov:skip=CKV2_AWS_19:EIP will be attached to NAT Gateway`

3. **CKV_AWS_130**: "VPC subnets do not assign public IP by default"
   - **Lý do:** Public subnets CẦN `map_public_ip_on_launch = true`
   - **Giải pháp:** Thêm comment `# checkov:skip=CKV_AWS_130:Public subnets require public IP assignment`

#### ⚠️ Cần Fix:
1. **CKV2_AWS_12**: "Default security group of every VPC restricts all traffic"
   - **Vấn đề:** Default security group cho phép tất cả traffic
   - **Giải pháp:** Thêm resource để restrict default security group

2. **CKV2_AWS_11**: "VPC flow logging is enabled in all VPCs"
   - **Vấn đề:** VPC flow logging chưa được enable
   - **Giải pháp:** Thêm VPC flow log resource

3. **Parsing error**: `infrastructure/terraform/modules/ec2/main.tf`
   - **Vấn đề:** File có syntax error
   - **Giải pháp:** Kiểm tra và sửa syntax

### Cách thêm skip comments:
```hcl
# checkov:skip=CKV2_AWS_5:Security groups will be attached when EC2 instances are created
resource "aws_security_group" "example" {
  # ...
}
```

### Cách fix thực sự:
Xem file `infrastructure/terraform/modules/vpc/main.tf` để thêm VPC flow logging và default security group restriction.

## 3. MLOps Pipeline - Push to Registry Fail

### Vấn đề:
Step "Push to Registry" fail với lỗi authentication hoặc registry không accessible

### Nguyên nhân:
Thiếu GitHub Secrets:
- `DOCKER_REGISTRY_URL`
- `DOCKER_REGISTRY_USERNAME`
- `DOCKER_REGISTRY_PASSWORD`

### Giải pháp:

#### Bước 1: Tạo GitHub Secrets
1. Vào repository → Settings → Secrets and variables → Actions
2. Thêm các secrets:
   - `DOCKER_REGISTRY_URL`: URL của registry (ví dụ: `harbor.example.com` hoặc `docker.io`)
   - `DOCKER_REGISTRY_USERNAME`: Username để login
   - `DOCKER_REGISTRY_PASSWORD`: Password hoặc token

#### Bước 2: Kiểm tra workflow
File: `.github/workflows/mlops-model-deployment.yml`

```yaml
- name: Push to Registry
  env:
    DOCKER_REGISTRY: ${{ secrets.DOCKER_REGISTRY_URL }}
    DOCKER_USERNAME: ${{ secrets.DOCKER_REGISTRY_USERNAME }}
    DOCKER_PASSWORD: ${{ secrets.DOCKER_REGISTRY_PASSWORD }}
```

#### Bước 3: Test locally (nếu có registry)
```bash
docker login $DOCKER_REGISTRY_URL -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
docker tag eshelf/ml-service:test $DOCKER_REGISTRY_URL/eshelf/ml-service:test
docker push $DOCKER_REGISTRY_URL/eshelf/ml-service:test
```

### Alternative: Skip push nếu không có registry
Có thể thêm `continue-on-error: true` hoặc check secrets trước khi push:

```yaml
- name: Push to Registry
  if: ${{ secrets.DOCKER_REGISTRY_URL != '' }}
  continue-on-error: true
  # ...
```

## 4. Tổng Kết

### ✅ Đã Fix:
- Terraform format (xóa dòng trống thừa)

### ⚠️ Cần Fix:
1. **Checkov errors**: Thêm skip comments hoặc fix thực sự
2. **MLOps pipeline**: Thêm GitHub Secrets cho Docker registry
3. **VPC flow logging**: Thêm resource để enable
4. **Default security group**: Restrict traffic

### 📝 Best Practices:
1. **Luôn chạy `terraform fmt`** trước khi commit
2. **Review Checkov errors** - một số là false positives, một số cần fix
3. **Sử dụng GitHub Secrets** cho tất cả credentials
4. **Test workflows locally** nếu có thể (với act hoặc docker)

