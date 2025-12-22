# eShelf Architecture

Tài liệu kiến trúc hệ thống eShelf.

## Tổng quan

eShelf được xây dựng theo kiến trúc microservices với các nguyên tắc:
- **Separation of Concerns:** Mỗi service có trách nhiệm riêng
- **Loose Coupling:** Services giao tiếp qua API
- **High Cohesion:** Logic liên quan được nhóm lại
- **Scalability:** Có thể scale từng service độc lập
- **Resilience:** Lỗi ở 1 service không ảnh hưởng toàn hệ thống

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet / Users                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Route 53 (DNS)                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                     │
│                    SSL/TLS Termination                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
   ┌─────────┐         ┌──────────┐         ┌─────────┐
   │Frontend │         │   API    │         │  Admin  │
   │ (React) │         │ Gateway  │         │  Panel  │
   │  :5173  │         │  :3000   │         │         │
   └────┬────┘         └────┬─────┘         └────┬────┘
        │                   │                    │
        └───────────────────┼────────────────────┘
                            │
       ┌────────────────────┼────────────────────┬──────────────┐
       ▼                    ▼                    ▼              ▼
  ┌─────────┐        ┌──────────┐        ┌──────────┐    ┌──────────┐
  │  Auth   │        │   Book   │        │   User   │    │    ML    │
  │ Service │        │ Service  │        │ Service  │    │ Service  │
  │  :3001  │        │  :3002   │        │  :3003   │    │  :8000   │
  └────┬────┘        └────┬─────┘        └────┬─────┘    └────┬─────┘
       │                  │                   │               │
       └──────────────────┼───────────────────┼───────────────┘
                          │                   │
                          ▼                   ▼
                   ┌────────────┐      ┌────────────┐
                   │ PostgreSQL │      │   Redis    │
                   │   (RDS)    │      │ (ElastiC.) │
                   └────────────┘      └────────────┘
```

## Services Detail

### Frontend (React + Vite)
**Port:** 5173  
**Technology:** React 18, TailwindCSS, React Router

**Responsibilities:**
- User interface
- Client-side routing
- State management (React Context)
- API calls to backend

**Key Features:**
- Responsive design
- Dark mode
- PWA support
- Offline caching

### API Gateway (Express.js)
**Port:** 3000  
**Technology:** Node.js, Express.js

**Responsibilities:**
- Request routing to services
- Rate limiting
- CORS handling
- Request/response logging
- Error handling

**Middleware:**
- Helmet (security headers)
- CORS
- Rate limiter (100 req/15min)
- Body parser
- Morgan (logging)

### Auth Service (Express.js)
**Port:** 3001  
**Technology:** Node.js, Express.js, JWT, bcrypt

**Responsibilities:**
- User registration
- User authentication
- JWT token generation
- Token refresh
- Password reset

**Endpoints:**
- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/auth/refresh`
- POST `/api/auth/logout`
- GET `/api/auth/me`

### Book Service (Express.js)
**Port:** 3002  
**Technology:** Node.js, Express.js

**Responsibilities:**
- Book CRUD operations
- Book search and filtering
- Genre management
- Book reviews
- View/download tracking

**Endpoints:**
- GET `/api/books` - List books
- GET `/api/books/search` - Search
- GET `/api/books/:id` - Get book
- POST `/api/books` - Create (Admin)
- PUT `/api/books/:id` - Update (Admin)
- DELETE `/api/books/:id` - Delete (Admin)

### User Service (Express.js)
**Port:** 3003  
**Technology:** Node.js, Express.js

**Responsibilities:**
- User profile management
- Favorites management
- Collections (custom lists)
- Reading history tracking
- Reading progress

**Endpoints:**
- GET `/api/profile` - Get profile
- PUT `/api/profile` - Update profile
- GET `/api/favorites` - Get favorites
- POST `/api/favorites/:bookId` - Add favorite
- GET `/api/collections` - Get collections
- POST `/api/collections` - Create collection

### ML Service (FastAPI)
**Port:** 8000  
**Technology:** Python, FastAPI, scikit-learn

