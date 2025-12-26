# Hướng Dẫn Demo eShelf Project

## Mục Lục
1. [Chuẩn Bị Môi Trường](#chuẩn-bị-môi-trường)
2. [Setup AWS Academy](#setup-aws-academy)
3. [Kiểm Tra Tự Động](#kiểm-tra-tự-động)
4. [Setup Infrastructure với Terraform](#setup-infrastructure-với-terraform)
5. [Deploy Kubernetes Cluster](#deploy-kubernetes-cluster)
6. [Deploy Applications](#deploy-applications)
7. [Kiểm Tra và Demo](#kiểm-tra-và-demo)
8. [Troubleshooting](#troubleshooting)

---

## Chuẩn Bị Môi Trường

### Yêu Cầu Hệ Thống
- Windows 10/11 hoặc Linux/Mac
- PowerShell 5.1+ (Windows) hoặc Bash (Linux/Mac)
- AWS CLI v2
- Terraform >= 1.5.0
- kubectl
- Docker Desktop (cho local development)

### Cài Đặt Công Cụ

#### 1. AWS CLI
```powershell
# Windows - Download từ: https://aws.amazon.com/cli/
# Hoặc dùng winget:
winget install Amazon.AWSCLI

# Verify installation
aws --version
```

Nếu đã cài nhưng vẫn báo "aws: The term 'aws' is not recognized":
→ Bạn cần thêm thư mục cài đặt AWS CLI vào biến môi trường PATH.

Thông thường, AWS CLI được cài ở:
C:\Program Files\Amazon\AWSCLIV2\
hoặc
C:\Program Files\Amazon\AWSCLI\

Thêm vào PATH (PowerShell):
$env:Path += ";C:\Program Files\Amazon\AWSCLIV2\"
Hoặc thêm thủ công qua System Properties > Environment Variables

Sau đó, mở lại terminal/cmd mới và kiểm tra:
aws --version
```

#### 2. Terraform
```powershell
# Windows - Nếu đã cài bằng winget mà không có bản mới hơn:
terraform version

# Nếu cần cập nhật hoặc cài lại bản mới nhất:
# 1. Truy cập https://www.terraform.io/downloads.html
# 2. Tải file .zip cho Windows, giải nén và thêm thư mục chứa terraform.exe vào PATH
# 3. Kiểm tra lại:
terraform version
```

#### 3. kubectl
```powershell
# Windows
winget install Kubernetes.kubectl

# Hoặc tải từ: https://kubernetes.io/docs/tasks/tools/

# Verify installation
kubectl version --client
```

---

## Setup AWS Academy

### Bước 1: Tạo File Credentials

File `aws-academy-credentials.txt` đã được tạo tự động từ thông tin bạn cung cấp. File này **KHÔNG** được commit lên Git (đã có trong `.gitignore`).

**Lưu ý quan trọng:**
- Sandbox sẽ reset sau 4 giờ, tất cả dữ liệu sẽ bị xóa
- Hệ thống có thể bị khóa vì nhiều lý do
- Tham khảo "Hands-on playground and labs abuse protocol" để biết thêm chi tiết

### Bước 2: Load Credentials vào Environment

Chạy script để load credentials:

```powershell
.\scripts\setup-aws-credentials.ps1
```

Script này sẽ:
- Đọc file `aws-academy-credentials.txt`
- Kiểm tra AWS CLI đã cài đặt chưa
- Load credentials vào environment variables
- Hướng dẫn các bước tiếp theo

### Bước 3: Đăng Nhập AWS Console (Thủ Công)

**AWS Academy sử dụng SSO (Single Sign-On), bạn cần đăng nhập qua browser:**

1. **Mở browser và truy cập URL từ credentials file:**
   ```
   https://644123626050.signin.aws.amazon.com/console?region=us-east-1
   ```

2. **Đăng nhập với thông tin:**
   - Username: `cloud_user`
   - Password: `3ZJ7)y2GAjsk#P+^aD8y`

3. **Sau khi đăng nhập thành công, bạn sẽ thấy AWS Console**

### Bước 4: Configure AWS CLI cho AWS Academy

AWS Academy hỗ trợ 2 cách để sử dụng AWS CLI:

#### **Cách 1: AWS SSO CLI (Khuyến nghị - Dễ dàng hơn)**

AWS Academy sử dụng SSO, bạn có thể dùng AWS SSO CLI để login trực tiếp:

**Bước 1: Configure SSO Profile**

Chạy script tự động:
```powershell
.\scripts\setup-aws-sso.ps1
```

Hoặc configure thủ công:
```powershell
aws configure sso --profile aws-academy
```

Khi được hỏi, điền:
- **SSO start URL:** `https://644123626050.signin.aws.amazon.com/console`
- **SSO region:** `us-east-1`
- **SSO registration scopes:** `sso:account:access`
- **CLI default client Region:** `us-east-1`
- **CLI default output format:** `json`

**Bước 2: Login**

```powershell
aws sso login --profile aws-academy
```

Browser sẽ mở và bạn đăng nhập với:
- Username: `cloud_user`
- Password: `3ZJ7)y2GAjsk#P+^aD8y`

**Bước 3: Sử dụng**

Sau khi login, sử dụng AWS CLI với profile:
```powershell
aws s3 ls --profile aws-academy
```

Hoặc set environment variable để dùng mặc định:
```powershell
$env:AWS_PROFILE = "aws-academy"
aws s3 ls
```

**Lưu ý:** SSO session hết hạn sau một thời gian, cần login lại bằng `aws sso login --profile aws-academy`

#### **Cách 2: Temporary Access Keys (Truyền thống)**

Nếu không muốn dùng SSO, bạn có thể tạo temporary access keys:

**Bước 1: Lấy Access Key từ IAM Console**

1. Trong AWS Console, vào **IAM** service
2. Chọn **Users** → chọn user của bạn
3. Chọn tab **Security credentials**
4. Scroll xuống **Access keys** → **Create access key**
5. Chọn use case: **Command Line Interface (CLI)**
6. Copy **Access Key ID** và **Secret Access Key**
7. **Lưu ý:** Secret Access Key chỉ hiển thị một lần, hãy lưu lại ngay!

**Bước 2: Configure AWS CLI**

```powershell
aws configure
```

Nhập thông tin:
- **AWS Access Key ID:** [Paste Access Key ID]
- **AWS Secret Access Key:** [Paste Secret Access Key]
- **Default region name:** `us-east-1` (hoặc region bạn muốn)
- **Default output format:** `json`

#### **Cách 3: Sử dụng CloudShell (Không cần configure)**

1. Trong AWS Console, click vào icon **CloudShell** (terminal icon ở top bar)
2. CloudShell sẽ tự động có credentials sẵn
3. Bạn có thể chạy AWS CLI commands trực tiếp từ đây

### Bước 6: Kiểm Tra Kết Nối AWS (Tự Động)

Chạy script test tự động:

```powershell
.\scripts\test-aws-connection.ps1
```

Script này sẽ test:
- AWS CLI installation
- AWS credentials configuration
- Region access
- EC2 service access
- VPC service access

**Kết quả mong đợi:**
```
[PASS] AWS CLI Installation: aws-cli/2.x.x
[PASS] AWS Credentials: Account: 644123626050
[PASS] Region Access: Region: us-east-1
[PASS] EC2 Service: Service accessible
[PASS] VPC Service: Service accessible

✓ All tests passed! AWS connection is working.
```

**Nếu có lỗi:**
- Kiểm tra lại credentials đã đúng chưa
- Kiểm tra region có đúng không
- Kiểm tra IAM permissions của user

---

## Setup Infrastructure với Terraform

### Bước 1: Kiểm Tra Terraform Configuration

```powershell
cd infrastructure/terraform/environments/dev

# Validate Terraform files
terraform init -backend=false
terraform validate
terraform fmt -check
```

### Bước 2: Tạo Terraform Variables File

Copy file example và điền thông tin:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
```

Mở `terraform.tfvars` và cập nhật các giá trị cần thiết (nếu có).

**Lưu ý:** File `terraform.tfvars` đã có trong `.gitignore`, không được commit lên Git.

### Bước 3: Terraform Plan

Xem trước những gì sẽ được tạo:

```powershell
terraform init
terraform plan
```

Kiểm tra output:
- VPC sẽ được tạo
- Subnets (public/private)
- Security Groups
- EC2 instances cho K3s cluster
- Internet Gateway, NAT Gateway

### Bước 4: Terraform Apply (Thủ Công - Cần Xác Nhận)

**Lưu ý:** Bước này sẽ tạo resources trên AWS và có thể tốn phí. Hãy chắc chắn bạn muốn tiếp tục.

```powershell
terraform apply
```

Terraform sẽ hiển thị plan và hỏi xác nhận. Nhập `yes` để tiếp tục.

**Thời gian:** Quá trình này có thể mất 5-10 phút để tạo tất cả resources.

### Bước 5: Kiểm Tra Terraform Output

Sau khi apply thành công:

```powershell
terraform output
```

Bạn sẽ thấy:
- `k3s_master_instance_id`: ID của master node
- `k3s_worker_instance_ids`: IDs của worker nodes
- `bastion_instance_id`: ID của bastion host
- `vpc_id`: ID của VPC
- `public_subnet_ids`: IDs của public subnets
- `private_subnet_ids`: IDs của private subnets

---

## Deploy Kubernetes Cluster

### Bước 1: Setup Ansible Inventory

Terraform output sẽ được dùng để tạo Ansible inventory. Script tự động sẽ làm điều này, hoặc bạn có thể làm thủ công:

```powershell
cd infrastructure/ansible

# Tạo inventory từ Terraform output
# (Script tự động sẽ làm điều này)
```

### Bước 2: Deploy K3s với Ansible

```powershell
# Từ thư mục ansible
ansible-playbook -i inventory/hosts.ini playbooks/k3s-cluster.yml
```

Playbook này sẽ:
- Install K3s trên master node
- Join worker nodes vào cluster
- Setup kubeconfig
- Verify cluster health

### Bước 3: Verify Cluster

```powershell
# Export kubeconfig (script sẽ tự động làm)
# Hoặc copy kubeconfig từ master node

kubectl get nodes
```

Kết quả mong đợi:
```
NAME              STATUS   ROLES                  AGE   VERSION
ip-xxx-xxx-xxx    Ready    control-plane,master   5m    v1.28.x+k3s1
ip-xxx-xxx-xxx    Ready    <none>                 4m    v1.28.x+k3s1
ip-xxx-xxx-xxx    Ready    <none>                 4m    v1.28.x+k3s1
```

---

## Deploy Applications

### Bước 1: Deploy ArgoCD

```powershell
kubectl create namespace argocd
kubectl apply -n argocd -f infrastructure/kubernetes/argocd/
```

Chờ ArgoCD pods ready:
```powershell
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Bước 2: Truy Cập ArgoCD UI (Browser)

**Lấy ArgoCD admin password:**
```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

**Port-forward ArgoCD:**
```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Truy cập browser:**
- URL: `https://localhost:8080`
- Username: `admin`
- Password: [Password từ command trên]

**Kiểm tra trong ArgoCD UI:**
- Tất cả applications đã được sync
- Health status: Healthy
- Sync status: Synced

### Bước 3: Deploy Monitoring Stack

```powershell
kubectl apply -f infrastructure/kubernetes/monitoring/
```

Chờ các pods ready:
```powershell
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
```

### Bước 4: Truy Cập Grafana (Browser)

**Port-forward Grafana:**
```powershell
kubectl port-forward svc/grafana -n monitoring 3000:3000
```

**Truy cập browser:**
- URL: `http://localhost:3000`
- Username: `admin`
- Password: `admin` (đổi sau lần đăng nhập đầu)

**Kiểm tra:**
- Dashboard hiển thị metrics
- Prometheus data source đã được config
- Có metrics từ các services

### Bước 5: Deploy Harbor Registry

```powershell
kubectl apply -f infrastructure/kubernetes/harbor/
```

Chờ Harbor ready:
```powershell
kubectl wait --for=condition=ready pod -l app=harbor -n harbor --timeout=600s
```

### Bước 6: Truy Cập Harbor UI (Browser)

**Port-forward Harbor:**
```powershell
kubectl port-forward svc/harbor-core -n harbor 8081:80
```

**Truy cập browser:**
- URL: `http://localhost:8081`
- Username: `admin`
- Password: [Xem trong Harbor values.yaml hoặc secret]

**Kiểm tra:**
- Harbor UI load được
- Có thể tạo project
- Có thể push/pull images

---

## Kiểm Tra và Demo

### Test Tự Động

Chạy các script test:

```powershell
# Test infrastructure
.\scripts\test-infrastructure.sh

# Test AWS connection
.\scripts\test-aws-connection.ps1

# Test services
.\scripts\check-services.sh
```

### Demo Checklist

#### 1. Infrastructure
- [ ] VPC đã được tạo
- [ ] Subnets (public/private) đã được tạo
- [ ] Security Groups đã được config
- [ ] EC2 instances đang chạy
- [ ] K3s cluster đã được deploy

#### 2. Kubernetes
- [ ] Cluster có 3 nodes (1 master, 2 workers)
- [ ] Tất cả nodes status: Ready
- [ ] Namespaces đã được tạo (argocd, monitoring, harbor, etc.)

#### 3. ArgoCD
- [ ] ArgoCD UI accessible
- [ ] Tất cả applications đã sync
- [ ] Health status: Healthy
- [ ] Có thể thấy các services trong ArgoCD

#### 4. Applications
- [ ] API Gateway đang chạy
- [ ] Auth Service đang chạy
- [ ] Book Service đang chạy
- [ ] User Service đang chạy
- [ ] ML Service đang chạy

#### 5. Monitoring
- [ ] Grafana accessible
- [ ] Prometheus đang collect metrics
- [ ] Dashboards hiển thị data
- [ ] Logs được collect (Loki)

#### 6. Registry
- [ ] Harbor accessible
- [ ] Có thể push images
- [ ] Có thể pull images
- [ ] Image scanning hoạt động

### Demo Scenarios

#### Scenario 1: CI/CD Pipeline
1. Tạo một PR với code changes
2. Show GitHub Actions workflow chạy
3. Show tests, linting, security scans
4. Show build và push images
5. Show ArgoCD tự động sync

#### Scenario 2: Rollback
1. Deploy một version có bug
2. Show application không hoạt động
3. Rollback về version trước
4. Show application hoạt động lại

#### Scenario 3: Monitoring
1. Show Grafana dashboards
2. Show metrics từ các services
3. Show logs trong Loki
4. Show alerts (nếu có)

---

## Troubleshooting

### Lỗi: Không thể describe-images (ec2:DescribeImages) do explicit deny

**Nguyên nhân:**
- Tài khoản AWS/IAM user bị **explicit deny** bởi Service Control Policy (SCP) hoặc chính sách của AWS Academy.
- Bạn **không thể sử dụng** lệnh `describe-images` hoặc truy vấn AMI public (ví dụ: Amazon Linux 2023) do hạn chế quyền.

**Giải pháp:**
1. **Nếu dùng AWS Academy hoặc tài khoản bị giới hạn:**
   - Không thể override hoặc cấp thêm quyền nếu bị deny bởi SCP.
   - Chỉ sử dụng được các AMI hoặc resource mà trường/lab đã cho phép sẵn.
   - Hỏi giảng viên/trợ giảng xem có AMI nào được phép sử dụng (có thể là custom AMI do trường cấp).

2. **Nếu bạn cần EC2 AMI cho Terraform:**
   - Hỏi giảng viên/trợ giảng cung cấp sẵn `ami_id` hợp lệ (AMI private hoặc do trường tạo).
   - Trong file Terraform, override biến `ami_id` bằng giá trị được cấp.

3. **Không tự bypass được:**  
   - Không thể xin thêm quyền nếu bạn không phải admin của AWS Organization/lab.

**Tóm tắt:**  
- Lỗi này là do chính sách bảo mật của trường/lab, không phải do cấu hình sai.
- Chỉ sử dụng được AMI hoặc resource mà trường cho phép.
- Luôn hỏi giảng viên/trợ giảng nếu cần AMI ID hợp lệ.

### Lỗi: AWS Credentials không hoạt động

**Nguyên nhân:**
- Credentials hết hạn (AWS Academy sandbox reset)
- Credentials không đúng
- IAM permissions không đủ

**Giải pháp:**
1. Đăng nhập lại AWS Console
2. Tạo Access Key mới
3. Configure lại AWS CLI: `aws configure`
4. Test lại: `.\scripts\test-aws-connection.ps1`

### Lỗi: Terraform không thể tạo resources

**Nguyên nhân:**
- AWS quota limits
- Region không hỗ trợ một số services
- IAM permissions không đủ

**Giải pháp:**
1. Kiểm tra AWS Console → Service Quotas
2. Kiểm tra IAM permissions
3. Thử region khác (nếu được phép)
4. Kiểm tra Terraform plan output để xem lỗi cụ thể

### Lỗi: K3s cluster không join được

**Nguyên nhân:**
- Security groups chưa mở đúng ports
- Network connectivity issues
- Ansible inventory không đúng

**Giải pháp:**
1. Kiểm tra security groups trong AWS Console
2. Kiểm tra network connectivity giữa nodes
3. Verify Ansible inventory file
4. Check K3s logs trên master node

### Lỗi: ArgoCD không sync applications

**Nguyên nhân:**
- Repository access issues
- Image pull errors
- Resource limits

**Giải pháp:**
1. Kiểm tra ArgoCD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`
2. Kiểm tra repository credentials
3. Kiểm tra image registry access
4. Kiểm tra resource quotas

### Lỗi: Services không accessible

**Nguyên nhân:**
- Ingress chưa được config
- Port-forward không đúng
- Services chưa ready

**Giải pháp:**
1. Kiểm tra service status: `kubectl get svc -A`
2. Kiểm tra pods: `kubectl get pods -A`
3. Kiểm tra ingress: `kubectl get ingress -A`
4. Kiểm tra logs: `kubectl logs <pod-name> -n <namespace>`

### Lỗi: Không kết nối được endpoint AWS (Could not connect to the endpoint URL)

**Nguyên nhân:**
- Sai region (ví dụ: `eshelf-test-1` không phải region hợp lệ của AWS)
- Cấu hình AWS CLI bị sai region hoặc endpoint
- Mạng bị chặn hoặc không có internet

**Giải pháp:**
1. Kiểm tra lại region trong cấu hình AWS CLI:
   ```powershell
   aws configure
   ```
   - Đảm bảo **Default region name** là một region hợp lệ, ví dụ: `us-east-1`, `ap-southeast-1`, v.v.
   - Không dùng tên như `eshelf-test-1` (đây không phải region thật của AWS).

2. Kiểm tra lại lệnh:
   ```powershell
   aws sts get-caller-identity --region us-east-1
   ```
   (hoặc region đúng với tài khoản của bạn)

3. Kiểm tra kết nối mạng/internet.

4. Nếu vẫn lỗi, xóa file cấu hình cũ và cấu hình lại:
   ```powershell
   Remove-Item ~/.aws/credentials
   Remove-Item ~/.aws/config
   aws configure
   ```

### Lỗi: Không tìm thấy thư mục khi cd vào Terraform environment

**Nguyên nhân:**
- Bạn đang ở đúng thư mục `D:\github-renewable\eShelf`, nhưng lệnh `cd infrastructure/terraform/environments/dev` sẽ chuyển vào `D:\github-renewable\eShelf\infrastructure\terraform\environments\dev`.
- Nếu bạn chạy lại lệnh này **khi đã ở trong thư mục đó**, nó sẽ tìm tiếp một lần nữa bên trong, dẫn đến lỗi "Cannot find path ... because it does not exist".

**Giải pháp:**
- Chỉ chạy lệnh `cd infrastructure/terraform/environments/dev` **khi bạn đang ở thư mục gốc của project**.
- Nếu đã ở đúng thư mục, KHÔNG cần cd thêm nữa.
- Kiểm tra vị trí hiện tại bằng:
  ```powershell
  Get-Location
  ```
- Nếu cần về thư mục gốc, dùng:
  ```powershell
  cd D:\github-renewable\eShelf
  ```

**Ví dụ đúng:**
```powershell
# Từ thư mục gốc project:
cd infrastructure/terraform/environments/dev

# Nếu đã ở D:\github-renewable\eShelf\infrastructure\terraform\environments\dev thì KHÔNG cần cd nữa.
```

---

## Cleanup (Quan Trọng!)

**Lưu ý:** AWS Academy sandbox sẽ tự động reset sau 4 giờ, nhưng bạn nên cleanup để tránh tốn phí không cần thiết.

### Shutdown EC2 Instances

```powershell
.\scripts\aws-shutdown.sh dev
```

Hoặc thủ công:
```powershell
# Lấy instance IDs từ Terraform output
terraform output -json | ConvertFrom-Json

# Stop instances
aws ec2 stop-instances --instance-ids <instance-id-1> <instance-id-2> ...
```

### Destroy Terraform Resources

**Cẩn thận:** Bước này sẽ xóa TẤT CẢ resources!

```powershell
cd infrastructure/terraform/environments/dev
terraform destroy
```

Nhập `yes` khi được hỏi xác nhận.

---

## Tài Liệu Tham Khảo

- [AWS Academy Documentation](https://awsacademy.instructure.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [K3s Documentation](https://k3s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Project Architecture](./docs/ARCHITECTURE.md)

---

## Hỗ Trợ

Nếu gặp vấn đề, hãy:
1. Kiểm tra logs và error messages
2. Xem [Troubleshooting](#troubleshooting) section
3. Kiểm tra các file documentation trong `docs/`
4. Review GitHub Issues (nếu có)

### Lưu ý về region name (AWS)

- **Region name** là tên vùng (datacenter) của AWS mà bạn muốn sử dụng.
- Một số region phổ biến:
  - `us-east-1` (N. Virginia, Mỹ)
  - `us-west-2` (Oregon, Mỹ)
  - `ap-southeast-1` (Singapore)
  - `ap-northeast-1` (Tokyo)
  - `eu-west-1` (Ireland)
- Bạn có thể xem danh sách đầy đủ tại: https://docs.aws.amazon.com/general/latest/gr/rande.html

**Cách lấy region name phù hợp:**
1. Đăng nhập AWS Console.
2. Góc trên bên phải, cạnh tên tài khoản, sẽ thấy tên region đang dùng (ví dụ: N. Virginia).
3. Click vào đó sẽ thấy region name tương ứng (ví dụ: `us-east-1`).
4. Khi cấu hình AWS CLI, nhập đúng region name này.
