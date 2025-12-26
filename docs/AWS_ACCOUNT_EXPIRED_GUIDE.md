# Hướng Dẫn Khi AWS Account Hết Hạn

## ⚠️ Vấn Đề

Nếu tài khoản AWS của bạn hết hạn hoặc không có quyền truy cập, **deployment sẽ KHÔNG thành công**.

## 🔍 Kiểm Tra Trạng Thái

### 1. Kiểm tra AWS Account

```powershell
aws sts get-caller-identity
```

**Nếu thành công:** Account vẫn hoạt động
**Nếu lỗi:** Account có vấn đề (hết hạn, không có quyền, credentials sai)

### 2. Kiểm tra EC2 Instances

```powershell
aws ec2 describe-instances --region us-east-1 --filters "Name=tag:Name,Values=eshelf-*" --query "Reservations[*].Instances[*].[InstanceId,State.Name]" --output table
```

**Các trạng thái có thể:**
- `running` - Instance đang chạy (OK)
- `stopped` - Instance đã dừng (có thể do hết credit)
- `terminated` - Instance đã bị xóa
- `pending` - Instance đang khởi động

## 🚨 Hậu Quả Khi Account Hết Hạn

1. **EC2 Instances:**
   - Có thể bị dừng tự động (stopped)
   - Có thể bị terminate sau một thời gian
   - Không thể tạo instances mới

2. **K3s Deployment:**
   - Commands đã gửi có thể không chạy được
   - Cluster không thể hoàn thành deployment
   - Không thể truy cập instances qua SSM

3. **Applications:**
   - Không thể deploy lên cluster
   - Không thể sử dụng AWS services

## ✅ Giải Pháp

### Option 1: Gia Hạn/Activate Account

1. Đăng nhập AWS Console
2. Kiểm tra billing/credits
3. Nếu là AWS Academy/Educate:
   - Kiểm tra lab credits
   - Request thêm credits nếu cần
   - Đợi account được activate lại

### Option 2: Sử Dụng Account Mới

1. Tạo AWS account mới (hoặc dùng account khác)
2. Configure AWS CLI với credentials mới:
   ```powershell
   aws configure
   ```
3. Chạy lại Terraform để tạo infrastructure mới:
   ```powershell
   cd infrastructure\terraform\environments\dev
   terraform apply
   ```

### Option 3: Cleanup và Bắt Đầu Lại

Nếu account cũ không thể dùng:

1. **Destroy infrastructure cũ (nếu có quyền):**
   ```powershell
   cd infrastructure\terraform\environments\dev
   terraform destroy
   ```

2. **Với account mới, chạy lại từ đầu:**
   - Bước 1-3: Setup tools và Terraform
   - Bước 4: Deploy K3s cluster
   - Bước 5: Deploy applications

## 📋 Checklist Khi Account Hết Hạn

- [ ] Kiểm tra AWS account status
- [ ] Kiểm tra EC2 instances status
- [ ] Kiểm tra billing/credits
- [ ] Quyết định: Gia hạn hay dùng account mới
- [ ] Nếu dùng account mới: Configure AWS CLI
- [ ] Nếu dùng account mới: Chạy lại Terraform apply
- [ ] Verify infrastructure đã được tạo
- [ ] Chạy lại deployment scripts

## 🔗 Tài Liệu Tham Khảo

- **AWS Academy:** Kiểm tra lab credits trong AWS Academy portal
- **AWS Educate:** Kiểm tra credits trong AWS Educate account
- **AWS Free Tier:** Có giới hạn 12 tháng, sau đó tính phí

## 💡 Lưu Ý

- AWS Academy/Educate accounts thường có giới hạn credits
- Khi hết credits, instances có thể bị dừng tự động
- Nên monitor credits thường xuyên
- Backup kubeconfig và important data trước khi account hết hạn