**Responsibilities:**
- Book recommendations (Collaborative Filtering)
- Similar books (Content-based Filtering)
- Reading time estimation
- Featured books ranking

**Endpoints:**
- POST `/recommendations` - Get recommendations
- POST `/similar` - Get similar books
- POST `/estimate-time` - Estimate reading time
- GET `/featured` - Get featured books

**Algorithms:**
- Collaborative Filtering (user-based)
- Content-based Filtering (genre, author similarity)
- TF-IDF + Cosine Similarity

## Data Flow

### User Authentication Flow

```
User → Frontend → API Gateway → Auth Service
                                     ↓
                              Generate JWT
                                     ↓
                              Return tokens
                                     ↓
Frontend stores tokens → Subsequent requests include token
```

### Book Search Flow

```
User → Frontend → API Gateway → Book Service
                                     ↓
                              Query database
                                     ↓
                              Return results
                                     ↓
Frontend displays results
```

### ML Recommendation Flow

```
User → Frontend → API Gateway → ML Service
                                     ↓
                              Load user history
                                     ↓
                              Run ML model
                                     ↓
                              Return recommendations
                                     ↓
Frontend displays recommendations
```

## Database Schema

### Users
- id, email, username, password_hash
- name, avatar, bio, role
- created_at, updated_at

### Books
- id, isbn, title, description
- authors, translators, publisher
- cover_url, pdf_url, page_count
- language, published_year
- rating_avg, rating_count
- view_count, download_count

### Reviews
- id, user_id, book_id
- rating, content
- created_at, updated_at

### Favorites
- user_id, book_id
- created_at

### Collections
- id, user_id, name, description
- is_public, created_at

### Reading History
- id, user_id, book_id
- current_page, total_pages
- progress_percent
- last_read_at, started_at, finished_at

## Security

### Authentication
- JWT with RS256 algorithm
- Access token: 15 minutes expiry
- Refresh token: 7 days expiry
- Secure HTTP-only cookies (production)

### Authorization
- Role-based access control (RBAC)
- Roles: user, admin
- Protected routes require valid token
- Admin routes require admin role

### Data Protection
- Password hashing with bcrypt (12 rounds)
- SQL injection prevention (Prisma ORM)
- XSS prevention (input sanitization)
- CSRF protection (SameSite cookies)

## Scalability

### Horizontal Scaling
- Each service can scale independently
- Kubernetes HPA for auto-scaling
- Load balancing with ALB/Ingress

### Caching Strategy
- Redis for session storage
- Redis for API response caching
- Browser caching for static assets
- CDN for images and PDFs

### Database Optimization
- Indexes on frequently queried columns
- Connection pooling
- Read replicas for read-heavy operations
- Query optimization

## Resilience

### Error Handling
- Centralized error handling middleware
- Graceful degradation
- Circuit breaker pattern (future)
- Retry logic with exponential backoff

### Health Checks
- Liveness probes (service is alive)
- Readiness probes (service is ready)
- Dependency checks (database, cache)

### Monitoring
- Prometheus metrics
- Grafana dashboards
- Loki centralized logging
- Alertmanager for alerts

## Deployment

### Development
- Docker Compose for local development
- Hot reload for fast iteration
- Mock data for testing

### Staging
- Kubernetes cluster
- Automated deployment via ArgoCD
- Integration tests after deployment

### Production
- Multi-AZ deployment
- Blue/Green deployment strategy
- Canary deployment for risky changes
- Automated rollback on failure

## Future Enhancements

### Phase 1 (Tuần 7-8)
- Kubernetes deployment
- ArgoCD GitOps
- Smart Build pipeline

### Phase 2 (Tuần 9-10)
- Monitoring stack
- MLOps pipeline
- Model versioning

### Phase 3 (Tuần 11-12)
- Blue/Green deployment
- Canary deployment
- Ansible configuration management

### Phase 4 (Tuần 13-14)
- Advanced ML features
- Performance optimization
- Security hardening

---

*Document version: 1.0*  
*Last updated: December 2024*

