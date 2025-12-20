# 📋 Master Prompts - Kế Hoạch Chi Tiết Dự Án eShelf

> **Phiên bản:** 2.0 (Tổng hợp & Cải tiến)  
> **Cập nhật:** Tháng 1/2025  
> **Mục đích:** Hướng dẫn từng bước hoàn thành dự án eShelf với DevOps + MLOps

---

## 📊 Tổng quan tiến độ

| Phase | Mô tả | Trạng thái | Prompts |
|-------|-------|------------|---------|
| **Phase 1** | Frontend Enhancement | ✅ **Hoàn thành** | 1.1-1.6 |
| **Phase 2** | Backend Services | ⏳ Tiếp theo | 2.1-2.6 |
| **Phase 3** | Database | 📋 Chờ | 3.1-3.3 |
| **Phase 4** | AI/ML Features | 📋 Chờ | 4.1-4.6 |
| **Phase 5** | DevOps Lab 1 (IaC) | 📋 Chờ | 5.1-5.10 |
| **Phase 6** | DevOps Lab 2 (CI/CD) | 📋 Chờ | 6.1-6.9 |
| **Phase 7** | Kubernetes & GitOps | 📋 Chờ | 7.1-7.8 |
| **Phase 8** | Monitoring & Observability | 📋 Chờ | 8.1-8.6 |
| **Phase 9** | MLOps Pipeline | 📋 Chờ | 9.1-9.6 |

---

## 🎯 PHASE 1: FRONTEND ENHANCEMENT ✅

### ✅ Prompt 1.1 - User Profile Page (Đã hoàn thành)
### ✅ Prompt 1.2 - Collections & Favorites (Đã hoàn thành)
### ✅ Prompt 1.3 - Reading Progress Tracker (Đã hoàn thành)
### ✅ Prompt 1.4 - Dark Mode Implementation (Đã hoàn thành)
### ✅ Prompt 1.5 - Admin Panel Layout & Dashboard (Đã hoàn thành)
### ✅ Prompt 1.6 - Admin Book Management (Đã hoàn thành)

---

## 🎯 PHASE 2: BACKEND SERVICES

### ✅ Prompt 2.1 - API Gateway Setup (Đã hoàn thành)

**Status:** ✅ Completed

**Implemented:**
- Express.js server with middleware chain
- CORS, Helmet, Morgan logging
- Rate limiting (100 req/15min per IP)
- Zod validation schemas
- Centralized error handling
- Health check endpoints
- Multi-stage Dockerfile

**Location:** `backend/services/api-gateway/`

**Known Issues:**
- Port 3000 conflict: Use `PORT=3001 npm run dev` or kill existing process

**Next:** Proceed to Prompt 2.2 - Auth Service

---

### Prompt 2.2 - Auth Service
```
Tạo Auth Service cho eShelf:

1. Cấu trúc backend/services/auth-service/
   ├── src/
   │   ├── controllers/authController.js
   │   ├── services/authService.js
   │   ├── middleware/validateToken.js
   │   ├── utils/jwt.js
   │   └── app.js
   ├── Dockerfile
   └── package.json

2. JWT Authentication:
   - Access token: 15 phút expiry
   - Refresh token: 7 ngày expiry
   - Token structure với user info

3. API Endpoints:
   - POST /register - tạo tài khoản mới
   - POST /login - đăng nhập
   - POST /refresh - làm mới access token
   - POST /logout - hủy refresh token
   - POST /forgot-password - gửi email reset
   - POST /reset-password - đặt lại mật khẩu

4. Password security:
   - bcrypt với salt rounds = 12
   - Password validation (8+ chars, uppercase, lowercase, number)

5. Error responses:
   - 400 Bad Request (validation errors)
   - 401 Unauthorized (invalid credentials)
   - 409 Conflict (duplicate email/username)
```

**✅ Kết quả:**
- Auth service chạy port 3001
- JWT tokens hoạt động
- Password hashed an toàn

**🧪 Test:**
```bash
# Register
curl -X POST http://localhost:3001/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test1234!","username":"testuser"}'

# Login
curl -X POST http://localhost:3001/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"Test1234!"}'

# Verify token at jwt.io
```

---

### Prompt 2.3 - User Service
```
Tạo User Service cho eShelf:

1. Cấu trúc backend/services/user-service/
2. API Endpoints:
   - GET /profile - lấy thông tin user (auth required)
   - PUT /profile - cập nhật profile
   - PUT /profile/avatar - upload avatar
   - GET /favorites - danh sách sách yêu thích
   - POST /favorites/:bookId - thêm yêu thích
   - DELETE /favorites/:bookId - xóa yêu thích
   - GET /collections - danh sách bộ sưu tập
   - POST /collections - tạo bộ sưu tập
   - GET /reading-history - lịch sử đọc
   - POST /reading-progress - lưu tiến độ đọc

3. JWT Middleware:
   - Verify access token
   - Extract user info
   - Attach to request

4. Database models (Prisma schema ready):
   - User, UserPreferences
   - Favorite, Collection, CollectionBook
   - ReadingHistory, ReadingProgress
```

