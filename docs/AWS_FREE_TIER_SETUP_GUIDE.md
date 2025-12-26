# Hướng Dẫn Setup AWS Free Tier Account Từ Đầu

## 📋 Tổng Quan

Tài khoản AWS Free Tier mới cần setup các thành phần cơ bản trước khi deploy infrastructure. Hướng dẫn này sẽ giúp bạn setup từng bước.

## Bước 1: Tạo IAM User và Access Keys

### 1.1. Tạo IAM User

1. **Đăng nhập AWS Console:**
   - Truy cập: https://console.aws.amazon.com
   - Đăng nhập với root account hoặc admin account

2. **Vào IAM Service:**
   - Tìm kiếm "IAM" trong search bar
   - Click vào **IAM** service

3. **Tạo User mới:**
   - Click **Users** ở menu bên trái
   - Click nút **Create user**

4. **Đặt tên user:**
   - **User name:** `eshelf-admin` (hoặc tên bạn muốn)
   - Click **Next**

5. **Set permissions:**
   - Chọn **Attach policies directly**
   - Tìm và chọn các policies sau:
     - ✅ `AdministratorAccess` (hoặc tạo custom policy với quyền cần thiết)
     - Hoặc nếu muốn hạn chế quyền, chọn:
       - `AmazonEC2FullAccess`
       - `AmazonVPCFullAccess`
       - `AmazonS3FullAccess`
       - `IAMFullAccess`
       - `CloudFormationFullAccess`
   - Click **Next**

6. **Review và Create:**
   - Review lại thông tin
   - Click **Create user**

### 1.2. Tạo Access Keys

1. **Vào user vừa tạo:**
   - Click vào user name (`eshelf-admin`)

2. **Tạo Access Key:**
   - Tab **Security credentials**
   - Scroll xuống phần **Access keys**
   - Click **Create access key**

3. **Chọn use case:**
   - Chọn **Command Line Interface (CLI)**
   - Check box "I understand..."
   - Click **Next**

4. **Set description (optional):**
   - Có thể để trống hoặc nhập mô tả
   - Click **Create access key**

5. **Lưu Access Keys:**
   - ⚠️ **QUAN TRỌNG:** Copy ngay **Access Key ID** và **Secret Access Key**
   - Secret Access Key chỉ hiển thị 1 lần duy nhất!
   - Lưu vào file an toàn hoặc password manager
   - Click **Done**

## Bước 2: Configure AWS CLI

### 2.1. Cài AWS CLI (nếu chưa có)

**Windows (PowerShell):**
```powershell
winget install Amazon.AWSCLI
```

**Kiểm tra:**
```powershell
aws --version
```

### 2.2. Configure Credentials

```powershell
aws configure
```

Nhập thông tin:
- **AWS Access Key ID:** [Paste Access Key ID từ bước 1.2]
- **AWS Secret Access Key:** [Paste Secret Access Key từ bước 1.2]
- **Default region name:** `us-east-1`
- **Default output format:** `json`

### 2.3. Test Kết Nối

```powershell
aws sts get-caller-identity
```

Kết quả mong đợi:
```json
{
    "UserId": "AIDA...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/eshelf-admin"
}
```

## Bước 3: Setup VPC và Networking (Nếu Cần)

### 3.1. Kiểm Tra Default VPC

AWS Free Tier thường đã có default VPC sẵn. Kiểm tra:

```powershell
aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[*].[VpcId,CidrBlock]" --output table
```

Nếu có kết quả → Đã có default VPC, có thể dùng hoặc tạo mới.

### 3.2. Tạo VPC Mới (Nếu Muốn)

Nếu muốn tạo VPC riêng (Terraform sẽ tự động làm, nhưng có thể test thủ công):

```powershell
# Tạo VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region us-east-1

# Lưu VPC ID từ output
# Sau đó tạo subnets, internet gateway, etc.
```

**Lưu ý:** Terraform sẽ tự động tạo VPC, nên bước này không bắt buộc.

## Bước 4: Setup EC2 Key Pair (Nếu Dùng SSH)

