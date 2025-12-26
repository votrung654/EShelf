# Báo Cáo Kiểm Tra Bảo Mật - Files Không Nên Push Lên Repo

**Ngày kiểm tra:** 2025-01-27

## Tóm Tắt

Kiểm tra các file hiện tại và lịch sử commit để tìm:
- Files chứa credentials/secrets
- Files lớn không cần thiết
- Files đã bị xóa nhưng vẫn còn trong git history

---

## VẤN ĐỀ NGHIÊM TRỌNG - CẦN XỬ LÝ NGAY

### 1. Hardcoded Passwords trong Kubernetes Configs

#### `infrastructure/kubernetes/harbor/harbor-values.yaml`
- **Dòng 77:** `harborAdminPassword: "Harbor12345"` (CẢNH BÁO)
- **Dòng 79:** `secretKey: "not-a-secure-key"` (CẢNH BÁO)
- **Dòng 82:** `password: "root123"` (database) (CẢNH BÁO)
- **Dòng 90:** `secret: "not-a-secure-secret"` (CẢNH BÁO)

**Hành động:** Di chuyển sang Kubernetes Secrets hoặc sử dụng external secret management.

#### `infrastructure/kubernetes/monitoring/grafana/grafana-deployment.yaml`
- **Dòng 93:** `admin-password: "admin123"` (CẢNH BÁO)

**Hành động:** Sử dụng Kubernetes Secrets thay vì hardcode.

#### `infrastructure/kubernetes/sonarqube/deployment.yaml`
- **Dòng 102:** `postgres-password: "sonarqube-password"` (CẢNH BÁO)

**Hành động:** Sử dụng Kubernetes Secrets.

#### `infrastructure/kubernetes/mlops/mlflow-deployment.yaml`
- **Dòng 152:** `aws-secret-access-key: "minioadmin"` (CẢNH BÁO)

**Hành động:** Sử dụng Kubernetes Secrets hoặc AWS Secrets Manager.

---

## VẤN ĐỀ CẦN LƯU Ý

### 2. Files Hiện Tại (OK - Chỉ là examples)

Các file sau là OK vì chỉ là examples:
- `aws-academy-credentials.example.txt` - Template file, không chứa real credentials
- `scripts/setup-harbor-credentials.sh` - Script sử dụng environment variables
- `CREDENTIALS_README.md` - Documentation
- Tất cả `.env.example` files - Template files

### 3. Lịch Sử Commit

#### Commits liên quan đến credentials:
- `50864c0` - `security: Remove sensitive credentials from DEMO_GUIDE.md` ✅ (Đã xóa)
- `849d30d` - `security: Remove sensitive credentials from DEMO_GUIDE.md` ✅ (Đã xóa)
- `e806775a` - `upload examples for .env` ✅ (Chỉ examples)

Lưu ý: File `DEMO_GUIDE.md` đã từng chứa credentials nhưng đã được xóa trong commit `50864c0`. Tuy nhiên, credentials vẫn còn trong git history.

---

## Files Đã Được Bảo Vệ Đúng Cách

1. **`.gitignore`** đã có các patterns:
   - `*.env` (trừ `.env.example`)
   - `terraform.tfvars` (trừ `.tfvars.example`)
   - `*.pem`, `*.key`
   - `aws-academy-credentials.txt` (trừ `.example.txt`)

2. **Tất cả files nhạy cảm hiện tại đều là `.example`** - OK

---

## HÀNH ĐỘNG CẦN THỰC HIỆN

### Ngay Lập Tức (High Priority)

1. **Xóa hardcoded passwords khỏi Kubernetes configs:**
   ```bash
   # Tạo Kubernetes Secrets thay vì hardcode
   kubectl create secret generic harbor-secrets \
     --from-literal=admin-password='<secure-password>' \
     --from-literal=secret-key='<secure-key>'
   ```

2. **Kiểm tra xem có file `.env` thực sự nào đã được commit:**
   ```powershell
   git log --all --full-history --name-only -- "*.env" | Select-String -Pattern "\.env$" -NotMatch "\.example"
   ```

3. **Xóa credentials khỏi git history (nếu cần):**
   - Xem file `SECURITY_GIT_HISTORY.md` để biết cách xử lý
   - Sử dụng `git filter-branch` hoặc BFG Repo-Cleaner

### Trung Hạn (Medium Priority)

1. **Rotate tất cả passwords đã bị hardcode:**
   - Harbor admin password
   - Grafana admin password
   - Database passwords
   - AWS credentials (nếu có)

2. **Thiết lập Secret Management:**
   - Sử dụng Kubernetes Secrets
   - Hoặc AWS Secrets Manager
   - Hoặc HashiCorp Vault

3. **Thiết lập pre-commit hooks:**
   ```bash
   # Cài đặt git-secrets
   git secrets --install
   git secrets --register-aws
   ```

### Dài Hạn (Low Priority)

1. **Security scanning tự động:**
   - Sử dụng GitHub Advanced Security
   - Hoặc tools như `truffleHog`, `git-secrets`

2. **Code review process:**
   - Đảm bảo không commit credentials
   - Review code trước khi merge

---

## 📊 Thống Kê

- **Files có hardcoded passwords:** 4 files
- **Files example (OK):** ~10 files
- **Commits liên quan credentials:** 3 commits (đã xử lý)
- **Files trong .gitignore:** ✅ Đã cấu hình đúng

---

## 🔗 Tài Liệu Tham Khảo

- Xem `SECURITY_GIT_HISTORY.md` để biết cách xóa credentials khỏi git history
- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [Kubernetes Secrets Best Practices](https://kubernetes.io/docs/concepts/configuration/secret/)

---

## ⚠️ CẢNH BÁO

**Nếu bạn đã push các file chứa hardcoded passwords lên GitHub:**
1. **ROTATE NGAY** tất cả passwords đã bị lộ
2. Xem xét xóa khỏi git history (theo hướng dẫn trong `SECURITY_GIT_HISTORY.md`)
3. Sử dụng Secret Management cho tất cả credentials