**✅ Kết quả:**
- User service chạy port 3002
- CRUD profile hoạt động
- Favorites và Collections API ready

---

### Prompt 2.4 - Book Service
```
Tạo Book Service cho eShelf:

1. API Endpoints:
   - GET /books - list với pagination
   - GET /books/:id - chi tiết sách
   - GET /books/search?q=&genre=&year= - tìm kiếm
   - POST /books - tạo sách (admin only)
   - PUT /books/:id - sửa sách (admin only)
   - DELETE /books/:id - xóa sách (admin only)
   - POST /books/:id/review - thêm review
   - GET /books/:id/reviews - list reviews

2. File upload:
   - Cover images → S3/local storage
   - PDF files → S3/local storage
   - File validation (type, size)

3. Pagination format:
   {
     "data": [...],
     "pagination": {
       "page": 1,
       "limit": 10,
       "total": 100,
       "totalPages": 10
     }
   }

4. Search features:
   - Full-text search on title, author, description
   - Filter by genre, year, language
   - Sort by: relevance, date, rating
```

---

### Prompt 2.5 - Search Service (Elasticsearch)
```
Tạo Search Service với Elasticsearch:

1. Elasticsearch setup:
   - docker-compose với ES container
   - Index mapping cho books
   - Analyzer configuration (Vietnamese support)

2. API Endpoints:
   - GET /search?q= - full-text search
   - GET /autocomplete?q= - suggestions
   - GET /search/advanced - với filters

3. Index mapping:
   - title: text với edge_ngram
   - author: text
   - description: text
   - genres: keyword array
   - year: integer
   - language: keyword

4. Features:
   - Highlighting matched text
   - Fuzzy matching
   - Did you mean suggestions
   - Aggregations for facets
```

---

### Prompt 2.6 - Notification Service
```
Tạo Notification Service:

1. Email notifications:
   - Nodemailer setup (hoặc AWS SES)
   - Templates: welcome, password-reset, new-chapter
   - Queue với Bull/Redis

2. In-app notifications:
   - WebSocket connection
   - Real-time push
   - Notification types: system, book, social

3. API Endpoints:
   - GET /notifications - list user notifications
   - PUT /notifications/:id/read - mark as read
   - PUT /notifications/read-all - mark all read
   - DELETE /notifications/:id - delete

4. WebSocket events:
   - 'notification:new' - new notification
   - 'notification:read' - marked as read
```

---

## 🎯 PHASE 3: DATABASE

### Prompt 3.1 - Database Schema Design
```
Thiết kế Database Schema cho eShelf (PostgreSQL):

1. Tạo database/schemas/schema.sql với tables:

-- Users & Auth
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100),
  avatar_url TEXT,
  bio TEXT,
  role VARCHAR(20) DEFAULT 'user',
  email_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Books
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  isbn VARCHAR(20) UNIQUE,
  title VARCHAR(255) NOT NULL,
  author JSONB NOT NULL, -- ["Author 1", "Author 2"]
  description TEXT,
  cover_url TEXT,
  pdf_url TEXT,
  page_count INTEGER,
  language VARCHAR(10) DEFAULT 'vi',
  published_year INTEGER,
  publisher VARCHAR(100),
  rating_avg DECIMAL(3,2) DEFAULT 0,
  rating_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  download_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE genres (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) UNIQUE NOT NULL,
  slug VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50)
);

CREATE TABLE book_genres (
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  genre_id UUID REFERENCES genres(id) ON DELETE CASCADE,
  PRIMARY KEY (book_id, genre_id)
);

-- User Interactions
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  content TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

CREATE TABLE favorites (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, book_id)
);

CREATE TABLE collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE collection_books (
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  added_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (collection_id, book_id)
);

CREATE TABLE reading_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  current_page INTEGER DEFAULT 1,
  total_pages INTEGER,
  progress_percent DECIMAL(5,2) DEFAULT 0,
  time_spent_minutes INTEGER DEFAULT 0,
  last_read_at TIMESTAMP DEFAULT NOW(),
  started_at TIMESTAMP DEFAULT NOW(),
  finished_at TIMESTAMP,
  UNIQUE(user_id, book_id)
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Audit & Analytics
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id),
  action VARCHAR(50) NOT NULL,
  entity_type VARCHAR(50),
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

2. Indexes cho performance
3. Seed data script (50+ books, 10 users)
4. ERD diagram description
```

