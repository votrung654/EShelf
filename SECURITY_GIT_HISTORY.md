# Xử Lý Thông Tin Nhạy Cảm Trong Git History

## Vấn Đề

Nếu bạn đã commit thông tin nhạy cảm (credentials, passwords, API keys) vào Git và push lên remote repository, thông tin đó vẫn tồn tại trong lịch sử commit ngay cả khi bạn đã xóa trong commit mới nhất.

**Bất kỳ ai có quyền truy cập repository đều có thể xem lịch sử commit và lấy thông tin nhạy cảm.**

## Giải Pháp

### 1. Kiểm Tra Git History

```powershell
# Tìm kiếm credentials trong toàn bộ git history
git log --all --full-history --source --pretty=format:"%H" | ForEach-Object {
    git show $_ | Select-String -Pattern "password|secret|key|credential" -CaseSensitive:$false
}
```

### 2. Xóa Thông Tin Nhạy Cảm Khỏi Git History

**CẢNH BÁO:** Các phương pháp sau sẽ **viết lại lịch sử Git**. Nếu repository đã được chia sẻ, bạn cần:
- Thông báo cho tất cả collaborators
- Force push (có thể gây conflict)
- Cân nhắc tạo repository mới nếu cần

#### Phương Pháp 1: Sử dụng git filter-branch (Built-in)

```powershell
# Xóa file chứa credentials khỏi toàn bộ history
git filter-branch --force --index-filter `
  "git rm --cached --ignore-unmatch DEMO_GUIDE.md" `
  --prune-empty --tag-name-filter cat -- --all

# Xóa file credentials cụ thể
git filter-branch --force --index-filter `
  "git rm --cached --ignore-unmatch aws-academy-credentials.txt" `
  --prune-empty --tag-name-filter cat -- --all
```

#### Phương Pháp 2: Sử dụng BFG Repo-Cleaner (Khuyên dùng - Nhanh hơn)

1. Download BFG: https://rtyley.github.io/bfg-repo-cleaner/

2. Xóa file:
   ```powershell
   java -jar bfg.jar --delete-files aws-academy-credentials.txt
   ```

3. Xóa text trong file:
   ```powershell
   # Tạo file passwords.txt chứa các passwords cần xóa
   echo "3ZJ7)y2GAjsk#P+^aD8y" > passwords.txt
   java -jar bfg.jar --replace-text passwords.txt
   ```

4. Clean up:
   ```powershell
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   ```

#### Phương Pháp 3: Tạo Repository Mới (Đơn giản nhất)

Nếu repository chưa có nhiều collaborators:

1. Tạo repository mới
2. Copy code hiện tại (không có credentials)
3. Push lên repository mới
4. Xóa repository cũ

### 3. Sau Khi Xóa

```powershell
# Force push (CẨN THẬN - sẽ ghi đè remote history)
git push origin --force --all
git push origin --force --tags
```

**Lưu ý:** 
- Thông báo cho tất cả collaborators trước khi force push
- Họ cần re-clone repository sau khi bạn force push

### 4. Rotate Credentials (Quan Trọng!)

**Ngay cả khi đã xóa khỏi Git history, bạn VẪN CẦN:**

1. **Đổi password/credentials** đã bị lộ
2. **Revoke API keys** cũ
3. **Tạo credentials mới**
4. **Cập nhật tất cả nơi sử dụng**

### 5. Best Practices Để Tránh Vấn Đề Này

1. **Sử dụng .gitignore** ngay từ đầu
2. **Không commit credentials** - dùng environment variables hoặc secrets management
3. **Sử dụng pre-commit hooks** để scan credentials:
   ```powershell
   # Cài đặt git-secrets
   git secrets --install
   git secrets --register-aws
   ```
4. **Review code trước khi commit**
5. **Sử dụng GitHub Secrets** cho CI/CD

## Tài Liệu Tham Khảo

- [GitHub: Removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [git-secrets](https://github.com/awslabs/git-secrets)

