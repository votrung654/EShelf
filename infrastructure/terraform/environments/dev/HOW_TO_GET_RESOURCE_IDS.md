# Hướng Dẫn Lấy Resource IDs Từ AWS Console

Vì bạn không có quyền query qua AWS CLI, bạn cần lấy các resource IDs từ AWS Console.

## 1. Lấy Subnet IDs

1. Đăng nhập vào AWS Console
2. Vào **VPC** service
3. Click **Subnets** ở menu bên trái
4. Filter bằng VPC ID: `vpc-08fb2bec5fb5a49dc`
5. Copy các **Subnet ID** (ví dụ: `subnet-12345678`)
6. Bạn cần ít nhất 2 subnets
7. Cập nhật trong `terraform.tfvars`:
   ```hcl
   use_existing_subnets = true
   existing_public_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]
   existing_private_subnet_ids = ["subnet-xxxxx", "subnet-yyyyy"]  # Có thể dùng chung với public
   ```

## 2. Lấy Security Group ID

1. Đăng nhập vào AWS Console
2. Vào **EC2** service
3. Click **Security Groups** ở menu bên trái
4. Filter bằng VPC ID: `vpc-08fb2bec5fb5a49dc`
5. Tìm security group có tên **"default"** (default security group của VPC)
6. Copy **Security Group ID** (ví dụ: `sg-12345678`)
7. Cập nhật trong `terraform.tfvars`:
   ```hcl
   use_existing_security_groups = true
   existing_bastion_sg_id = "sg-xxxxx"
   existing_app_sg_id = "sg-xxxxx"  # Có thể dùng chung
   existing_alb_sg_id = "sg-xxxxx"  # Có thể dùng chung
   existing_k3s_master_sg_id = "sg-xxxxx"  # Có thể dùng chung
   existing_k3s_worker_sg_id = "sg-xxxxx"  # Có thể dùng chung
   existing_rds_sg_id = "sg-xxxxx"  # Có thể dùng chung
   ```

**Lưu ý:** Bạn có thể dùng cùng một security group (default) cho tất cả các instances. Điều này sẽ cho phép tất cả traffic trong VPC.

## 3. Kiểm Tra Default Security Group Rules

Default security group thường có:
- **Inbound:** Cho phép tất cả traffic từ chính nó (self)
- **Outbound:** Cho phép tất cả traffic

Nếu cần mở thêm ports (như SSH port 22), bạn có thể:
1. Vào Security Group > Edit inbound rules
2. Thêm rule cho SSH (port 22) từ IP của bạn hoặc 0.0.0.0/0

## 4. Sau Khi Cập Nhật terraform.tfvars

Chạy lại:
```powershell
cd infrastructure/terraform/environments/dev
terraform plan
```

Nếu plan thành công, chạy:
```powershell
terraform apply
```