---

### Prompt 3.2 - Prisma ORM Setup
```
Setup Prisma ORM cho eShelf:

1. prisma/schema.prisma với tất cả models
2. prisma/migrations/ với versioned migrations
3. prisma/seed.ts với sample data
4. Connection pooling configuration
5. TypeScript types generated
6. Environment variable DATABASE_URL
```

---

### Prompt 3.3 - Database Migration System
```
Tạo Migration System:

1. Scripts:
   - scripts/db-migrate.sh - run migrations
   - scripts/db-rollback.sh - rollback last
   - scripts/db-seed.sh - seed data
   - scripts/db-reset.sh - reset database

2. CI/CD integration
3. Environment configs (dev/staging/prod)
```

---

## 🎯 PHASE 4: AI/ML FEATURES

### Prompt 4.1 - ML Service Setup (FastAPI)
```
Setup ML Service với Python FastAPI:

1. Cấu trúc backend/services/ml-service/
   ├── src/
   │   ├── api/
   │   │   ├── routes/
   │   │   │   ├── recommendations.py
   │   │   │   ├── similar.py
   │   │   │   ├── chat.py
   │   │   │   └── health.py
   │   │   └── main.py
   │   ├── models/
   │   │   └── schemas.py (Pydantic)
   │   ├── services/
   │   │   ├── recommender.py
   │   │   ├── similarity.py
   │   │   └── chat.py
   │   └── ml/
   │       ├── models/
   │       └── training/
   ├── requirements.txt
   ├── Dockerfile
   └── docker-compose.yml

2. FastAPI application:
   - Pydantic models cho request/response
   - CORS middleware
   - Health check endpoints

3. MLflow integration:
   - Experiment tracking
   - Model registry connection
   - Model loading from registry

4. Endpoints:
   - GET /health
   - POST /recommendations
   - POST /similar-books
   - POST /chat (AI assistant)
```

**✅ Kết quả:**
- FastAPI chạy port 8000
- Swagger docs tại /docs
- MLflow client connected

**🧪 Test:**
```bash
cd backend/services/ml-service
pip install -r requirements.txt
uvicorn src.api.main:app --reload

# Test health
curl http://localhost:8000/health

# Swagger docs
open http://localhost:8000/docs
```

---

### Prompt 4.2 - AI Chat Assistant (ChatPDF-style)
```
Tạo AI Chat Assistant cho eShelf:

Frontend:
1. src/components/ai/AIChatPanel.jsx
   - Floating widget góc phải
   - Collapse/expand animation
   - Chat input với send button
   - Message list với scroll
   - Loading indicator

2. src/components/ai/ChatMessage.jsx
   - User message (right-aligned, blue)
   - AI message (left-aligned, gray)
   - Markdown rendering
   - Code blocks support

3. Tích hợp vào Reading page:
   - Chat icon button
   - Context: current book, current page
   - "Highlight to ask AI" feature

Backend (ML Service):
1. POST /chat endpoint
   - Request: { message, book_id, page_number, context }
   - Response: { reply, sources }

2. OpenAI/Claude API integration:
   - API key từ environment
   - Rate limiting: 10 requests/hour (free tier)
   - Fallback response khi API down

3. Context management:
   - Book metadata as context
   - Current page content (nếu có)
   - Chat history (last 5 messages)

4. Prompt engineering:
   - System prompt: "Bạn là trợ lý đọc sách..."
   - Include book title, author
   - Limit response length
```

**✅ Kết quả:**
- Chat widget hoạt động
- AI trả lời context-aware
- Rate limiting active

**🧪 Test:**
```bash
# 1. Mở Reading page → thấy chat icon
# 2. Click → panel mở
# 3. Gõ "Tóm tắt sách này" → AI trả lời
# 4. F12 Network → verify API call
```

---

### Prompt 4.3 - Book Recommendation System
```
Implement Recommendation System:

1. Training pipeline:
   - ml/training/train_recommender.py
   - Collaborative Filtering (SVD algorithm)
   - Content-based (TF-IDF + cosine similarity)
   - Hybrid approach

2. Data preparation:
   - User-book interactions (views, favorites, reading time)
   - Book features (genres, description, author)
   - Rating matrix

3. Model training:
   - Train/test split
   - Hyperparameter tuning
   - Cross-validation
   - MLflow experiment tracking

4. API endpoint:
   - POST /recommendations
   - Input: user_id, n_items
   - Output: list of book_ids with scores

5. A/B testing setup:
   - 50% collaborative filtering
   - 50% hybrid
   - Track click-through rate
```

---

