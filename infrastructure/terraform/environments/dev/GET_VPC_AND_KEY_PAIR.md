# Hướng Dẫn Lấy VPC ID và Key Pair Name

## Khi nào cần dùng VPC và Key Pair có sẵn?

Khi bạn gặp lỗi permission:
- `ec2:CreateVpc` - Không có quyền tạo VPC
- `ec2:ImportKeyPair` - Không có quyền tạo Key Pair

## Cách 1: Lấy từ AWS Console

### Lấy VPC ID:

1. **Mở AWS Console:**
   - Truy cập: https://console.aws.amazon.com/vpc/
   - Hoặc tìm "VPC" trong search bar

2. **Tìm VPC:**
   - Click vào "Your VPCs" ở menu bên trái
   - Bạn sẽ thấy danh sách VPCs
   - Copy **VPC ID** (ví dụ: `vpc-0123456789abcdef0`)

3. **Lấy Internet Gateway ID (optional):**
   - Click vào "Internet Gateways" ở menu bên trái
   - Tìm IGW gắn với VPC của bạn
   - Copy **Internet Gateway ID** (ví dụ: `igw-0123456789abcdef0`)

### Lấy Key Pair Name:

1. **Mở EC2 Console:**
   - Truy cập: https://console.aws.amazon.com/ec2/
   - Click vào "Key Pairs" ở menu bên trái

2. **Tìm Key Pair:**
   - Bạn sẽ thấy danh sách key pairs
   - Copy **Key Pair Name** (ví dụ: `vockey` cho AWS Academy)

## Cách 2: Dùng AWS CLI

### Lấy VPC ID:

```bash
# Liệt kê tất cả VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

# Lấy VPC ID mặc định (nếu có)
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query 'Vpcs[0].VpcId' --output text
```

### Lấy Internet Gateway ID:

```bash
# Lấy IGW của VPC cụ thể (thay VPC_ID)
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text
```

### Lấy Key Pair Name:

```bash
# Liệt kê tất cả key pairs
aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output table
```

## Cập nhật terraform.tfvars

Sau khi lấy được thông tin, cập nhật `terraform.tfvars`:

```hcl
# Dùng VPC có sẵn
use_existing_vpc = true
existing_vpc_id = "vpc-0123456789abcdef0"  # Thay bằng VPC ID của bạn
existing_igw_id = ""  # Optional, để trống nếu muốn tạo IGW mới

# Dùng Key Pair có sẵn
create_key_pair = false
key_name = "vockey"  # Thay bằng key pair name của bạn
```

## Lưu ý

- **VPC CIDR:** Khi dùng VPC có sẵn, bạn cần đảm bảo subnet CIDRs không conflict với VPC CIDR hiện tại
- **Subnets:** Terraform vẫn sẽ tạo subnets mới trong VPC có sẵn
- **Internet Gateway:** Nếu VPC đã có IGW, bạn có thể dùng `existing_igw_id` hoặc để trống để tạo mới (nếu có quyền)
- **Key Pair:** Đảm bảo bạn có file private key tương ứng để SSH vào instances

## Kiểm tra sau khi cập nhật

```powershell
cd infrastructure/terraform/environments/dev
terraform plan
```

Nếu không còn lỗi permission, bạn có thể chạy `terraform apply`.



