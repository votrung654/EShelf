# 📝 Tổng hợp Commands

Tất cả commands cần thiết cho eShelf project.

---

## 🚀 SETUP & RUN

### Setup Project (Lần đầu)

```bash
# Clone
git clone https://github.com/levanvux/eShelf.git
cd eShelf

# Auto setup
npm run setup

# Or manual
npm install
cd backend/services/api-gateway && npm install
cd backend/services/auth-service && npm install
cd backend/services/book-service && npm install
cd backend/services/user-service && npm install
cd backend/services/ml-service && pip install -r requirements.txt
```

### Start Development

```bash
# Frontend
npm run dev

# Backend (Docker)
npm run backend:start

# Backend (Manual - 5 terminals)
cd backend/services/api-gateway && npm run dev
cd backend/services/auth-service && npm run dev
cd backend/services/book-service && npm run dev
cd backend/services/user-service && npm run dev
cd backend/services/ml-service && uvicorn src.main:app --reload
```

### Stop Services

```bash
# Stop Docker
npm run backend:stop

# Or
cd backend && docker-compose down
```

### Check Services Health

```bash
npm run check

# Or manual
curl http://localhost:3000/health
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
curl http://localhost:8000/health
```

---

## 🏗️ INFRASTRUCTURE (LAB 1)

### Terraform

```bash
cd infrastructure/terraform/environments/dev

# Initialize
terraform init

# Format
terraform fmt -recursive

# Validate
terraform validate

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Outputs
terraform output

# Destroy
terraform destroy
```

### CloudFormation

```bash
cd infrastructure/cloudformation

# Validate
aws cloudformation validate-template \
  --template-body file://templates/vpc-stack.yaml

# Deploy VPC
aws cloudformation create-stack \
  --stack-name eshelf-vpc-dev \
  --template-body file://templates/vpc-stack.yaml

# Wait
aws cloudformation wait stack-create-complete \
  --stack-name eshelf-vpc-dev

# Deploy EC2
aws cloudformation create-stack \
  --stack-name eshelf-ec2-dev \
  --template-body file://templates/ec2-stack.yaml \
  --parameters ParameterKey=KeyPairName,ParameterValue=your-key

# Get outputs
aws cloudformation describe-stacks \
  --stack-name eshelf-vpc-dev \
  --query 'Stacks[0].Outputs'

# Delete
aws cloudformation delete-stack --stack-name eshelf-ec2-dev
aws cloudformation delete-stack --stack-name eshelf-vpc-dev
```

### Test Infrastructure

```bash
bash scripts/test-infrastructure.sh
```

---

## 🔄 CI/CD (LAB 2)

### GitHub Actions

```bash
# Trigger manually
git push origin main

# View workflow runs
gh run list

# View logs
gh run view <run-id>
```

### Jenkins

```bash
# Start Jenkins (Docker)
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts

# Get initial password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Access: http://localhost:8080
```

### Security Scanning

```bash
# Checkov (Terraform)
checkov -d infrastructure/terraform

# Trivy (Docker)
trivy image eshelf/api-gateway:latest

# SonarQube
sonar-scanner \
  -Dsonar.projectKey=eshelf \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000
```

---

## ☸️ KUBERNETES

### Deploy

```bash
# Using Kustomize
kubectl apply -k infrastructure/kubernetes/overlays/dev

# Using Helm
helm install eshelf infrastructure/helm/eshelf \
  --namespace eshelf \
  --create-namespace

# Verify
kubectl get all -n eshelf
```

### Manage

```bash
# Get pods
kubectl get pods -n eshelf

# Get services
kubectl get svc -n eshelf

# View logs
kubectl logs -f deployment/api-gateway -n eshelf

# Describe
kubectl describe pod <pod-name> -n eshelf

# Execute command in pod
kubectl exec -it <pod-name> -n eshelf -- sh

# Port forward
kubectl port-forward svc/api-gateway 3000:3000 -n eshelf
```

### Scale

```bash
# Manual scale
kubectl scale deployment api-gateway --replicas=3 -n eshelf

# Autoscale
kubectl autoscale deployment api-gateway \
  --cpu-percent=70 \
  --min=2 \
  --max=10 \
  -n eshelf

# Check HPA
kubectl get hpa -n eshelf
```

### Rollback

```bash
# View history
kubectl rollout history deployment/api-gateway -n eshelf

# Rollback
kubectl rollout undo deployment/api-gateway -n eshelf

# Rollback to specific revision
kubectl rollout undo deployment/api-gateway --to-revision=2 -n eshelf
```

---