### Prompt 4.4 - Similar Books (Content-Based)
```
Implement Similar Books feature:

1. Preprocessing:
   - TF-IDF on book descriptions
   - Genre encoding
   - Author encoding

2. Similarity computation:
   - Cosine similarity matrix
   - Pre-compute và cache
   - Scheduled batch job (daily)

3. API endpoint:
   - GET /similar/{book_id}
   - Response: top 10 similar books

4. Caching:
   - Redis cache per book_id
   - TTL: 24 hours
   - Invalidate on book update

5. Fallback:
   - Same genre books nếu no data
   - Popular books nếu cold start
```

---

### Prompt 4.5 - Reading Time Estimation
```
Implement Reading Time Estimation:

1. ML Model:
   - Simple regression
   - Features: page_count, word_count, genre, avg_user_speed
   - Train on historical reading data

2. API endpoint:
   - GET /estimate-time/{book_id}
   - Response: { minutes: 45, confidence: 0.8 }

3. Frontend display:
   - "⏱️ ~45 phút đọc" trên book card
   - Per-chapter estimation trong detail

4. User personalization:
   - Track user's actual reading speed
   - Adjust estimates accordingly
```

---

### Prompt 4.6 - Smart Search (Semantic)
```
Implement Semantic Search:

1. Vector database setup:
   - Qdrant hoặc Pinecone
   - Book embeddings index

2. Embedding model:
   - sentence-transformers
   - Vietnamese support (phobert hoặc multilingual)

3. API endpoint:
   - GET /search/semantic?q=
   - Hybrid: keyword + semantic

4. Features:
   - "Sách về tình yêu tuổi trẻ" → semantic match
   - Relevance scores
   - "AI-powered search" toggle in UI
```

---

## 🎯 PHASE 5: DEVOPS - LAB 1 (Infrastructure as Code)

### Prompt 5.1 - Terraform VPC Module
```
Tạo Terraform VPC Module cho eShelf:

1. infrastructure/terraform/modules/vpc/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   └── README.md

2. Resources:
   - VPC với CIDR 10.0.0.0/16
   - DNS hostnames enabled
   - DNS support enabled

3. Subnets:
   - Public: 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b)
   - Private: 10.0.10.0/24 (AZ-a), 10.0.11.0/24 (AZ-b)
   - Database: 10.0.20.0/24 (AZ-a), 10.0.21.0/24 (AZ-b)

4. Internet Gateway attached

5. Proper tagging:
   - Name: ${project}-${resource}-${environment}
   - Environment, Project, ManagedBy tags
```

**✅ Kết quả:**
- VPC module reusable
- Multi-AZ subnets
- Proper outputs for other modules

**🧪 Test:**
```bash
cd infrastructure/terraform/modules/vpc
terraform init
terraform validate
# → Success!

checkov -d . --framework terraform
# → Passed: X, Failed: 0
```

---

### Prompt 5.2 - Terraform Route Tables & NAT Gateway
```
Tạo Terraform Networking Module:

1. infrastructure/terraform/modules/networking/

2. Public Route Table:
   - Route 0.0.0.0/0 → Internet Gateway
   - Associate với public subnets

3. NAT Gateway:
   - Elastic IP allocation
   - NAT Gateway trong public subnet

4. Private Route Table:
   - Route 0.0.0.0/0 → NAT Gateway
   - Associate với private subnets
```

---

### Prompt 5.3 - Terraform EC2 Module
```
Tạo Terraform EC2 Module:

1. infrastructure/terraform/modules/ec2/

2. Bastion Host:
   - t3.micro in public subnet
   - Public IP assigned
   - SSH key pair

3. App Server:
   - t3.small in private subnet
   - No public IP
   - User data script: install Docker, Node.js

4. AMI data source:
   - Amazon Linux 2023
   - Latest version
```

---

### Prompt 5.4 - Terraform Security Groups
```
Tạo Terraform Security Groups Module:

1. Bastion SG:
   - Ingress: SSH (22) from var.my_ip only
   - Egress: All traffic

2. App SG:
   - Ingress: SSH from Bastion SG
   - Ingress: 3000 from Bastion SG
   - Egress: All traffic

3. ALB SG:
   - Ingress: 80, 443 from 0.0.0.0/0
   - Egress: All traffic

4. RDS SG:
   - Ingress: 5432 from App SG
   - No egress

5. Checkov compliance annotations
```

---

### Prompt 5.5 - Terraform Environment Setup
```
Tạo Terraform Environment Configuration:

1. infrastructure/terraform/environments/dev/
   ├── main.tf (module calls)
   ├── variables.tf
   ├── outputs.tf
   ├── backend.tf (S3 + DynamoDB)
   ├── terraform.tfvars.example
   └── providers.tf

2. S3 backend:
   - Bucket: eshelf-terraform-state
   - Key: dev/terraform.tfstate
   - DynamoDB table for locking

3. .gitignore:
   - *.tfvars (except example)
   - .terraform/
   - *.tfstate*
```

