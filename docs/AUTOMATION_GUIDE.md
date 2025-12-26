# Hướng Dẫn Tự Động Hóa Cập Nhật Resources

## Câu Hỏi: Có Cách Nào Tự Động Cập Nhật Resources/Region Không?

**Trả lời ngắn gọn:** Có! Có 3 cách chính:

### 1. ✅ Script Tự Động (Đã Tạo - Khuyến Nghị)

Chúng ta đã tạo script `scripts/auto-update-terraform-config.ps1` để tự động query AWS và cập nhật `terraform.tfvars`:

```powershell
# Tự động cập nhật terraform.tfvars từ AWS resources
.\scripts\auto-update-terraform-config.ps1 -Region us-east-1
```

**Script này sẽ tự động:**
- Tìm default VPC trong region
- Lấy tất cả subnets (public/private)
- Lấy security groups
- Lấy availability zones
- Lấy AMI ID mới nhất
- Cập nhật `terraform.tfvars` tự động

**Khi nào dùng:**
- Khi chuyển region
- Khi VPC/subnets thay đổi
- Khi muốn cập nhật AMI ID mới nhất

### 2. Terraform Data Sources (Tự Động Hoàn Toàn)

Terraform có thể tự động query AWS resources bằng **data sources**:

```hcl
# Tự động tìm default VPC
data "aws_vpc" "default" {
  default = true
}

# Tự động tìm subnets trong VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Tự động lấy AMI ID mới nhất
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
```

**Ưu điểm:**
- Hoàn toàn tự động, không cần cập nhật thủ công
- Luôn lấy resources mới nhất

**Nhược điểm:**
- Cần quyền AWS (DescribeVpcs, DescribeSubnets, DescribeImages)
- Trong AWS Academy có thể bị hạn chế quyền

**Hiện tại:** Code đã có data sources cho VPC, nhưng subnets và AMI vẫn dùng hardcode vì hạn chế quyền.

### 3. External Data Source (Script + Terraform)

Có thể dùng `external` data source để chạy script và lấy kết quả:

```hcl
data "external" "aws_resources" {
  program = ["powershell", "${path.module}/scripts/get-aws-resources.ps1"]
  
  query = {
    region = var.aws_region
  }
}
```

**Khi nào dùng:**
- Khi cần logic phức tạp
- Khi AWS CLI có sẵn nhưng Terraform data sources bị hạn chế

## So Sánh Các Phương Pháp

| Phương Pháp | Tự Động | Cần Quyền AWS | Dễ Dùng | Khuyến Nghị |
|------------|---------|---------------|---------|-------------|
| Script PowerShell | ⭐⭐⭐ | ⭐ | ⭐⭐⭐ | ✅ Cho AWS Academy |
| Terraform Data Sources | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ✅ Cho production |
| External Data Source | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⚠️ Phức tạp hơn |

## Hướng Dẫn Sử Dụng Script Tự Động

### Cập Nhật Terraform Config

```powershell
# Cập nhật terraform.tfvars cho region mới
.\scripts\auto-update-terraform-config.ps1 -Region us-east-1 -TerraformDir infrastructure\terraform\environments\dev
```

### Cập Nhật Ansible Inventory

```powershell
# Tự động cập nhật Ansible inventory từ Terraform outputs
.\scripts\update-ansible-inventory.ps1 -Environment dev
```

## Workflow Đề Xuất

### Khi Chuyển Region:

1. **Chạy script tự động:**
   ```powershell
   .\scripts\auto-update-terraform-config.ps1 -Region us-east-1
   ```

2. **Review và chỉnh sửa nếu cần:**
   ```powershell
   notepad infrastructure\terraform\environments\dev\terraform.tfvars
   ```

3. **Chạy Terraform:**
   ```powershell
   cd infrastructure\terraform\environments\dev
   terraform plan
   terraform apply
   ```

4. **Cập nhật Ansible inventory:**
   ```powershell
   .\scripts\update-ansible-inventory.ps1 -Environment dev
   ```

### Khi Resources Thay Đổi:

1. **Chạy script tự động** để cập nhật
2. **Review changes** với `terraform plan`
3. **Apply** nếu OK

## Lưu Ý

⚠️ **Script tự động không thể:**
- Tạo resources mới (chỉ query existing)
- Xử lý logic phức tạp (như chọn subnets theo tiêu chí)
- Bypass IAM permissions

✅ **Script tự động có thể:**
- Query default VPC và subnets
- Lấy security groups
- Cập nhật AMI ID mới nhất
- Cập nhật file config tự động

## Tài Liệu Tham Khảo

- [Terraform AWS Data Sources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources)
- [Terraform External Data Source](https://www.terraform.io/docs/language/data-sources/external.html)
- Scripts: `scripts/auto-update-terraform-config.ps1`, `scripts/update-ansible-inventory.ps1`