## 🐳 DOCKER

### Build Images

```bash
# Build all
cd backend
docker-compose build

# Build specific service
docker build -t eshelf/auth-service backend/services/auth-service

# Tag for registry
docker tag eshelf/auth-service harbor.yourdomain.com/eshelf/auth-service:v1.0.0
```

### Push to Registry

```bash
# Login
docker login harbor.yourdomain.com

# Push
docker push harbor.yourdomain.com/eshelf/auth-service:v1.0.0
```

### Docker Compose

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Logs
docker-compose logs -f

# Restart service
docker-compose restart auth-service

# Rebuild and restart
docker-compose up -d --build auth-service
```

---

## 🗄️ DATABASE

### Prisma

```bash
cd backend/database

# Generate client
npm run db:generate

# Create migration
npm run db:migrate

# Deploy migrations
npm run db:migrate:deploy

# Seed data
npm run db:seed

# Reset database
npm run db:reset

# Prisma Studio (GUI)
npm run db:studio
```

### PostgreSQL

```bash
# Connect to database
psql postgresql://eshelf:eshelf123@localhost:5432/eshelf

# Backup
pg_dump -U eshelf eshelf > backup.sql

# Restore
psql -U eshelf eshelf < backup.sql

# Docker exec
docker exec -it backend-postgres-1 psql -U eshelf
```

---

## 🧪 TESTING

### Frontend

```bash
# Run tests
npm test

# Coverage
npm run test:coverage

# E2E tests
npm run test:e2e
```

### Backend

```bash
# Test specific service
cd backend/services/auth-service
npm test

# Integration tests
npm run test:integration

# Load testing with K6
k6 run tests/load-test.js
```

### Infrastructure

```bash
# Run test suite
bash scripts/test-infrastructure.sh

# Terraform validate
terraform validate

# CloudFormation lint
cfn-lint infrastructure/cloudformation/templates/*.yaml
```

---

## 📊 MONITORING

### Prometheus

```bash
# Port forward
kubectl port-forward svc/prometheus-kube-prometheus-prometheus \
  -n monitoring 9090:9090

# Access: http://localhost:9090
```

### Grafana

```bash
# Port forward
kubectl port-forward svc/prometheus-grafana \
  -n monitoring 3000:80

# Access: http://localhost:3000
# Default: admin/prom-operator
```

### Logs (Loki)

```bash
# Query logs
logcli query '{namespace="eshelf"}'

# Follow logs
logcli query --follow '{app="api-gateway"}'
```

---

## 🔧 TROUBLESHOOTING

### Kill Port

```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:3000 | xargs kill -9
```

### Docker Issues

```bash
# Remove all containers
docker rm -f $(docker ps -aq)

# Remove all images
docker rmi -f $(docker images -q)

# Clean system
docker system prune -a --volumes

# Restart Docker Desktop
```

### Git Issues

```bash
# Discard changes
git checkout .

# Reset to remote
git fetch origin
git reset --hard origin/main

# Clean untracked files
git clean -fd
```

---

## 🎯 USEFUL ALIASES

Add to `.bashrc` or `.zshrc`:

```bash
# eShelf aliases
alias eshelf-start="cd ~/eShelf && npm run dev"
alias eshelf-backend="cd ~/eShelf/backend && docker-compose up -d"
alias eshelf-check="cd ~/eShelf && npm run check"
alias eshelf-logs="cd ~/eShelf/backend && docker-compose logs -f"

# Kubernetes
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get svc"
alias kgd="kubectl get deployments"
alias kl="kubectl logs -f"

# Docker
alias dc="docker-compose"
alias dcu="docker-compose up -d"
alias dcd="docker-compose down"
alias dcl="docker-compose logs -f"
```

---

## 📚 QUICK REFERENCE

### Service Ports

| Service | Port |
|---------|------|
| Frontend | 5173 |
| API Gateway | 3000 |
| Auth Service | 3001 |
| Book Service | 3002 |
| User Service | 3003 |
| ML Service | 8000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Jenkins | 8080 |
| Grafana | 3000 |
| Prometheus | 9090 |

### Important Files

| File | Purpose |
|------|---------|
| `package.json` | Frontend dependencies & scripts |
| `docker-compose.yml` | Backend services orchestration |
| `PLAN.md` | Project plan (3-person team) |
| `README.md` | Main documentation |
| `QUICKSTART.md` | Quick start guide |

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature

# Commit
git add .
git commit -m "feat: add feature"

# Push
git push origin feature/your-feature

# Create PR on GitHub
```

---

*Keep this file handy for quick reference!*