---

### Prompt 5.6 - CloudFormation VPC Stack
```
Tạo CloudFormation VPC Template:

1. infrastructure/cloudformation/templates/vpc-stack.yaml

2. Parameters:
   - Environment
   - VpcCIDR
   - PublicSubnet1CIDR, PublicSubnet2CIDR
   - PrivateSubnet1CIDR, PrivateSubnet2CIDR

3. Resources:
   - VPC, Internet Gateway
   - 4 Subnets với proper tags
   - NAT Gateway với EIP

4. Outputs (exported for cross-stack):
   - VpcId
   - PublicSubnet1Id, PublicSubnet2Id
   - PrivateSubnet1Id, PrivateSubnet2Id
```

---

### Prompt 5.7 - CloudFormation EC2 Stack
```
Tạo CloudFormation EC2 Template:

1. infrastructure/cloudformation/templates/ec2-stack.yaml

2. Parameters:
   - VpcStackName (for imports)
   - KeyPairName
   - InstanceType

3. Resources:
   - Bastion EC2 với public IP
   - App EC2 trong private subnet
   - Security Groups inline
   - IAM Role + Instance Profile

4. UserData (base64 encoded)
```

---

### Prompt 5.8 - Infrastructure Test Cases
```
Tạo Test Cases cho Infrastructure:

1. infrastructure/tests/test_infrastructure.sh

2. Tests:
   - test_vpc_exists()
   - test_subnets_configured()
   - test_bastion_ssh_accessible()
   - test_private_ec2_via_bastion()
   - test_nat_gateway_working()
   - test_security_groups_rules()

3. Output format:
   - [PASS] green
   - [FAIL] red
   - Exit code for CI

4. Verbose mode với -v flag
```

---

### Prompt 5.9 - Ansible Server Provisioning
```
Tạo Ansible Playbooks cho eShelf:

1. infrastructure/ansible/
   ├── inventory/
   │   └── hosts.yml
   ├── playbooks/
   │   ├── common.yml
   │   ├── app-server.yml
   │   └── monitoring.yml
   ├── roles/
   │   ├── docker/
   │   ├── nginx/
   │   └── node-exporter/
   ├── group_vars/
   │   ├── all.yml
   │   └── app_servers.yml
   └── ansible.cfg

2. common.yml:
   - Update packages
   - Install Docker
   - Configure users
   - Setup firewall

3. app-server.yml:
   - Deploy application
   - Configure nginx
   - SSL certificates

4. Ansible Vault cho secrets
```

---

### Prompt 5.10 - AWS Secrets Manager
```
Tạo Secrets Management:

1. Terraform module: modules/secrets/

2. Secrets:
   - eshelf/database - DB credentials
   - eshelf/jwt - JWT secrets
   - eshelf/api-keys - External API keys

3. IAM policies cho access
4. Rotation configuration (30 days)
5. Application SDK integration
6. Kubernetes ExternalSecrets Operator
```

---

## 🎯 PHASE 6: DEVOPS - LAB 2 (CI/CD Automation)

### Prompt 6.1 - GitHub Actions Terraform Pipeline
```
Tạo GitHub Actions cho Terraform:

1. .github/workflows/terraform.yml

2. Triggers:
   - push to main (paths: infrastructure/terraform/**)
   - pull_request to main

3. Jobs:
   security-scan:
   - Checkov scan
   - Upload SARIF to Security tab

   terraform-plan:
   - terraform init
   - terraform validate
   - terraform plan
   - Comment plan output on PR

   terraform-apply:
   - Only on merge to main
   - terraform apply -auto-approve

4. AWS credentials via OIDC (no static keys)
```

---

### Prompt 6.2 - CloudFormation CodePipeline
```
Tạo AWS CodePipeline cho CloudFormation:

1. infrastructure/cloudformation/pipeline-stack.yaml

2. Stages:
   - Source: GitHub webhook
   - Build: CodeBuild với cfn-lint, taskcat
   - Deploy: CloudFormation CreateChangeSet + ExecuteChangeSet

3. buildspec.yml:
   - Install cfn-lint, taskcat
   - Validate templates
   - Run taskcat tests

4. taskcat.yml configuration
```

---

### Prompt 6.3 - Jenkins Pipeline Setup
```
Tạo Jenkins Pipeline cho eShelf:

1. jenkins/Jenkinsfile

2. Stages (parallel where possible):
   - Checkout
   - Lint & Test (Frontend + Backend parallel)
   - SonarQube Analysis
   - Docker Build
   - Security Scan (Trivy)
   - Push to ECR

3. Environment variables
4. Credentials management
5. Post actions (cleanup, notifications)
```

