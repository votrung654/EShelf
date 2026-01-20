# Chi Tiết Các Công Cụ, Cấu Hình và Quy Trình Tích Hợp - eShelf Project

## Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [Công Cụ CI/CD](#công-cụ-cicd)
3. [Công Cụ Build & Development](#công-cụ-build--development)
4. [Công Cụ Infrastructure](#công-cụ-infrastructure)
5. [Công Cụ Monitoring & Observability](#công-cụ-monitoring--observability)
6. [Công Cụ Security](#công-cụ-security)
7. [Quy Trình Tích Hợp](#quy-trình-tích-hợp)
8. [Cấu Hình Chi Tiết](#cấu-hình-chi-tiết)

---

## Tổng Quan

Project eShelf sử dụng một hệ sinh thái công cụ DevOps/MLOps đầy đủ để tự động hóa quy trình phát triển, build, test, deploy và monitor. Tài liệu này giải thích chi tiết từng công cụ, chức năng, cấu hình code và cách chúng tích hợp vào quy trình tổng thể.

---

## Công Cụ CI/CD

### 1. GitHub Actions

#### Chức Năng
- **Tự động hóa CI/CD pipeline** khi có code changes
- **Smart Build System**: Chỉ build services có thay đổi code thực sự
- **Multi-environment support**: Dev, Staging, Production
- **Security scanning**: Tự động scan code và Docker images
- **Automated testing**: Lint, test, build validation

#### Cấu Hình Chi Tiết

##### 1.1. Smart Build Pipeline (`.github/workflows/smart-build.yml`)

**Trigger Events:**
```yaml
on:
  push:
    branches: [main, develop]
    paths-ignore:  # Bỏ qua các file không cần build
      - 'README.md'
      - '*.md'
      - 'docs/**'
  pull_request:
    branches: [main]
```

**Cơ Chế Smart Build:**

**Bước 1: Path Filtering** (Nhanh, filter theo đường dẫn file)
```yaml
- uses: dorny/paths-filter@v2
  id: filter
  with:
    filters: |
      frontend:
        - 'src/**'
        - 'public/**'
        - 'index.html'
        - 'package.json'
        - 'vite.config.js'
      api-gateway:
        - 'backend/services/api-gateway/**'
      # ... các services khác
```

**Bước 2: Code Change Detection** (Kiểm tra code thực sự, bỏ qua comment)
```bash
# Script: scripts/check-service-changes.sh
# Chức năng:
# 1. So sánh diff giữa commits
# 2. Loại bỏ các thay đổi chỉ là comment hoặc whitespace
# 3. Chỉ build nếu có code changes thực sự

# Logic:
- Lấy diff: git diff BASE_REF HEAD -- service_path
- Loại bỏ dòng comment: grep -vE '^[[:space:]]*//'
- Loại bỏ whitespace: sed '/^[[:space:]]*$/d'
- Kiểm tra còn code thực sự không
```

**Bước 3: Conditional Build Jobs**
```yaml
build-api-gateway:
  needs: changes
  if: needs.changes.outputs.api-gateway == 'true' && 
      github.event_name == 'push' && 
      (github.ref == 'refs/heads/main' || 
       github.ref == 'refs/heads/staging' || 
       github.ref == 'refs/heads/develop')
```

**Environment Tag Determination:**
```yaml
- name: Determine environment tag
  id: env
  run: |
    if [ "${{ github.ref }}" = "refs/heads/main" ]; then
      echo "env=prod" >> $GITHUB_OUTPUT
    elif [ "${{ github.ref }}" = "refs/heads/staging" ]; then
      echo "env=staging" >> $GITHUB_OUTPUT
    else
      echo "env=dev" >> $GITHUB_OUTPUT
    fi
```

**Docker Build & Push:**
```yaml
- name: Build and push Docker image
  run: |
    ENV_TAG="${{ steps.env.outputs.env }}"
    IMAGE_NAME="docker.io/22521571/eshelf-api-gateway"
    SHA_TAG="${{ github.sha }}"
    
    # Build với multiple tags
    docker build -t $IMAGE_NAME:$ENV_TAG \
                  -t $IMAGE_NAME:$SHA_TAG \
                  backend/services/api-gateway/
    
    # Push tất cả tags
    docker push $IMAGE_NAME:$ENV_TAG
    docker push $IMAGE_NAME:$SHA_TAG
    docker push $IMAGE_NAME:latest || true
```

**Tích Hợp Vào Quy Trình:**
```
Developer commit code
    ↓
GitHub Actions trigger
    ↓
Path Filter (nhanh) → Detect service changes
    ↓
Code Change Check (chi tiết) → Verify real code changes
    ↓
Conditional Build → Chỉ build services có changes
    ↓
Docker Build → Build images với env tags
    ↓
Push to Registry → Docker Hub hoặc Harbor
    ↓
ArgoCD Image Updater → Detect new images
    ↓
Update Manifests → Auto-update kustomization.yaml
    ↓
ArgoCD Sync → Deploy to Kubernetes
```

##### 1.2. CI Pipeline (`.github/workflows/ci.yml`)

**Chức Năng:**
- **PR Validation**: Chỉ chạy lint, test, không deploy
- **Security Scanning**: Trivy filesystem scan
- **Code Quality**: ESLint, TypeScript check

**Matrix Strategy cho Backend Services:**
```yaml
lint-and-test-backend:
  strategy:
    matrix:
      service: [api-gateway, auth-service, book-service, user-service]
  steps:
    - name: Install dependencies
      working-directory: backend/services/${{ matrix.service }}
      run: npm ci
    
    - name: Lint
      working-directory: backend/services/${{ matrix.service }}
      run: npm run lint
      continue-on-error: true
```

**Security Scan với Trivy:**
```yaml
security-scan:
  steps:
    - name: Run Trivy filesystem scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'
    
    - name: Upload Trivy results
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: 'trivy-results.sarif'
```

**Tích Hợp:**
```
Pull Request created
    ↓
CI Pipeline trigger
    ↓
Lint & Test (all services in parallel)
    ↓
Security Scan (Trivy)
    ↓
Results → GitHub Security tab
    ↓
PR checks pass/fail
```

##### 1.3. Update Manifests Workflow (`.github/workflows/update-manifests.yml`)

**Chức Năng:**
- Tự động update Kubernetes manifests với image tags mới
- Chạy sau khi Smart Build Pipeline thành công

**Cấu Hình:**
```yaml
on:
  workflow_run:
    workflows: ["Smart Build Pipeline"]
    types: [completed]
    branches: [main]

jobs:
  update-manifests:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Update image tags
        run: |
          IMAGE_TAG="${{ github.sha }}"
          REGISTRY="${{ secrets.HARBOR_REGISTRY }}"
          
          # Update deployment manifests
          yq eval ".spec.template.spec.containers[0].image = \
            \"${REGISTRY}/eshelf/api-gateway:${IMAGE_TAG}\"" \
            -i infrastructure/kubernetes/base/api-gateway-deployment.yaml
```

**Tích Hợp:**
```
Smart Build Pipeline success
    ↓
Update Manifests workflow trigger
    ↓
Update kustomization.yaml với image tags mới
    ↓
Commit changes to Git
    ↓
ArgoCD detect Git changes
    ↓
Auto-sync to cluster
```

---

### 2. ArgoCD (GitOps)

#### Chức Năng
- **GitOps Deployment**: Deploy từ Git repository
- **Auto-sync**: Tự động sync khi Git có thay đổi
- **Multi-environment**: Quản lý Dev, Staging, Prod
- **Self-heal**: Tự động khôi phục về desired state
- **Rollback**: Dễ dàng rollback về version trước

#### Cấu Hình Chi Tiết

##### 2.1. ArgoCD Application (`infrastructure/kubernetes/argocd/applications/api-gateway-app.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: api-gateway
  namespace: argocd
  annotations:
    # Image Updater annotations
    argocd-image-updater.argoproj.io/image-list: |
      api-gateway=docker.io/22521571/eshelf-api-gateway
    argocd-image-updater.argoproj.io/api-gateway.update-strategy: digest
    argocd-image-updater.argoproj.io/api-gateway.allow-tags-regex: '^dev$'
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main
    argocd-image-updater.argoproj.io/write-back-target: kustomization
spec:
  project: default
  source:
    repoURL: https://github.com/votrung654/EShelf.git
    targetRevision: main
    path: infrastructure/kubernetes/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: eshelf-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Giải Thích:**
- **source.repoURL**: Git repository chứa manifests
- **source.path**: Kustomize overlay path (dev/staging/prod)
- **syncPolicy.automated**: Tự động sync khi Git có thay đổi
- **syncPolicy.selfHeal**: Tự động khôi phục nếu cluster bị thay đổi manual

##### 2.2. ArgoCD Image Updater Config (`infrastructure/kubernetes/argocd/image-updater-config.yaml`)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-image-updater-config
  namespace: argocd
data:
  registries.conf: |
    registries:
    - name: Docker Hub
      prefix: docker.io
      api_url: https://registry-1.docker.io
      credentials: ext:/scripts/dockerhub-creds
      default: true
  git.user: github-actions[bot]
  git.email: github-actions[bot]@users.noreply.github.com
  git.commit_message: "chore: update image tags to {{.Tag}}"
  git.branch: main
  log.level: info
```

**Chức Năng:**
- **Monitor Registry**: Theo dõi Docker Hub/Harbor cho images mới
- **Write-back to Git**: Tự động commit image tags mới vào Git
- **Update Strategy**: 
  - `digest`: Theo dõi bằng image digest (tránh lỗi semantic version)
  - `semver`: Theo dõi semantic version tags

**Quy Trình Image Updater:**
```
Docker image pushed to registry
    ↓
ArgoCD Image Updater poll registry (mỗi 3 phút)
    ↓
Detect new image với tag matching regex
    ↓
Update kustomization.yaml với image tag mới
    ↓
Commit to Git repository
    ↓
ArgoCD detect Git changes
    ↓
Auto-sync to Kubernetes cluster
    ↓
Rolling update deployment
```

---

### 3. Harbor (Container Registry)

#### Chức Năng
- **Container Registry**: Lưu trữ Docker images
- **Image Scanning**: Tự động scan vulnerabilities với Trivy
- **Access Control**: Quản lý quyền truy cập
- **Project Organization**: Tổ chức images theo projects

#### Cấu Hình

**Harbor Deployment** (`infrastructure/kubernetes/harbor/`):
- Harbor Core service
- Harbor Registry service
- Harbor Database (PostgreSQL)
- Harbor Redis cache
- Harbor Nginx ingress

**Image Naming Convention:**
```
harbor-core.harbor.svc.cluster.local/eshelf/<service>:<tag>
```

**Tích Hợp với GitHub Actions:**
```yaml
- name: Login to Harbor
  uses: docker/login-action@v3
  with:
    registry: ${{ secrets.HARBOR_REGISTRY }}
    username: ${{ secrets.HARBOR_USERNAME }}
    password: ${{ secrets.HARBOR_PASSWORD }}

- name: Build and push Docker image
  run: |
    docker build -t ${{ secrets.HARBOR_REGISTRY }}/eshelf/api-gateway:${{ github.sha }} .
    docker push ${{ secrets.HARBOR_REGISTRY }}/eshelf/api-gateway:${{ github.sha }}
```

---

## Công Cụ Build & Development

### 1. Vite (Frontend Build Tool)

#### Chức Năng
- **Fast Build**: Build tool nhanh cho React
- **Hot Module Replacement (HMR)**: Hot reload trong development
- **Code Splitting**: Tự động split code
- **Environment Variables**: Support .env files

#### Cấu Hình (`vite.config.js`)

```javascript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
```

**Giải Thích:**
- **plugins**: Sử dụng `@vitejs/plugin-react` để build React
- **Default config**: Vite tự động detect `index.html` và `src/`
- **Build output**: `dist/` directory

**Environment Variables:**
```bash
# .env.development
VITE_API_URL=http://localhost:3000/api

# .env.production
VITE_API_URL=https://api.eshelf.example.com/api
```

**Tích Hợp:**
```
npm run dev
    ↓
Vite dev server start (port 5173)
    ↓
HMR enabled → Auto reload on file changes
    ↓
npm run build
    ↓
Vite build → dist/ folder
    ↓
Docker build → Copy dist/ vào nginx image
```

---

### 2. TailwindCSS (CSS Framework)

#### Chức Năng
- **Utility-first CSS**: Viết CSS bằng utility classes
- **Dark Mode**: Support dark mode với `dark:` prefix
- **Purge CSS**: Tự động loại bỏ unused CSS
- **Responsive**: Mobile-first responsive design

#### Cấu Hình (`tailwind.config.js`)

```javascript
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',  // Dark mode bằng class
  theme: {
    extend: {},  // Extend default theme
  },
  plugins: [],
};
```

**Giải Thích:**
- **content**: Files để Tailwind scan tìm classes
- **darkMode: 'class'**: Dark mode được toggle bằng class `dark`
- **theme.extend**: Thêm custom colors, spacing, etc.

**PostCSS Config** (`postcss.config.js`):
```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
    ...(process.env.NODE_ENV === "production" ? { cssnano: {} } : {}),
  },
};
```

**Tích Hợp:**
```
TailwindCSS scan content files
    ↓
Generate CSS với utility classes được sử dụng
    ↓
PostCSS process (autoprefixer, cssnano)
    ↓
Output: Optimized CSS file
```

---

### 3. ESLint (Code Linting)

#### Chức Năng
- **Code Quality**: Kiểm tra code quality và best practices
- **React Rules**: React-specific linting rules
- **Auto-fix**: Tự động fix một số lỗi

#### Cấu Hình (`eslint.config.js`)

```javascript
import js from '@eslint/js'
import globals from 'globals'
import react from 'eslint-plugin-react'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'

export default [
  { 
    ignores: [
      'dist',
      'backend/**',
      'node_modules/**',
      'scripts/**',
      'infrastructure/**',
    ] 
  },
  {
    files: ['src/**/*.{js,jsx}', 'public/**/*.{js,jsx}'],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
      parserOptions: {
        ecmaVersion: 'latest',
        ecmaFeatures: { jsx: true },
        sourceType: 'module',
      },
    },
    settings: { react: { version: '18.3' } },
    plugins: {
      react,
      'react-hooks': reactHooks,
      'react-refresh': reactRefresh,
    },
    rules: {
      ...js.configs.recommended.rules,
      ...react.configs.recommended.rules,
      ...react.configs['jsx-runtime'].rules,
      ...reactHooks.configs.recommended.rules,
      'react/jsx-no-target-blank': 'off',
      'react-refresh/only-export-components': ['warn', { allowConstantExport: true }],
    },
  },
]
```

**Giải Thích:**
- **ignores**: Files/folders không cần lint
- **files**: Files cần lint (chỉ frontend)
- **plugins**: React, React Hooks, React Refresh plugins
- **rules**: Kết hợp recommended rules + custom rules

**Tích Hợp:**
```
npm run lint
    ↓
ESLint scan src/ và public/
    ↓
Check rules violations
    ↓
Report errors/warnings
    ↓
CI Pipeline: Fail nếu có errors
```

---

## Công Cụ Infrastructure

### 1. Terraform (Infrastructure as Code)

#### Chức Năng
- **Provision AWS Resources**: EC2, VPC, Security Groups
- **K3s Cluster Setup**: Tạo K3s cluster trên AWS
- **Multi-environment**: Dev, Staging, Prod environments

#### Cấu Hình

**Terraform Modules** (`infrastructure/terraform/modules/`):
- `ec2-instance/`: EC2 instance module
- `k3s-cluster/`: K3s cluster module
- `vpc/`: VPC module
- `security-group/`: Security group module

**Environment Configs** (`infrastructure/terraform/environments/dev/`):
```hcl
module "k3s_cluster" {
  source = "../../modules/k3s-cluster"
  
  cluster_name = "eshelf-dev"
  master_count = 1
  worker_count = 2
  instance_type = "t3.medium"
  # ...
}
```

**Tích Hợp:**
```
terraform init
    ↓
terraform plan
    ↓
terraform apply
    ↓
Create AWS resources
    ↓
Output kubeconfig
    ↓
Ansible setup K3s
```

---

### 2. Ansible (Configuration Management)

#### Chức Năng
- **K3s Installation**: Cài đặt K3s trên EC2 instances
- **Configuration**: Cấu hình cluster, nodes
- **Package Management**: Cài đặt packages cần thiết

#### Cấu Hình

**Playbooks** (`infrastructure/ansible/playbooks/`):
- `k3s-install.yml`: Install K3s
- `k3s-configure.yml`: Configure K3s
- `setup-harbor.yml`: Setup Harbor
- `setup-argocd.yml`: Setup ArgoCD

**Inventory** (`infrastructure/ansible/inventory/dev.ini`):
```ini
[master]
master-1 ansible_host=10.0.1.10

[workers]
worker-1 ansible_host=10.0.1.11
worker-2 ansible_host=10.0.1.12

[k3s_cluster:children]
master
workers
```

**Tích Hợp:**
```
Terraform create EC2 instances
    ↓
Ansible inventory update
    ↓
Ansible playbook run
    ↓
Install K3s on nodes
    ↓
Configure cluster
    ↓
Deploy applications
```

---

### 3. Kubernetes (K3s)

#### Chức Năng
- **Container Orchestration**: Quản lý containers
- **Service Discovery**: DNS-based service discovery
- **Load Balancing**: Built-in load balancer
- **Auto-scaling**: Horizontal Pod Autoscaler

#### Cấu Hình

**Kustomize Base** (`infrastructure/kubernetes/base/`):
- Base manifests cho tất cả environments
- Deployment, Service, ConfigMap, Secret

**Kustomize Overlays** (`infrastructure/kubernetes/overlays/dev/`):
```yaml
# kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namespace: eshelf-dev

images:
  - name: eshelf/api-gateway
    newTag: dev

replicas:
  - name: dev-api-gateway
    count: 2
```

**Tích Hợp:**
```
Kustomize build overlays/dev
    ↓
Generate manifests với dev configs
    ↓
ArgoCD apply manifests
    ↓
Kubernetes create resources
    ↓
Pods running
```

---

## Công Cụ Monitoring & Observability

### 1. Prometheus

#### Chức Năng
- **Metrics Collection**: Thu thập metrics từ pods
- **Time Series Database**: Lưu trữ time series data
- **Alerting Rules**: Định nghĩa alert rules

#### Cấu Hình

**ServiceMonitor** (`infrastructure/kubernetes/monitoring/`):
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-gateway-metrics
spec:
  selector:
    matchLabels:
      app: api-gateway
  endpoints:
    - port: metrics
      interval: 30s
```

**Tích Hợp:**
```
Pods expose metrics endpoint (/metrics)
    ↓
Prometheus scrape metrics (mỗi 30s)
    ↓
Store in time series database
    ↓
Grafana query Prometheus
    ↓
Visualize metrics
```

---

### 2. Grafana

#### Chức Năng
- **Visualization**: Dashboards cho metrics
- **Alerting**: Alert notifications
- **Logs**: Query logs từ Loki

#### Cấu Hình

**Data Sources:**
- Prometheus: Metrics
- Loki: Logs

**Dashboards:**
- Kubernetes cluster metrics
- Application metrics
- Service health

**Tích Hợp:**
```
Grafana connect to Prometheus
    ↓
Query PromQL queries
    ↓
Display graphs, tables
    ↓
Set up alerts
    ↓
Send notifications
```

---

### 3. Loki

#### Chức Năng
- **Log Aggregation**: Tập trung logs từ tất cả pods
- **Log Querying**: Query logs với LogQL
- **Label-based Indexing**: Index logs bằng labels

#### Cấu Hình

**Promtail** (Log collector):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
data:
  promtail.yml: |
    server:
      http_listen_port: 3101
    clients:
      - url: http://loki:3100/loki/api/v1/push
    scrape_configs:
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
```

**Tích Hợp:**
```
Promtail collect logs từ pods
    ↓
Send to Loki
    ↓
Loki store logs
    ↓
Grafana query Loki
    ↓
Display logs
```

---

## Công Cụ Security

### 1. Trivy

#### Chức Năng
- **Vulnerability Scanning**: Scan Docker images và filesystem
- **CVE Detection**: Phát hiện Common Vulnerabilities and Exposures
- **SBOM Generation**: Software Bill of Materials

#### Cấu Hình

**GitHub Actions:**
```yaml
- name: Run Trivy filesystem scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'sarif'
    severity: 'CRITICAL,HIGH'
```

**Harbor Integration:**
- Harbor tự động scan images khi push
- Hiển thị vulnerabilities trong Harbor UI

**Tích Hợp:**
```
Docker image build
    ↓
Trivy scan image
    ↓
Detect vulnerabilities
    ↓
Report to GitHub Security tab
    ↓
Harbor scan on push
    ↓
Block push nếu có critical vulnerabilities
```

---

### 2. Checkov

#### Chức Năng
- **IaC Scanning**: Scan Terraform, CloudFormation
- **Security Best Practices**: Kiểm tra security best practices
- **Compliance**: Check compliance với standards

#### Cấu Hình

**GitHub Actions:**
```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    directory: infrastructure/terraform
    framework: terraform
```

**Tích Hợp:**
```
Terraform code changes
    ↓
Checkov scan
    ↓
Check security best practices
    ↓
Report violations
    ↓
Block deployment nếu có critical issues
```

---

### 3. SonarQube

#### Chức Năng
- **Code Quality**: Phân tích code quality
- **Code Coverage**: Measure test coverage
- **Technical Debt**: Tính toán technical debt

#### Cấu Hình

**SonarQube Deployment** (`infrastructure/kubernetes/sonarqube/`):
- SonarQube server
- PostgreSQL database
- Persistent volumes

**Tích Hợp:**
```
Code changes
    ↓
SonarQube scan
    ↓
Analyze code quality
    ↓
Generate report
    ↓
Quality gate pass/fail
```

---

## Quy Trình Tích Hợp

### Quy Trình CI/CD Hoàn Chỉnh

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workflow                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  1. Developer commit code          │
        │     git commit -m "feat: ..."     │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  2. Push to GitHub                │
        │     git push origin feature-branch│
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  3. Create Pull Request           │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  4. GitHub Actions: PR Pipeline   │
        │     - Path Filter (detect changes) │
        │     - Code Change Check            │
        │     - Lint & Test (only changed)   │
        │     - Security Scan (Trivy)       │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  5. PR Checks Pass                │
        │     - All tests pass              │
        │     - No security issues           │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  6. Merge to main                 │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  7. GitHub Actions: Push Pipeline│
        │     - Smart Build (only changed)   │
        │     - Docker Build                │
        │     - Push to Registry            │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  8. Harbor Registry               │
        │     - Store Docker images         │
        │     - Scan vulnerabilities        │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  9. ArgoCD Image Updater          │
        │     - Poll registry               │
        │     - Detect new images           │
        │     - Update kustomization.yaml  │
        │     - Commit to Git               │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  10. ArgoCD Auto-sync             │
        │      - Detect Git changes         │
        │      - Sync to Kubernetes         │
        │      - Rolling update             │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  11. Kubernetes Deployment         │
        │      - Create new pods            │
        │      - Health checks              │
        │      - Terminate old pods          │
        └───────────────────────────────────┘
                            │
                            ▼
        ┌───────────────────────────────────┐
        │  12. Monitoring                   │
        │      - Prometheus collect metrics │
        │      - Grafana visualize          │
        │      - Loki collect logs          │
        └───────────────────────────────────┘
```

### Quy Trình Smart Build Chi Tiết

```
Code Change Detection:
┌─────────────────────────────────────────────┐
│ 1. Path Filter (dorny/paths-filter)          │
│    - Fast filtering by file paths            │
│    - Output: frontend=true/false             │
│              api-gateway=true/false          │
│              ...                              │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│ 2. Code Change Check (check-service-changes) │
│    - git diff BASE_REF HEAD                  │
│    - Remove comment lines                    │
│    - Remove whitespace-only changes         │
│    - Check if real code remains              │
│    - Output: true (build) / false (skip)    │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│ 3. Conditional Build Jobs                   │
│    - if: needs.changes.outputs.api-gateway  │
│      == 'true'                               │
│    - Only build changed services             │
│    - Skip unchanged services                 │
└─────────────────────────────────────────────┘
```

### Quy Trình GitOps với ArgoCD

```
Git Repository (Source of Truth)
        │
        │ (ArgoCD monitors)
        ▼
┌───────────────────────────────────┐
│  ArgoCD Application               │
│  - Source: Git repo + path        │
│  - Destination: K8s cluster        │
│  - Sync Policy: Auto              │
└───────────────────────────────────┘
        │
        │ (Sync)
        ▼
┌───────────────────────────────────┐
│  Kubernetes Cluster               │
│  - Deployments                    │
│  - Services                        │
│  - ConfigMaps                      │
└───────────────────────────────────┘
        │
        │ (Self-heal)
        ▼
┌───────────────────────────────────┐
│  If manual changes detected       │
│  → Revert to Git state            │
└───────────────────────────────────┘
```

### Quy Trình Image Updater

```
Docker Image Push to Registry
        │
        │ (Poll every 3 minutes)
        ▼
┌───────────────────────────────────┐
│  ArgoCD Image Updater             │
│  - Check registry for new images   │
│  - Match tag regex                 │
│  - Get image digest                │
└───────────────────────────────────┘
        │
        │ (Update manifest)
        ▼
┌───────────────────────────────────┐
│  Update kustomization.yaml        │
│  - Change image tag               │
│  - Commit to Git                  │
└───────────────────────────────────┘
        │
        │ (Git change detected)
        ▼
┌───────────────────────────────────┐
│  ArgoCD Auto-sync                 │
│  - Apply updated manifest         │
│  - Rolling update deployment      │
└───────────────────────────────────┘
```

---

## Cấu Hình Chi Tiết

### Environment Variables

#### Frontend (.env files)
```bash
# .env.development
VITE_API_URL=http://localhost:3000/api

# .env.production
VITE_API_URL=https://api.eshelf.example.com/api
```

#### Backend Services (.env files)
```bash
# backend/services/api-gateway/.env
PORT=3000
AUTH_SERVICE_URL=http://auth-service:3001
BOOK_SERVICE_URL=http://book-service:3002
USER_SERVICE_URL=http://user-service:3003
ML_SERVICE_URL=http://ml-service:8000
```

#### GitHub Secrets
```bash
DOCKERHUB_USERNAME=22521571
DOCKERHUB_TOKEN=<token>
HARBOR_REGISTRY=harbor.example.com
HARBOR_USERNAME=admin
HARBOR_PASSWORD=<password>
```

### Dockerfile Examples

#### Frontend Dockerfile
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Backend Service Dockerfile
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "src/index.js"]
```

### Kubernetes Manifests Structure

```
infrastructure/kubernetes/
├── base/                    # Base manifests
│   ├── api-gateway-deployment.yaml
│   ├── api-gateway-service.yaml
│   └── ...
├── overlays/                # Environment-specific
│   ├── dev/
│   │   └── kustomization.yaml
│   ├── staging/
│   │   └── kustomization.yaml
│   └── prod/
│       └── kustomization.yaml
└── argocd/                  # ArgoCD configs
    ├── applications/
    └── image-updater-config.yaml
```

### Scripts Utilities

#### check-service-changes.sh
```bash
# Chức năng: Kiểm tra service có code changes thực sự
# Input: Service paths, base ref
# Output: 0 (có changes) / 1 (không có changes)

# Logic:
1. git diff để lấy changed files
2. Filter config/build files (luôn cần build)
3. Với code files:
   - Loại bỏ comment lines
   - Loại bỏ whitespace-only changes
   - Kiểm tra còn code thực sự không
4. Return exit code
```

#### quick-check.ps1
```powershell
# Chức năng: Quick check cluster status
# Checks:
- kubectl get nodes
- kubectl get pods -A
- kubectl get applications -n argocd
- Service health checks
```

---

## Tổng Kết

### Các Công Cụ Chính

| Công Cụ | Chức Năng | Vị Trí Trong Quy Trình |
|---------|-----------|------------------------|
| **GitHub Actions** | CI/CD automation | Trigger → Build → Deploy |
| **Smart Build** | Optimize builds | Detect changes → Conditional build |
| **ArgoCD** | GitOps deployment | Git → Kubernetes |
| **Image Updater** | Auto-update images | Registry → Git → Deploy |
| **Harbor** | Container registry | Store & scan images |
| **Prometheus** | Metrics collection | Collect → Store |
| **Grafana** | Visualization | Query → Display |
| **Loki** | Log aggregation | Collect → Store → Query |
| **Trivy** | Security scanning | Scan → Report |
| **Terraform** | Infrastructure as Code | Provision → Configure |
| **Ansible** | Configuration management | Setup → Configure |
| **K3s** | Container orchestration | Deploy → Manage |

### Lợi Ích Tích Hợp

1. **Tự Động Hóa**: Giảm manual work, tăng tốc độ deploy
2. **Tối Ưu**: Smart Build chỉ build services có changes
3. **An Toàn**: Security scanning tự động, GitOps audit trail
4. **Quan Sát**: Monitoring & logging đầy đủ
5. **Khả Năng Mở Rộng**: Dễ dàng thêm services, environments
6. **Phục Hồi**: Self-heal, rollback dễ dàng

### Best Practices

1. **Always use Smart Build**: Không build services không thay đổi
2. **Git as Source of Truth**: Tất cả configs trong Git
3. **Security First**: Scan trước khi deploy
4. **Monitor Everything**: Metrics và logs cho tất cả services
5. **Environment Parity**: Dev, Staging, Prod giống nhau
6. **Documentation**: Giữ docs cập nhật

---

**Tài liệu này cung cấp cái nhìn toàn diện về các công cụ, cấu hình và quy trình tích hợp trong project eShelf. Mọi thay đổi về công cụ hoặc cấu hình nên được cập nhật trong tài liệu này.**





