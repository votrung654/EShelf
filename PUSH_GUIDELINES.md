# Hướng Dẫn Push Code và Tài Liệu

Tài liệu này liệt kê những gì nên và không nên push lên repository.

---

## Nên Push

### Code và Scripts
- [x] Source code (frontend, backend, ML service)
- [x] Infrastructure code (Terraform, CloudFormation, Ansible)
- [x] Kubernetes manifests
- [x] Dockerfiles và docker-compose.yml
- [x] CI/CD workflows (GitHub Actions, Jenkinsfile)
- [x] Utility scripts (PowerShell, Bash)
- [x] Configuration files (.gitignore, eslint.config.js, etc.)

### Tài Liệu Quan Trọng
- [x] README.md
- [x] docs/SETUP_GUIDE.md
- [x] docs/ARCHITECTURE.md
- [x] docs/ARCHITECTURE_DEEP_DIVE.md
- [x] docs/MANUAL_STEPS_GUIDE.md
- [x] docs/MANUAL_K3S_INSTALLATION.md
- [x] NEXT_STEPS.md
- [x] DEMO_GUIDE.md
- [x] DEMO_VIDEO_SCRIPT.md
- [x] PRESENTATION_SLIDES_CONTENT.md
- [x] STUDY_MATERIAL.md
- [x] REQUIREMENTS_COMPLIANCE.md
- [x] HARBOR_IMAGE_SETUP.md
- [x] backend/FRESH_CLONE_GUIDE.md
- [x] backend/ENV_SETUP.md
- [x] backend/TROUBLESHOOTING.md
- [x] infrastructure/ansible/README.md
- [x] infrastructure/kubernetes/*/README.md

### Scripts Documentation
- [x] scripts/README-SMART-BUILD.md
- [x] scripts/README-TEST-FRESH-CLONE.md

---

## Không Nên Push

### Sensitive Data
- [ ] `.env` files
- [ ] `terraform.tfvars` (có thể chứa sensitive data)
- [ ] `aws-academy-credentials.txt`
- [ ] SSH keys
- [ ] API keys và tokens
- [ ] Passwords và secrets

### Temporary Files
- [ ] `terraform.tfstate` và `terraform.tfstate.backup`
- [ ] `.terraform/` directory
- [ ] Log files từ scripts
- [ ] Temporary test files
- [ ] `node_modules/` (đã có trong .gitignore)

### Redundant Documentation
- [ ] Status files đã xóa (FINAL_STATUS.md, COMPLETION_SUMMARY.md, etc.)
- [ ] Duplicate documentation
- [ ] Old/outdated guides
- [ ] Personal notes

### Build Artifacts
- [ ] Docker images
- [ ] Compiled binaries
- [ ] Build outputs
- [ ] Coverage reports (có thể giữ nếu cần)

### IDE và Editor Files
- [ ] `.vscode/` (trừ settings chung)
- [ ] `.idea/`
- [ ] `*.swp`, `*.swo`
- [ ] `.DS_Store`

---

## Files Đã Xóa (Không Cần Push)

Các file sau đã được xóa vì dư thừa:
- FINAL_COMPLETION_REPORT.md
- COMPLETION_SUMMARY.md
- FINAL_STATUS.md
- DEPLOYMENT_STATUS.md
- DEPLOYMENT_STATUS_SUMMARY.md
- COMPLETED_TASKS.md
- SETUP_COMPLETE.md
- JENKINS_SONARQUBE_STATUS.md
- PUSH_IMAGES_EXPLANATION.md
- RESOURCE_OPTIMIZATION.md
- docs/WHAT_I_DID_AND_WHY.md
- docs/FINAL_INSTRUCTIONS.md

---

## Checklist Trước Khi Push

### Security Check
- [ ] Không có passwords trong code
- [ ] Không có API keys hardcoded
- [ ] `.env` files trong `.gitignore`
- [ ] `terraform.tfvars` trong `.gitignore` (nếu có sensitive data)
- [ ] Credentials files trong `.gitignore`

### Code Quality
- [ ] Code đã được lint
- [ ] Tests pass
- [ ] Không có console.logs debug
- [ ] Comments rõ ràng và cần thiết

### Documentation
- [ ] README.md updated
- [ ] Không có emoji trong documentation
- [ ] Văn phong chuyên nghiệp
- [ ] Không có "AI" style text

### Git
- [ ] Commit messages rõ ràng
- [ ] Không commit large files
- [ ] Branch naming convention
- [ ] PR description đầy đủ

---

## Best Practices

### Commit Messages
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`
- Be descriptive: "Add manual steps guide" thay vì "Update docs"
- Reference issues: "Fix #123: Image pull error"

### Branch Strategy
- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: Feature branches
- `fix/*`: Bug fixes

### Documentation
- Keep documentation updated với code changes
- Remove outdated information
- Add examples và use cases
- Include troubleshooting sections

---

## Lưu Ý

1. **Sensitive Data:** Luôn kiểm tra kỹ trước khi push. Nếu vô tình push sensitive data, rotate credentials ngay lập tức.

2. **Large Files:** Sử dụng Git LFS cho large files hoặc không commit chúng.

3. **Documentation:** Giữ documentation sạch sẽ, không dư thừa, và professional.

4. **Scripts:** Scripts nên có comments và error handling.

5. **Testing:** Test scripts và workflows trước khi push.