---

### Prompt 6.4 - Jenkins Security Scanning
```
Jenkins Pipeline - Security Scanning:

1. Trivy container scan:
   - Scan Docker images
   - Fail on CRITICAL, HIGH

2. OWASP Dependency Check:
   - Scan npm dependencies
   - HTML report generation

3. SonarQube integration:
   - Code quality gate
   - Coverage thresholds

4. Snyk scan (optional):
   - Dependency vulnerabilities
   - License compliance
```

---

### Prompt 6.5 - Jenkins Kubernetes Deployment
```
Jenkins Pipeline - K8s Deployment:

1. Push to ECR stage
2. Deploy to Staging:
   - kubectl apply -k overlays/staging
   - Wait for rollout
3. Integration tests
4. Manual approval gate
5. Deploy to Production:
   - Blue/Green hoặc Canary
6. Rollback on failure:
   - post { failure { kubectl rollback } }
```

---

### Prompt 6.6 - GitHub Actions Frontend CI
```
Tạo GitHub Actions cho Frontend CI:

1. .github/workflows/ci-frontend.yml

2. Matrix: Node 18.x, 20.x

3. Steps:
   - Checkout
   - Setup Node
   - Install dependencies (npm ci)
   - Lint (eslint)
   - Type check (tsc --noEmit)
   - Unit tests (vitest)
   - Build production
   - Upload artifacts

4. Lighthouse CI:
   - Performance score > 80
   - Accessibility > 90
```

---

### Prompt 6.7 - GitHub Actions Backend CI
```
Tạo GitHub Actions cho Backend CI:

1. .github/workflows/ci-backend.yml

2. Matrix: services [api-gateway, auth, user, book]

3. Steps per service:
   - Install dependencies
   - Lint
   - Unit tests với coverage
   - Docker build
   - Push to ECR (on main)

4. Integration tests với testcontainers
5. Codecov coverage upload
```

---

### Prompt 6.8 - E2E Testing Pipeline
```
Tạo E2E Testing với Playwright:

1. tests/e2e/
   ├── playwright.config.ts
   ├── auth.spec.ts
   ├── books.spec.ts
   ├── collections.spec.ts
   └── reading.spec.ts

2. Test scenarios:
   - User registration flow
   - Login/logout
   - Book search and detail
   - Add to collection
   - Reading progress

3. GitHub Actions integration
4. Screenshots on failure
5. Video recording (optional)
6. Parallel execution
```

---

### Prompt 6.9 - OWASP Security Testing
```
Tạo Security Testing Pipeline:

1. OWASP ZAP configuration:
   - Baseline scan (quick, 5 min)
   - Full scan (nightly, 30 min)

2. API security scan:
   - OpenAPI spec import
   - Authentication testing

3. Report generation:
   - HTML report
   - JSON for CI parsing

4. Fail thresholds:
   - CRITICAL: 0
   - HIGH: < 3

5. Slack alerts on findings
```

---

## 🎯 PHASE 7: KUBERNETES & GITOPS

### Prompt 7.1 - Kubernetes Base Manifests
```
Tạo Kubernetes Base Manifests:

1. infrastructure/kubernetes/base/
   ├── namespace.yaml
   ├── configmaps/
   ├── secrets/ (SealedSecrets)
   ├── network-policies/
   └── resource-quotas/

2. Namespace với labels
3. ConfigMaps: app-config, feature-flags
4. NetworkPolicy: deny-all default
5. ResourceQuota: limit pods, CPU, memory
6. LimitRange: default container limits
```

---

### Prompt 7.2 - Kubernetes Deployments
```
Tạo Kubernetes Deployments:

1. infrastructure/kubernetes/deployments/
   ├── frontend.yaml
   ├── api-gateway.yaml
   ├── auth-service.yaml
   ├── user-service.yaml
   ├── book-service.yaml
   └── ml-service.yaml

2. Per deployment:
   - Replicas: 2-3
   - Liveness probe: /health
   - Readiness probe: /ready
   - Resources: requests/limits
   - Env from ConfigMap/Secret
   - Pod anti-affinity

3. Deployment strategy:
   - RollingUpdate
   - maxSurge: 1
   - maxUnavailable: 0
```

---

### Prompt 7.3 - Kubernetes Services & Ingress
```
Tạo Services và Ingress:

1. Services:
   - ClusterIP cho internal
   - LoadBalancer cho external (optional)

2. Ingress:
   - Host: eshelf.com, api.eshelf.com
   - TLS với cert-manager
   - Path routing

3. Ingress annotations:
   - ALB/Nginx specific
   - SSL redirect
   - Rate limiting
```

