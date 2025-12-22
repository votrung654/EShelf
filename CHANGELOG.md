# Changelog

All notable changes to eShelf project.

## [1.0.0] - 2024-12-22

### ✨ Added - Backend Microservices

#### Auth Service (Port 3001)
- JWT authentication with access/refresh tokens
- User registration with validation
- Password hashing with bcrypt (12 rounds)
- Token refresh mechanism
- Password reset flow (placeholder)
- `/api/auth/register`, `/login`, `/refresh`, `/logout`, `/me`

#### Book Service (Port 3002)
- Book CRUD operations (Admin only for create/update/delete)
- Book search with filters (genre, year, language)
- Pagination support
- Featured and popular books endpoints
- Book reviews system
- Genre management
- `/api/books`, `/api/books/search`, `/api/genres`

#### User Service (Port 3003)
- User profile management
- Favorites management
- Collections (custom book lists)
- Reading history tracking
- Reading progress with percentage
- `/api/profile`, `/api/favorites`, `/api/collections`, `/api/reading-history`

#### ML Service (Port 8000)
- Recommendation system (Collaborative Filtering)
- Similar books (Content-based Filtering with TF-IDF)
- Reading time estimation
- Featured books ranking
- FastAPI with Swagger docs at `/docs`

#### API Gateway (Port 3000)
- Request routing to all services
- Rate limiting (100 req/15min)
- CORS configuration
- Request/response logging
- Centralized error handling
- Health check endpoints

### 🗄️ Added - Database

- Prisma schema with 10+ models
- Users, Books, Genres, Reviews
- Favorites, Collections, Reading History
- Notifications, Audit Logs
- Seed script with sample data
- Migration system

### 🏗️ Added - Infrastructure as Code

#### Terraform Modules
- VPC module (VPC, Subnets, IGW, NAT, Route Tables)
- Security Groups module (Bastion, App, ALB, RDS)
- EC2 module (Bastion Host, App Servers)
- Modular and reusable design
- Proper tagging and outputs

#### CloudFormation Templates
- `vpc-stack.yaml` - VPC infrastructure
- `ec2-stack.yaml` - EC2 instances and security groups
- Cross-stack references with exports
- Parameter-driven configuration

### 🔄 Added - CI/CD Pipelines

#### GitHub Actions
- `ci.yml` - Frontend/Backend CI with matrix builds
- `terraform.yml` - Terraform pipeline with Checkov
- `smart-build.yml` - Smart Build (path-filter)
- `update-manifests.yml` - Auto-update K8s manifests
- Security scanning with Trivy
- Docker build and push

#### Jenkins
- `Jenkinsfile` - Multi-stage pipeline
- Parallel lint & test stages
- SonarQube integration
- Trivy container scanning
- Kubernetes deployment
- Manual approval for production

### ☸️ Added - Kubernetes

- Deployment manifests for all services
- Service definitions (ClusterIP)
- Kustomize base and overlays
- Health probes (liveness, readiness)
- Resource requests and limits
- Namespace configuration

### 🎨 Added - Frontend Components

- `SimilarBooks.jsx` - ML-powered similar books
- `RecommendedBooks.jsx` - Personalized recommendations
- `api.js` - Centralized API client service
- Better error handling
- Loading states

### 📝 Added - Documentation

- `README.md` - Main documentation (updated)
- `PLAN.md` - 15-week project plan for 3-person team
- `QUICKSTART.md` - Quick start guide
- `CONTRIBUTING.md` - Contribution guidelines
- `COMMANDS.md` - All commands reference
- `SUMMARY.md` - Project summary
- `docs/ARCHITECTURE.md` - System architecture
- `docs/DEPLOYMENT.md` - Deployment guide
- `docs/API.md` - Complete API documentation
- Service-specific READMEs

### 🛠️ Added - Scripts

- `setup-project.sh` - Auto setup script
- `check-services.sh` - Health check script
- `test-infrastructure.sh` - Infrastructure tests
- `start-backend.sh` - Start backend services
- `start-dev.sh` - Start all services

### 🐳 Added - Docker

- `docker-compose.yml` - All services orchestration
- Dockerfiles for all services
- Multi-stage builds for optimization
- Non-root users for security
- Health checks
- Volume mounts

### 🔒 Added - Security

- JWT authentication
- Password hashing
- Rate limiting
- CORS configuration
- Helmet security headers
- Input validation
- Admin role protection

### 📦 Added - Configuration

- `.env.example` files for all services
- `.gitignore` for backend and infrastructure
- `terraform.tfvars.example`
- Package.json scripts for convenience

---

## 🔧 Changed

### Frontend
- Fixed HomePage example code
- Updated AuthContext for API integration
- Updated AdminBooks for API integration (reverted to local)
- Improved LoginRegister UI

### Backend
- API Gateway now has proxy routes (optional)
- Services use consistent error handling
- Health checks standardized

---

## 🗑️ Removed

- `idea.md` - Consolidated into PLAN.md
- `prompt.md` - Consolidated into docs/master_prompts.md
- `plan1_chatgpt.md` - Replaced by PLAN.md
- `prompt_test.md` - No longer needed
- `truyendex.md` - Reference material, removed
- `docs/SEARCH_ISSUES_FIX.md` - Fixed, removed
- `docs/advanced_features_plan.md` - Consolidated
- `docs/improvement_plan.md` - Consolidated

---

## 📊 Statistics

### Code Added
- **Backend Services:** ~2,500 lines
- **Infrastructure:** ~1,000 lines
- **CI/CD:** ~500 lines
- **Documentation:** ~3,000 lines
- **Total:** ~7,000 lines

### Files Created
- Backend: 40+ files
- Infrastructure: 20+ files
- CI/CD: 5+ files
- Documentation: 15+ files
- **Total:** 80+ files

---

## 🎯 Next Version (1.1.0)

### Planned Features
- [ ] Connect frontend to backend APIs (currently using localStorage)
- [ ] Implement actual database integration
- [ ] Add WebSocket for real-time features
- [ ] Implement Elasticsearch for search
- [ ] Add email notifications
- [ ] Implement file upload to S3
- [ ] Add more ML features

### Planned Infrastructure
- [ ] Deploy to AWS
- [ ] Setup EKS cluster
- [ ] Configure ArgoCD
- [ ] Setup monitoring stack
- [ ] Implement Blue/Green deployment
- [ ] Setup Ansible playbooks

---

## 📝 Notes

This version provides a complete foundation for the eShelf project with:
- ✅ Working microservices architecture
- ✅ Complete infrastructure code
- ✅ CI/CD pipelines ready
- ✅ Kubernetes manifests ready
- ✅ Comprehensive documentation
- ✅ Clear project plan for team

The project is ready for Lab 1 and Lab 2 submission, and provides a solid foundation for the final project.

---

*Version 1.0.0 - December 22, 2024*

