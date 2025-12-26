# Fix Terraform AMI Permission Error

## Lỗi Gặp Phải

```
Error: reading EC2 AMIs: operation error EC2: DescribeImages, 
api error UnauthorizedOperation: You are not authorized to perform this operation. 
User: arn:aws:iam::533266955893:user/cloud_user is not authorized to perform: 
ec2:DescribeImages with an explicit deny in a service control policy
```

## Nguyên Nhân

Terraform đang cố query AMI ID tự động, nhưng user không có quyền `ec2:DescribeImages` do service control policy.

## Giải Pháp: Hardcode AMI ID

Đã sửa code để cho phép hardcode AMI ID. Bạn cần lấy AMI ID và thêm vào `terraform.tfvars`.

### Cách 1: Lấy từ AWS Console (Dễ nhất)

1. **Mở AWS Console:**
   - Truy cập: https://console.aws.amazon.com/ec2/
   - Hoặc trong AWS Console, tìm "EC2"

2. **Launch Instance:**
   - Click nút **"Launch instance"** (màu cam)

3. **Tìm AMI:**
   - Trong phần **"Application and OS Images (Amazon Machine Image)"**
   - Search: **"Amazon Linux 2023"**
   - Chọn **"Amazon Linux 2023 AMI"**

4. **Copy AMI ID:**
   - Bạn sẽ thấy AMI ID, ví dụ: `ami-0c55b159cbfafe1f0`
   - Copy AMI ID này

5. **Thêm vào terraform.tfvars:**
   ```hcl
   ami_id = "ami-0c55b159cbfafe1f0"
   ```

### Cách 2: Dùng CloudShell trong AWS Console

1. Trong AWS Console, click icon **CloudShell** (terminal icon ở top bar)
2. Chạy lệnh:
   ```bash
   aws ec2 describe-images \
     --region us-east-1 \
     --owners amazon \
     --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=virtualization-type,Values=hvm" \
     --query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
     --output text
   ```
3. Copy AMI ID từ output
4. Thêm vào `terraform.tfvars`

### Cách 3: Dùng Script (Nếu AWS CLI đã configure)

```powershell
.\scripts\get-ami-id.ps1 -Region us-east-1
```

## Các Bước Thực Hiện

### Bước 1: Tạo terraform.tfvars

```powershell
cd infrastructure/terraform/environments/dev
Copy-Item terraform.tfvars.example terraform.tfvars
```

### Bước 2: Thêm AMI ID

Mở `terraform.tfvars` và thêm:

```hcl
ami_id = "ami-0c55b159cbfafe1f0"  # Thay bằng AMI ID bạn lấy được
```

**Lưu ý:** AMI ID khác nhau cho mỗi region. Đảm bảo bạn lấy đúng region `us-east-1`.

### Bước 3: Test lại Terraform Plan

```powershell
terraform plan
```

Bây giờ sẽ không còn lỗi permission nữa!

## AMI IDs Tham Khảo (Có thể đã cũ)

**⚠️ Lưu ý:** AMI IDs thay đổi theo thời gian. Luôn kiểm tra trong AWS Console để lấy AMI ID mới nhất.

- **us-east-1:** `ami-0c55b159cbfafe1f0` (có thể đã cũ)

## Kiểm Tra AMI ID Có Đúng Không

Sau khi thêm AMI ID, test:

```powershell
terraform validate
terraform plan
```

Nếu AMI ID sai, bạn sẽ thấy lỗi:
```
Error: InvalidAMIID.NotFound: The image id 'ami-xxxxx' does not exist
```

## Troubleshooting

### Lỗi: "InvalidAMIID.NotFound"

**Nguyên nhân:** AMI ID không đúng hoặc không tồn tại trong region

**Giải pháp:**
1. Kiểm tra lại region: `us-east-1`
2. Lấy AMI ID mới từ AWS Console
3. Đảm bảo chọn đúng "Amazon Linux 2023" (không phải 2022)

### Lỗi: "AMI ID not found in region"

**Nguyên nhân:** AMI ID thuộc region khác

**Giải pháp:**
- Mỗi region có AMI ID riêng
- Lấy AMI ID từ region bạn đang dùng (`us-east-1`)

## Tài Liệu Tham Khảo

- [AWS EC2 AMI Documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
- [Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)