---

### Prompt 7.4 - Kubernetes HPA & Kustomize
```
Tạo HPA và Kustomize Overlays:

1. HPA per deployment:
   - Min: 2, Max: 10
   - Target CPU: 70%
   - Target Memory: 80%

2. Kustomize structure:
   infrastructure/kubernetes/kustomize/
   ├── base/
   └── overlays/
       ├── dev/
       ├── staging/
       └── production/

3. Overlay patches:
   - Replicas
   - Resources
   - Environment variables
   - Image tags
```

---

### Prompt 7.5 - Helm Chart
```
Tạo Helm Chart cho eShelf:

1. infrastructure/helm/eshelf/
   ├── Chart.yaml
   ├── values.yaml
   ├── values-staging.yaml
   ├── values-production.yaml
   └── templates/
       ├── _helpers.tpl
       ├── deployment.yaml
       ├── service.yaml
       ├── ingress.yaml
       ├── hpa.yaml
       ├── configmap.yaml
       └── secret.yaml

2. Parameterized:
   - image.repository, image.tag
   - replicaCount
   - resources
   - ingress configuration
   - environment variables
```

---

### Prompt 7.6 - ArgoCD GitOps Setup
```
Cấu hình ArgoCD cho eShelf:

1. ArgoCD Applications:
   - eshelf-staging
   - eshelf-production

2. ApplicationSet cho multi-env:
   - Generator: list
   - Template: per environment

3. Sync policies:
   - Auto-sync for staging
   - Manual sync for production

4. Notifications:
   - Slack integration
   - Sync status updates

5. RBAC:
   - Admin: full access
   - Developer: read, sync staging
```

---

### Prompt 7.7 - Blue/Green Deployment
```
Implement Blue/Green Deployment:

1. infrastructure/kubernetes/blue-green/
   ├── blue-deployment.yaml
   ├── green-deployment.yaml
   └── service.yaml

2. Strategy:
   - Blue: current version
   - Green: new version
   - Service selector switch

3. Health check validation
4. Automated rollback script
5. Runbook documentation
```

---

### Prompt 7.8 - Canary Deployment (Flagger)
```
Implement Canary với Flagger:

1. Flagger installation (Helm)

2. Canary resource:
   - Target deployment
   - Metrics: success-rate, latency
   - Thresholds: 99%, P99 < 500ms

3. Traffic shifting:
   - 10% → 30% → 50% → 100%
   - Interval: 1m

4. Rollback on failure
5. Slack notifications
```

---

## 🎯 PHASE 8: MONITORING & OBSERVABILITY

### Prompt 8.1 - Prometheus Setup
```
Cấu hình Prometheus:

1. monitoring/prometheus/
   ├── prometheus.yml
   ├── alert-rules.yml
   └── docker-compose.yml

2. Scrape configs:
   - Kubernetes service discovery
   - Node exporter
   - Application metrics

3. Alert rules:
   - High error rate
   - High latency
   - Pod crashes
   - Disk usage
```

---

### Prompt 8.2 - Grafana Dashboards
```
Tạo Grafana Dashboards:

1. monitoring/grafana/dashboards/
   ├── application.json
   ├── infrastructure.json
   ├── kubernetes.json
   └── ml-service.json

2. Dashboard panels:
   - Request rate, latency, errors
   - CPU, memory, disk
   - Pod status, HPA metrics
   - ML model performance
```

---

### Prompt 8.3 - Alertmanager Configuration
```
Cấu hình Alertmanager:

1. Alert routing:
   - Critical → PagerDuty
   - Warning → Slack
   - Info → Email

2. Inhibit rules
3. Notification templates
4. Silencing configuration
```

---

### Prompt 8.4 - Loki Logging Stack
```
Cấu hình Loki:

1. Loki server configuration
2. Promtail agents (DaemonSet)
3. Grafana Loki data source
4. Log queries và dashboards
5. Retention policies (30 days)
```

---

### Prompt 8.5 - Audit Logging System
```
Tạo Audit Logging:

1. Audit log middleware:
   - who, what, when, where, result

2. Store trong Elasticsearch

3. Retention:
   - 90 days hot
   - 1 year cold storage

4. Grafana dashboard cho queries
5. Compliance reports (weekly)
```

---

### Prompt 8.6 - Backup & Disaster Recovery
```
Tạo Backup Strategy:

1. Database backup:
   - pg_dump daily
   - S3 cross-region replication

2. Elasticsearch snapshots

3. Restore procedures:
   - Step-by-step runbook
   - Tested quarterly

4. RTO/RPO:
   - RTO: 4 hours
   - RPO: 1 hour
```

