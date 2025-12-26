# Hướng Dẫn Sửa Lỗi Terraform Apply

## Các Thay Đổi Đã Thực Hiện

### 1. Sửa Key Pair Handling
- Đã sửa EC2 module để xử lý trường hợp không có key pair đúng cách
- Khi `key_name = ""`, instances sẽ được tạo mà không có key pair (bạn có thể dùng Systems Manager Session Manager để kết nối)

### 2. Sửa VPC Data Source
- Đã sửa VPC data source để không dùng filter khi đã có VPC ID
- Giảm thiểu lỗi permission khi query VPC

### 3. Cập Nhật terraform.tfvars
- Đã cập nhật với VPC ID và IGW ID của bạn
- Thêm hướng dẫn cách kiểm tra VPC CIDR và subnet CIDRs

## Kiểm Tra Trước Khi Chạy Terraform Apply

### 1. Kiểm Tra VPC CIDR
```powershell
# Chạy script để lấy thông tin VPC
.\scripts\get-vpc-info.ps1 -VpcId vpc-0a5f3fddad683a720

# Hoặc dùng AWS CLI
aws ec2 describe-vpcs --vpc-ids vpc-0a5f3fddad683a720 --query 'Vpcs[0].CidrBlock' --output text
```

Nếu VPC CIDR khác `172.31.0.0/16`, cập nhật `vpc_cidr` trong `terraform.tfvars`.

### 2. Kiểm Tra Subnet CIDRs Có Trùng Lặp Không
```powershell
# Kiểm tra subnets hiện có trong VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-0a5f3fddad683a720" --query 'Subnets[*].[SubnetId,CidrBlock]' --output table
```

Nếu các CIDR sau đã tồn tại, thay đổi trong `terraform.tfvars`:
- `172.31.1.0/24`
- `172.31.2.0/24`
- `172.31.10.0/24`
- `172.31.11.0/24`

Ví dụ, nếu đã tồn tại, có thể dùng:
- `172.31.20.0/24`
- `172.31.21.0/24`
- `172.31.30.0/24`
- `172.31.31.0/24`

### 3. Kiểm Tra Key Pairs (Optional)
```powershell
# Kiểm tra key pairs có sẵn
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
```

Nếu có key pair, cập nhật `key_name` trong `terraform.tfvars`. Nếu không có, để trống `key_name = ""`.

## Chạy Terraform

### 1. Khởi Tạo Terraform (Nếu Chưa)
```powershell
cd infrastructure/terraform/environments/dev
terraform init
```

### 2. Kiểm Tra Plan
```powershell
terraform plan
```

Kiểm tra xem có lỗi gì không. Nếu có lỗi về subnet CIDR conflict, cập nhật `public_subnet_cidrs` và `private_subnet_cidrs` trong `terraform.tfvars`.

### 3. Apply
```powershell
terraform apply
```

Khi được hỏi, gõ `yes` để xác nhận.

## Các Lỗi Thường Gặp và Cách Sửa

### Lỗi: "subnet CIDR conflicts with existing subnet"
**Giải pháp:** Thay đổi `public_subnet_cidrs` và `private_subnet_cidrs` trong `terraform.tfvars` sang các CIDR chưa được sử dụng.

### Lỗi: "InvalidVpcID.NotFound"
**Giải pháp:** Kiểm tra lại VPC ID trong `terraform.tfvars` có đúng không.

### Lỗi: "InvalidInternetGatewayID.NotFound"
**Giải pháp:** Kiểm tra lại IGW ID trong `terraform.tfvars` có đúng không. Hoặc để trống `existing_igw_id = ""` để Terraform tự tìm.

### Lỗi: "InvalidKeyPair.NotFound"
**Giải pháp:** Nếu bạn set `key_name` nhưng key pair không tồn tại, để trống `key_name = ""`.

## Lưu Ý

- **Không có Key Pair:** Instances sẽ được tạo nhưng bạn không thể SSH trực tiếp. Bạn có thể dùng AWS Systems Manager Session Manager để kết nối.
- **Subnet CIDRs:** Phải nằm trong VPC CIDR và không được trùng với subnets hiện có.
- **VPC CIDR:** Phải đúng với VPC thực tế để security group rules hoạt động đúng.

## Sau Khi Apply Thành Công

Nếu apply thành công, bạn sẽ có:
- ✅ Subnets mới trong VPC có sẵn
- ✅ Route tables
- ✅ NAT Gateway (nếu enable_nat_gateway = true)
- ✅ EC2 Instances (bastion, k3s master/workers, hoặc app servers)
- ✅ Security Groups

Để kết nối vào instances không có key pair:
```powershell
# Install AWS Session Manager Plugin first
# Then connect:
aws ssm start-session --target <instance-id>
```