### 4.1. Tạo Key Pair

```powershell
# Tạo key pair mới
aws ec2 create-key-pair --key-name eshelf-keypair --query 'KeyMaterial' --output text > eshelf-keypair.pem

# Hoặc dùng SSH key có sẵn
aws ec2 import-key-pair --key-name eshelf-keypair --public-key-material fileb://~/.ssh/id_rsa.pub
```

### 4.2. Lưu Key Pair

- Lưu file `.pem` ở nơi an toàn
- Set permissions (nếu dùng Linux/Mac):
  ```bash
  chmod 400 eshelf-keypair.pem
  ```

**Lưu ý:** Nếu dùng AWS SSM Session Manager (không cần SSH key), có thể bỏ qua bước này.

## Bước 5: Kiểm Tra Service Limits

### 5.1. Kiểm Tra EC2 Limits

```powershell
aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --region us-east-1
```

### 5.2. Kiểm Tra VPC Limits

Free Tier thường có:
- 5 VPCs per region
- 200 subnets per VPC
- 5 Elastic IPs

## Bước 6: Enable Required Services

Một số services cần enable lần đầu:

### 6.1. EC2 Instance Connect

```powershell
# Kiểm tra
aws ec2 describe-instances --region us-east-1 --max-items 1
```

### 6.2. Systems Manager (SSM)

```powershell
# Kiểm tra SSM
aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1
```

Nếu lỗi, cần enable SSM trong IAM hoặc Console.

## Bước 7: Test Tạo EC2 Instance (Optional)

Test xem có thể tạo instance không:

```powershell
# Lấy AMI ID mới nhất
$amiId = aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 --query 'Parameter.Value' --output text

# Tạo test instance (t3.micro - Free Tier eligible)
aws ec2 run-instances `
    --image-id $amiId `
    --instance-type t3.micro `
    --key-name eshelf-keypair `
    --region us-east-1 `
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-instance}]' `
    --query 'Instances[0].InstanceId' `
    --output text
```

**Lưu ý:** Nhớ terminate instance test sau khi xong:
```powershell
aws ec2 terminate-instances --instance-ids <instance-id> --region us-east-1
```

## Bước 8: Verify Setup

Chạy script verify:

```powershell
.\scripts\verify-aws-setup.ps1
```

Hoặc test thủ công:

```powershell
# Test 1: Identity
aws sts get-caller-identity

# Test 2: EC2 Access
aws ec2 describe-regions --region-names us-east-1

# Test 3: VPC Access
aws ec2 describe-vpcs --region us-east-1 --max-items 1

# Test 4: SSM Access
aws ssm describe-instance-information --region us-east-1 --max-items 1
```

## ✅ Checklist Setup

- [ ] IAM user đã được tạo
- [ ] Access Keys đã được tạo và lưu an toàn
- [ ] AWS CLI đã được configure
- [ ] `aws sts get-caller-identity` thành công
- [ ] Có thể list regions
- [ ] Có thể describe VPCs
- [ ] (Optional) Key pair đã được tạo
- [ ] (Optional) Test instance có thể tạo

## 🚨 Troubleshooting

### Lỗi: "Access Denied"
- Kiểm tra IAM user có đủ permissions
- Kiểm tra policies đã được attach chưa

### Lỗi: "Invalid credentials"
- Kiểm tra Access Keys đã copy đúng chưa
- Chạy lại `aws configure`

### Lỗi: "Region not available"
- Kiểm tra region name đúng chưa (`us-east-1`)
- Một số regions có thể không available cho Free Tier

### Lỗi: "Service not enabled"
- Vào AWS Console enable service lần đầu
- Hoặc đợi vài phút để service activate

## 📚 Tài Liệu Tham Khảo

- [AWS Free Tier](https://aws.amazon.com/free/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

## 🎯 Bước Tiếp Theo

Sau khi setup xong, tiếp tục với:
1. **NEXT_STEPS.md** - Bước 3: Setup Terraform Infrastructure
2. Chạy `terraform init` và `terraform apply`
3. Deploy K3s cluster và applications