---

## 🎯 PHASE 9: MLOPS PIPELINE

### Prompt 9.1 - MLflow Setup
```
Cấu hình MLflow:

1. mlops/mlflow/
   ├── docker-compose.yml
   ├── Dockerfile
   └── nginx.conf

2. Components:
   - Tracking server
   - S3 artifact storage
   - PostgreSQL backend

3. UI với authentication
4. Model registry
```

---

### Prompt 9.2 - ML Training Pipeline
```
Tạo Training Pipeline:

1. .github/workflows/ml-training.yml

2. Steps:
   - Data preprocessing
   - Feature engineering
   - Model training
   - Evaluation
   - MLflow logging
   - Model registration (if improved)

3. Scheduled: weekly
4. Trigger: on data change
```

---

### Prompt 9.3 - Model Serving
```
Cấu hình Model Serving:

1. ML service loads from MLflow registry
2. Model versioning
3. Canary deployment cho models
4. A/B testing setup
5. Rollback strategy
```

---

### Prompt 9.4 - ML Monitoring
```
Cấu hình ML Monitoring:

1. Data drift detection (Evidently)
2. Model performance metrics
3. Prometheus metrics for ML
4. Grafana ML dashboard
5. Auto-retrain triggers
```

---

### Prompt 9.5 - DVC Data Pipeline
```
Tạo DVC Pipeline:

1. DVC initialization
2. Remote storage (S3)
3. Data versioning
4. dvc.yaml pipeline
5. CI/CD integration
```

---

### Prompt 9.6 - Model A/B Testing
```
Implement Model A/B Testing:

1. Feature flags cho model selection
2. Traffic splitting (50/50)
3. Metrics per model version
4. Statistical significance testing
5. Auto winner selection
```

---

## 📅 Thứ Tự Thực Hiện Đề Xuất

### Tuần 1-2: Backend Foundation
```
Prompt 2.1 → 2.2 → 2.3 → 2.4
```

### Tuần 3-4: Database & Lab 1
```
Prompt 3.1 → 3.2 → 5.1 → 5.2 → 5.3 → 5.4 → 5.5 → 5.8
```

### Tuần 5-6: Lab 2 CI/CD
```
Prompt 6.1 → 6.3 → 6.4 → 6.5 → 6.6 → 6.7
```

### Tuần 7-8: Kubernetes
```
Prompt 7.1 → 7.2 → 7.3 → 7.4 → 7.5 → 7.6
```

### Tuần 9-10: AI/ML Features
```
Prompt 4.1 → 4.2 → 4.3 → 4.4
```

### Tuần 11-12: MLOps
```
Prompt 9.1 → 9.2 → 9.3 → 9.4
```

### Tuần 13-14: Monitoring & Polish
```
Prompt 8.1 → 8.2 → 8.3 → 8.4 → 8.5 → 8.6
```

### Tuần 15: Demo & Documentation
```
- Update README
- Prepare demo script
- Record backup video
- Final testing
```

---

## 🧪 Kế Hoạch Testing

### Unit Tests (70%)
- Frontend: Vitest
- Backend: Jest
- ML: pytest
- Coverage target: 80%

### Integration Tests (20%)
- API tests: Supertest
- Database tests: Testcontainers

### E2E Tests (10%)
- Playwright
- Critical user flows only

---

## 🎬 Kế Hoạch Demo (15-20 phút)

### Part 1: Introduction (2 phút)
- Giới thiệu dự án
- Problem statement

### Part 2: Application Demo (5 phút)
- User flow: Browse → Read → Save
- Admin Panel
- AI Chat feature

### Part 3: DevOps Demo (5 phút)
- GitHub repo structure
- Terraform plan/apply
- CI/CD pipeline run
- Kubernetes dashboard

### Part 4: MLOps Demo (3 phút)
- MLflow UI
- Model metrics
- Recommendation API

### Part 5: Monitoring (3 phút)
- Grafana dashboards
- Alerting setup

### Part 6: Q&A (2 phút)

---

## ✅ Checklist Trước Nộp Bài

### Lab 1
- [ ] Terraform modules working
- [ ] CloudFormation templates pass cfn-lint
- [ ] Infrastructure tests pass
- [ ] SSH to Bastion OK
- [ ] Private EC2 via Bastion OK

### Lab 2
- [ ] GitHub Actions + Checkov
- [ ] Jenkins pipeline complete
- [ ] Trivy scan integrated
- [ ] SonarQube quality gate

### Final Project
- [ ] All features working
- [ ] Documentation complete
- [ ] Demo script prepared
- [ ] Backup recording made

---

*Cập nhật lần cuối: Tháng 1/2025*
