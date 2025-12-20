# 🚀 Kế Hoạch Tính Năng Nâng Cao & AI cho eShelf

> **Mục đích:** Bổ sung các tính năng AI, kế hoạch test, phân công việc, và demo  
> **Cập nhật:** Tháng 1/2025  
> **Tham khảo:** Các dự án của Google, Netflix, Spotify, Amazon, OpenAI

---

## 📋 Mục lục

1. [AI Features - Tính năng AI](#1-ai-features---tính-năng-ai)
2. [Advanced Frontend Features](#2-advanced-frontend-features)
3. [Kế hoạch Testing chi tiết](#3-kế-hoạch-testing-chi-tiết)
4. [Phân công công việc](#4-phân-công-công-việc)
5. [Kế hoạch Demo](#5-kế-hoạch-demo)
6. [Checklist trước nộp bài](#6-checklist-trước-nộp-bài)

---

## 1. AI Features - Tính năng AI

### 🤖 1.1 AI Book Chat Assistant (Khuyến nghị MẠNH)

**Mô tả:** Chatbot AI giúp người dùng tương tác với sách - hỏi đáp nội dung, tóm tắt, giải thích.

**Tham khảo:**
- ChatPDF (chatpdf.com)
- Claude for Docs
- Notion AI

**Prompt đề xuất:**
```
Tạo AI Chat Assistant cho eShelf:
1. Component AIChatPanel.jsx - floating chat widget
2. Tích hợp OpenAI API hoặc Claude API
3. Các chức năng:
   - "Tóm tắt chương này cho tôi"
   - "Giải thích đoạn văn được highlight"
   - "Đặt câu hỏi về nội dung sách"
   - "Gợi ý sách tương tự"
4. Context-aware: biết user đang đọc sách nào, trang nào
5. Chat history lưu theo user + book
6. Rate limiting để tiết kiệm API cost
```

**✅ Kết quả:**
- Chat widget góc phải màn hình đọc sách
- Có thể highlight text → "Ask AI about this"
- Trả lời dựa trên context của sách
- Lưu lịch sử chat

**🧪 Test:**
```bash
# 1. Mở Reading page → thấy chat icon
# 2. Click → chat panel mở
# 3. Gõ "Tóm tắt chương 1" → AI trả lời
# 4. Highlight text → "Explain this" button xuất hiện
```

**💡 Tại sao nên làm:**
- Phù hợp với MLOps (model serving, A/B testing)
- Ấn tượng với giám khảo
- Xu hướng 2024-2025

---

### 📖 1.2 AI Book Summarization

**Mô tả:** Tự động tóm tắt sách theo các cấp độ (1 câu, 1 đoạn, 1 trang).

**Prompt đề xuất:**
```
Tạo AI Summarization cho eShelf:
1. backend/services/ml-service/summarization/
2. Endpoints:
   - POST /summarize/chapter - tóm tắt 1 chương
   - POST /summarize/book - tóm tắt toàn bộ sách
   - POST /summarize/selection - tóm tắt đoạn được chọn
3. Sử dụng BART/T5 hoặc GPT API
4. Caching kết quả trong Redis
5. Frontend: nút "Tóm tắt" trong BookDetail và Reading
6. Hiển thị summary với expandable sections
```

**✅ Kết quả:**
- Nút "AI Summary" trong BookDetail
- Modal hiển thị tóm tắt 3 cấp độ: Quick/Medium/Detailed
- Cached summaries cho sách phổ biến

---

### 🔊 1.3 Text-to-Speech (Audiobook Mode)

**Mô tả:** Chuyển sách thành audio để nghe.

**Tham khảo:**
- Speechify
- Natural Reader
- Amazon Polly

**Prompt đề xuất:**
```
Tạo Text-to-Speech cho eShelf:
1. Tích hợp AWS Polly hoặc Google TTS API
2. Component AudioPlayer.jsx trong Reading page
3. Chức năng:
   - Play/Pause/Skip
   - Speed control (0.5x - 2x)
   - Voice selection (male/female)
   - Auto-scroll text khi đọc
4. Highlight từ đang đọc (karaoke style)
5. Lưu position để continue listening
6. Offline mode: cache audio chunks
```

**✅ Kết quả:**
- Nút headphone icon trong Reading page
- Audio player với controls
- Text highlight sync với audio

---

### 🔍 1.4 Semantic Search (Vector Search)

**Mô tả:** Tìm kiếm theo nghĩa, không chỉ keyword.

**Tham khảo:**
- Pinecone
- Weaviate
- Qdrant

**Prompt đề xuất:**
```
Tạo Semantic Search cho eShelf:
1. Vector database: Pinecone hoặc Qdrant
2. Embedding model: sentence-transformers
3. Index toàn bộ book descriptions + content
4. Search endpoint: GET /search/semantic?q=...
5. Kết quả: "Sách về tình yêu tuổi trẻ" → tìm đúng dù không có keyword
6. Hybrid search: kết hợp keyword + semantic
```

**✅ Kết quả:**
- Search box hiểu ngữ nghĩa
- "Sách dạy làm giàu" → tìm được sách kinh tế

---

### 🎯 1.5 Personalized Reading Goals & Insights

**Mô tả:** AI phân tích thói quen đọc và đề xuất goals.

**Prompt đề xuất:**
```
Tạo Reading Insights cho eShelf:
1. Dashboard ReadingInsights.jsx
2. Metrics:
   - Thời gian đọc trung bình/ngày
   - Tốc độ đọc (pages/hour)
   - Thể loại yêu thích (pie chart)
   - Streak đọc liên tục
3. AI suggestions:
   - "Bạn đọc chậm hơn tuần trước 20%"
   - "Thử đọc thể loại mới: Khoa học viễn tưởng"
4. Goals: "Đọc 20 sách trong năm"
5. Badges/Achievements
```

---

### 📊 1.6 Smart Content Recommendations (Netflix-style)

**Mô tả:** Gợi ý sách theo nhiều chiều (không chỉ collaborative filtering).

**Tham khảo:**
- Netflix recommendation system
- Spotify Discover Weekly

**Prompt đề xuất:**
```
Tạo Smart Recommendations cho eShelf:
1. Nhiều loại recommendations:
   - "Vì bạn đã đọc [Sách A]" (item-based)
   - "Người đọc giống bạn cũng thích" (user-based)
   - "Trending tuần này"
   - "Hidden gems" (sách ít người biết nhưng rating cao)
   - "Hoàn thành series" (nếu đang đọc series)
2. Carousel UI giống Netflix
3. A/B testing các thuật toán
4. Explainability: giải thích tại sao gợi ý
```

---

### 🧠 1.7 Reading Mood Detection

**Mô tả:** Hỏi user mood và gợi ý sách phù hợp.

**Prompt đề xuất:**
```
Tạo Mood-based Recommendations:
1. Component MoodSelector.jsx
2. UI: "Hôm nay bạn muốn đọc gì?"
   - 😊 Vui vẻ → Comedy, Feel-good
   - 😢 Buồn → Healing, Self-help
   - 🤔 Tò mò → Mystery, Sci-fi
   - 😴 Thư giãn → Light novels
3. ML model: mood → genre mapping
4. Lưu mood history để phân tích
```

---

## 2. Advanced Frontend Features

### 🎨 2.1 Immersive Reading Experience (Kindle-style)

**Tham khảo:**
- Kindle app
- Apple Books
- Google Play Books

**Prompt đề xuất:**
```
Tạo Immersive Reader cho eShelf:
1. Fullscreen reading mode (F11)
2. Customization panel:
   - Font: 10+ fonts (Serif, Sans, Dyslexia-friendly)
   - Size: 12px - 32px slider
   - Line height: 1.2 - 2.0
   - Margins: Narrow/Normal/Wide
   - Background: White/Sepia/Gray/Black
   - Column: Single/Two columns
3. Animation: page flip effect
4. Auto-brightness based on time of day
5. Blue light filter toggle
6. Save preferences per device
```

---

### 📱 2.2 Mobile-First Features

**Prompt đề xuất:**
```
Tạo Mobile Enhancements cho eShelf:
1. Swipe gestures:
   - Swipe left/right: next/prev page
   - Swipe up: show toolbar
   - Long press: highlight/annotate
2. Bottom navigation bar (mobile)
3. Pull-to-refresh
4. Floating action button (FAB)
5. Haptic feedback on interactions
6. Share to social media (Web Share API)
```

---

### 🔖 2.3 Advanced Annotations & Highlights

**Tham khảo:**
- Notion
- Hypothesis
- Kindle highlights

**Prompt đề xuất:**
```
Tạo Annotation System cho eShelf:
1. Highlight với nhiều màu (yellow, green, blue, pink)
2. Add notes cho highlights
3. Export highlights as:
   - Markdown
   - PDF
   - Notion integration
4. Share highlights publicly (optional)
5. "Popular highlights" từ cộng đồng
6. Flashcard mode từ highlights
```

---

### 🌐 2.4 Social Reading Features

**Tham khảo:**
- Goodreads
- Bookclubs
- Storygraph

**Prompt đề xuất:**
```
Tạo Social Features cho eShelf:
1. User profiles: /user/:username
2. Follow users
3. Activity feed: "User A đang đọc Book X"
4. Reading challenges: "Đọc 12 sách trong năm"
5. Book clubs:
   - Create club
   - Shared reading schedule
   - Discussion threads per chapter
6. Reviews & ratings
7. "Currently reading" badge
```

---

### 🎮 2.5 Gamification System

**Tham khảo:**
- Duolingo
- Habitica
- Forest app

**Prompt đề xuất:**
```
Tạo Gamification cho eShelf:
1. XP system: earn XP for reading
2. Levels: Beginner → Expert Reader
3. Badges:
   - "First Book" - đọc xong sách đầu tiên
   - "Night Owl" - đọc sau 11pm
   - "Speed Reader" - đọc 100 trang/ngày
   - "Genre Explorer" - đọc 5 thể loại khác nhau
4. Streaks: đọc X ngày liên tục
5. Leaderboards: tuần/tháng/all-time
6. Rewards: unlock themes, avatars
```

---

### 📊 2.6 Analytics Dashboard (User)

**Prompt đề xuất:**
```
Tạo User Analytics Dashboard:
1. Route /profile/analytics
2. Charts:
   - Reading time per day (bar chart)
   - Books by genre (donut chart)
   - Reading streak calendar (GitHub-style)
   - Pages read per month (line chart)
3. Stats:
   - Total books read
   - Total pages
   - Total hours
   - Average reading speed
4. Year in Review (Spotify Wrapped style)
5. Export data as CSV
```

---

## 3. Kế hoạch Testing chi tiết

### 3.1 Testing Pyramid

```
                    ┌──────────────┐
                    │   E2E Tests  │  10%
                    │ (Playwright) │
                    └──────────────┘
               ┌─────────────────────────┐
               │   Integration Tests     │  20%
               │   (Supertest, Jest)     │
               └─────────────────────────┘
          ┌───────────────────────────────────┐
          │         Unit Tests                │  70%
          │    (Jest, Vitest, pytest)         │
          └───────────────────────────────────┘
```

### 3.2 Test Cases Matrix

| Component | Unit Tests | Integration | E2E | Performance |
|-----------|------------|-------------|-----|-------------|
| Login/Register | ✅ | ✅ | ✅ | - |
| Book Search | ✅ | ✅ | ✅ | ✅ |
| PDF Reader | ✅ | - | ✅ | ✅ |
| Collections | ✅ | ✅ | ✅ | - |
| Admin CRUD | ✅ | ✅ | ✅ | - |
| Recommendations | ✅ | ✅ | - | ✅ |
| API Gateway | ✅ | ✅ | - | ✅ |

### 3.3 E2E Test Scenarios

```markdown
## Critical User Flows (phải pass 100%)

1. **User Registration Flow**
   - Vào trang chủ
   - Click "Đăng ký"
   - Điền form → Submit
   - Redirect về login
   - Đăng nhập thành công

2. **Book Discovery Flow**
   - Search "Harry Potter"
   - Click sách đầu tiên
   - Xem chi tiết
   - Click "Đọc sách"
   - PDF load thành công

3. **Collection Management Flow**
   - Đăng nhập
   - Vào book detail
   - Add to collection
   - Vào Collections page
   - Verify sách đã được thêm

4. **Admin Book Management Flow**
   - Đăng nhập admin
   - Vào Admin Panel
   - Add new book
   - Edit book
   - Delete book
   - Verify changes
```

### 3.4 Performance Testing

```markdown
## Load Testing với k6

**Scenarios:**
1. **Smoke Test:** 1 user, 1 minute
2. **Load Test:** 100 users, 10 minutes
3. **Stress Test:** 500 users, 5 minutes
4. **Spike Test:** 0 → 1000 users sudden

**Thresholds:**
- P95 response time < 500ms
- Error rate < 1%
- Throughput > 100 RPS

**Commands:**
```bash
k6 run tests/performance/smoke.js
k6 run tests/performance/load.js
k6 run tests/performance/stress.js
```
```

### 3.5 Security Testing Checklist

```markdown
## OWASP Top 10 Checklist

- [ ] SQL Injection: parameterized queries
- [ ] XSS: input sanitization, CSP headers
- [ ] CSRF: tokens implemented
- [ ] Broken Auth: JWT validation, password hashing
- [ ] Sensitive Data: HTTPS, encryption at rest
- [ ] XXE: disable external entities
- [ ] Access Control: role-based checks
- [ ] Security Misconfiguration: headers, defaults
- [ ] Using Known Vulnerabilities: dependency scan
- [ ] Insufficient Logging: audit logs

## Tools:
- OWASP ZAP: automated scan
- Snyk: dependency vulnerabilities
- Trivy: container scan
- SonarQube: code quality
```

---

## 4. Phân công công việc

### 4.1 Nếu làm 1 người (Solo Project)

```markdown
## Sprint 1-2: Foundation (2 tuần)
- [ ] Frontend cơ bản
- [ ] Dark mode
- [ ] Collections

## Sprint 3-4: Infrastructure (2 tuần)
- [ ] Terraform modules (Lab 1)
- [ ] CloudFormation templates
- [ ] Test cases

## Sprint 5-6: CI/CD (2 tuần)
- [ ] GitHub Actions (Lab 2)
- [ ] Jenkins pipeline
- [ ] Security scanning

## Sprint 7-8: Backend (2 tuần)
- [ ] API Gateway
- [ ] Auth Service
- [ ] Book Service

## Sprint 9-10: Kubernetes (2 tuần)
- [ ] K8s manifests
- [ ] Helm charts
- [ ] ArgoCD

## Sprint 11-12: MLOps (2 tuần)
- [ ] MLflow setup
- [ ] Recommendation model
- [ ] Model serving

## Sprint 13-14: Polish (2 tuần)
- [ ] Monitoring stack
- [ ] Documentation
- [ ] Demo preparation
```

### 4.2 Nếu làm nhóm 3-5 người

```markdown
## Role Distribution

### 👤 Member 1: Frontend Lead
**Tuần 1-4:**
- [ ] React app structure
- [ ] All pages implementation
- [ ] Dark mode, PWA
- [ ] Admin Panel UI

**Tuần 5-10:**
- [ ] Integration với Backend
- [ ] E2E tests
- [ ] Performance optimization

**Tuần 11-14:**
- [ ] AI features UI
- [ ] Final polish
- [ ] Demo UI

---

### 👤 Member 2: Backend Lead
**Tuần 1-4:**
- [ ] API Gateway
- [ ] Auth Service
- [ ] User Service

**Tuần 5-10:**
- [ ] Book Service
- [ ] Search Service (Elasticsearch)
- [ ] Database design

**Tuần 11-14:**
- [ ] API optimization
- [ ] Integration testing
- [ ] Documentation

---

### 👤 Member 3: DevOps Lead
**Tuần 1-4:**
- [ ] Terraform modules (Lab 1)
- [ ] CloudFormation templates
- [ ] Infrastructure tests

**Tuần 5-10:**
- [ ] CI/CD pipelines (Lab 2)
- [ ] Kubernetes setup
- [ ] ArgoCD GitOps

**Tuần 11-14:**
- [ ] Monitoring stack
- [ ] Security hardening
- [ ] DR testing

---

### 👤 Member 4: MLOps Lead
**Tuần 1-6:**
- [ ] ML research & design
- [ ] Data preparation
- [ ] Model training

**Tuần 7-10:**
- [ ] MLflow setup
- [ ] Model serving
- [ ] A/B testing

**Tuần 11-14:**
- [ ] Model monitoring
- [ ] Drift detection
- [ ] ML documentation

---

### 👤 Member 5: QA & Documentation
**Tuần 1-4:**
- [ ] Test strategy document
- [ ] Unit test templates
- [ ] README structure

**Tuần 5-10:**
- [ ] Integration tests
- [ ] E2E tests (Playwright)
- [ ] Performance tests

**Tuần 11-14:**
- [ ] Security testing
- [ ] Final documentation
- [ ] Demo script preparation
```

### 4.3 Communication Plan

```markdown
## Daily
- Standup 15 phút (Discord/Slack)
- Update Trello/Jira board

## Weekly
- Code review session (1h)
- Demo progress (30 phút)
- Planning next week (30 phút)

## Tools
- GitHub: code
- Discord/Slack: chat
- Trello/Notion: tasks
- Google Meet: meetings
- Loom: async demos
```

---

## 5. Kế hoạch Demo

### 5.1 Demo Structure (15-20 phút)

```markdown
## Part 1: Introduction (2 phút)
- Giới thiệu team
- Giới thiệu dự án eShelf
- Problem statement

## Part 2: Application Demo (5 phút)
- User flow: Register → Login → Browse → Read
- Collections & Favorites
- Dark mode
- Admin Panel
- Mobile responsive

## Part 3: DevOps Demo (5 phút)
- Show GitHub repo structure
- Terraform plan/apply
- GitHub Actions run
- Jenkins pipeline
- Kubernetes dashboard
- ArgoCD sync

## Part 4: MLOps Demo (3 phút)
- MLflow UI
- Model metrics
- Recommendation API call
- A/B testing dashboard

## Part 5: Monitoring Demo (3 phút)
- Grafana dashboards
- Prometheus metrics
- Alerting setup

## Part 6: Q&A (2 phút)
```

### 5.2 Demo Preparation Checklist

```markdown
## 1 tuần trước demo

### Infrastructure
- [ ] AWS resources stable
- [ ] Kubernetes cluster healthy
- [ ] All pods Running
- [ ] Domain/SSL working

### Application
- [ ] Seed data loaded (50+ books)
- [ ] Test accounts ready:
  - admin@eshelf.com / Admin123!
  - user@eshelf.com / User123!
- [ ] No console errors
- [ ] All features working

### Pipelines
- [ ] Recent successful pipeline run
- [ ] All tests passing
- [ ] SonarQube quality gate passed
- [ ] No critical vulnerabilities

### Monitoring
- [ ] Grafana dashboards populated
- [ ] Sample alerts configured
- [ ] Logs flowing to Loki

### Demo Environment
- [ ] Screen recording backup
- [ ] Slides ready
- [ ] Network tested
- [ ] Backup laptop ready
```

### 5.3 Demo Script

```markdown
## Demo Script - Chi tiết từng bước

### Scene 1: Application (Browser)
```
1. Mở https://eshelf.com
2. "Đây là trang chủ với sách nổi bật..."
3. Search "Python" → show results
4. Click book → show detail
5. Click "Đọc sách" → PDF viewer
6. Toggle dark mode
7. "Với tài khoản admin..." → /admin
8. Show dashboard charts
9. CRUD 1 book
```

### Scene 2: Code & Git (VSCode)
```
1. Show folder structure
2. "Frontend React, Backend Node.js..."
3. Show Terraform modules
4. Show Jenkinsfile
5. "Khi dev push code..."
```

### Scene 3: CI/CD (GitHub Actions)
```
1. Open GitHub Actions tab
2. Show recent workflow run
3. Expand steps: lint → test → build → scan
4. "Checkov đảm bảo security..."
5. Show Terraform plan output
```

### Scene 4: Kubernetes (kubectl/Lens)
```
1. kubectl get pods -n eshelf
2. Show deployments, services
3. Show HPA scaling
4. ArgoCD UI → show sync status
```

### Scene 5: Monitoring (Grafana)
```
1. Application dashboard
2. "Request rate hiện tại..."
3. Kubernetes dashboard
4. Show an alert rule
```

### Scene 6: MLOps (MLflow)
```
1. Open MLflow UI
2. Show experiments
3. "Model accuracy 0.87..."
4. curl recommendation API
5. Show A/B test metrics
```
```

### 5.4 Backup Plans

```markdown
## Nếu gặp sự cố

### Network issues
- Có sẵn video recording của toàn bộ demo
- Chạy local với Docker Compose

### AWS down
- Screenshots của tất cả dashboards
- Local Kubernetes với Minikube

### Nervous/Forget
- Printed script
- Slides với key points
- Team member backup
```

---

## 6. Checklist trước nộp bài

### 6.1 Lab 1 Checklist

```markdown
## Terraform
- [ ] modules/vpc/ ✓ validate ✓ plan ✓ apply
- [ ] modules/networking/ (NAT Gateway)
- [ ] modules/ec2/ (Bastion + App)
- [ ] modules/security-groups/
- [ ] environments/dev/ ✓ tfvars ✓ backend
- [ ] Checkov pass (no HIGH/CRITICAL)

## CloudFormation
- [ ] vpc-stack.yaml ✓ cfn-lint
- [ ] ec2-stack.yaml ✓ cfn-lint
- [ ] Cross-stack references work

## Tests
- [ ] test_infrastructure.sh pass
- [ ] SSH to Bastion OK
- [ ] Private EC2 via Bastion OK
- [ ] NAT Gateway working

## Documentation
- [ ] README with architecture diagram
- [ ] How to deploy guide
- [ ] Screenshots
```

### 6.2 Lab 2 Checklist

```markdown
## GitHub Actions
- [ ] terraform.yml ✓ Checkov ✓ Plan ✓ Apply
- [ ] ci-frontend.yml ✓ Lint ✓ Test ✓ Build
- [ ] ci-backend.yml ✓ Matrix ✓ Coverage

## CodePipeline
- [ ] pipeline-stack.yaml deployed
- [ ] cfn-lint stage pass
- [ ] taskcat tests pass
- [ ] CloudFormation deploy works

## Jenkins
- [ ] Jenkinsfile complete
- [ ] SonarQube integration
- [ ] Trivy scan stage
- [ ] K8s deploy stage
- [ ] Rollback tested

## Security
- [ ] No secrets in code
- [ ] All scans passing
- [ ] HTTPS only
```

### 6.3 Final Project Checklist

```markdown
## Code Quality
- [ ] No ESLint errors
- [ ] No TypeScript errors
- [ ] SonarQube quality gate passed
- [ ] Test coverage > 70%

## Functionality
- [ ] All CRUD operations work
- [ ] Authentication working
- [ ] Search working
- [ ] PDF reader working
- [ ] Admin panel working

## DevOps
- [ ] Infrastructure reproducible
- [ ] CI/CD automated
- [ ] Monitoring working
- [ ] Alerting configured

## MLOps
- [ ] Model trained and registered
- [ ] API serving predictions
- [ ] MLflow tracking

## Documentation
- [ ] README complete
- [ ] API documentation
- [ ] Architecture diagrams
- [ ] Runbooks

## Demo Ready
- [ ] Test accounts created
- [ ] Seed data loaded
- [ ] Demo script prepared
- [ ] Backup recording made
```

---

## 7. Prompts bổ sung cho AI Features

### Prompt AI.1 - AI Chat Assistant
```
Tạo AI Chat Assistant cho eShelf:
1. src/components/ai/AIChatPanel.jsx
2. Floating widget góc phải màn hình
3. OpenAI/Claude API integration
4. Context: current book, current page
5. Features:
   - Summarize chapter
   - Explain selected text
   - Answer questions about content
   - Suggest similar books
6. Chat history per user + book
7. Rate limiting: 10 requests/hour (free tier)
8. Fallback khi API down
```

**🧪 Test:**
```bash
npm run dev
# 1. Mở Reading page → thấy chat icon
# 2. Click → panel mở
# 3. Gõ "Tóm tắt" → AI response
# 4. F12 Network → verify API call
```

---

### Prompt AI.2 - Smart Search
```
Tạo Semantic Search cho eShelf:
1. Vector database setup (Pinecone/Qdrant)
2. Embedding endpoint: POST /embed
3. Search endpoint: GET /search/semantic?q=
4. Index all book descriptions
5. Hybrid search: keyword + semantic
6. UI: "AI-powered search" toggle
7. Show relevance scores
```

---

### Prompt AI.3 - Reading Insights
```
Tạo AI Reading Insights Dashboard:
1. src/pages/Insights.jsx
2. Collect reading data:
   - Time spent per book
   - Pages per session
   - Reading times (morning/night)
3. AI analysis:
   - "Bạn đọc hiệu quả nhất lúc 9pm"
   - "Thể loại yêu thích: Fantasy"
   - "Đề xuất: Thử đọc Non-fiction"
4. Visualizations:
   - Calendar heatmap (like GitHub)
   - Reading streak chart
   - Genre distribution
5. Weekly email summary (optional)
```

---

## 8. Tham khảo từ Industry Leaders

### 8.1 Netflix Recommendations
- Personalized rows ("Because you watched...")
- A/B testing mọi thứ
- Artwork personalization
- **Áp dụng:** Multiple recommendation types

### 8.2 Spotify Wrapped
- Year-in-review feature
- Shareable cards
- Gamification
- **Áp dụng:** "Your Reading Year" feature

### 8.3 Kindle X-Ray
- Character insights
- Key phrases
- Related Wikipedia
- **Áp dụng:** AI-powered book insights

### 8.4 Notion AI
- Inline AI commands
- Summarize, translate, explain
- Context-aware
- **Áp dụng:** AI commands trong reader

### 8.5 Duolingo Gamification
- XP system
- Streaks
- Leaderboards
- Hearts/Lives
- **Áp dụng:** Reading gamification

---

## 9. Priority Matrix - Tính năng AI

```
                        Impact cao
                            │
                  ┌─────────┼─────────┐
                  │ AI Chat │ Smart   │
     Effort thấp  │         │ Search  │  Effort cao
                  ├─────────┼─────────┤
                  │ TTS     │ Social  │
                  │ Insights│ Features│
                  └─────────┴─────────┘
                            │
                        Impact thấp

Thứ tự ưu tiên:
1. AI Chat Assistant (impact cao, effort TB)
2. Smart Search (impact cao, effort cao)
3. TTS (impact TB, effort thấp)
4. Reading Insights (impact TB, effort TB)
5. Social Features (impact thấp, effort cao)
```

---

## 10. Kết luận

### Nên làm ngay (Quick Wins):
1. ✅ AI Chat Assistant - ấn tượng giám khảo
2. ✅ Reading Insights Dashboard
3. ✅ Gamification cơ bản (XP, badges)

### Nên làm nếu có thời gian:
1. 🔶 Text-to-Speech
2. 🔶 Semantic Search
3. 🔶 Advanced Annotations

### Nice to have (Future):
1. ⬜ Social Features
2. ⬜ Book Clubs
3. ⬜ AI Summaries

### Prompts cần thêm vào prompt.md:
- Prompt AI.1: AI Chat Assistant
- Prompt AI.2: Smart Search
- Prompt AI.3: Reading Insights
- Prompt FE.4: Gamification
- Prompt FE.5: User Analytics

---

*Tài liệu được cập nhật thường xuyên theo tiến độ dự án.*
