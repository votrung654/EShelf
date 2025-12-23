require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { createProxyMiddleware } = require('http-proxy-middleware');
const { errorHandler } = require('./middleware/errorHandler');
const { rateLimiter } = require('./middleware/rateLimit');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ⚠️ KHÔNG parse body ở đây - để proxy tự handle
// Rate limiting (chỉ cho GET requests)
app.use((req, res, next) => {
  if (req.method === 'GET') {
    return rateLimiter(req, res, next);
  }
  next();
});

// ==========================================
// 👇 CẤU HÌNH PROXY (ĐÃ SỬA)
// ==========================================

const commonProxyOptions = {
  changeOrigin: true,
  timeout: 30000,
  proxyTimeout: 30000,
  // Không parse body, để proxy forward trực tiếp
  parseReqBody: false,
  onError: (err, req, res) => {
    console.error(`[Proxy Error] ${req.path}:`, err.message);
    res.status(503).json({
      success: false,
      message: 'Service temporarily unavailable',
      error: err.message
    });
  }
};

// 1. Auth Service
app.use('/api/auth', createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001',
}));

// 2. Book Service (Xử lý cả Books và Genres)
app.use(['/api/books', '/api/genres'], createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.BOOK_SERVICE_URL || 'http://book-service:3002',
}));

// 3. User Service
app.use('/api/users', createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
}));

app.use('/api/favorites', createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
}));

app.use('/api/reading-history', createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
}));

app.use('/api/collections', createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
}));

// 4. ML Service
app.use('/api/ml', createProxyMiddleware({
  ...commonProxyOptions,
  target: process.env.ML_SERVICE_URL || 'http://ml-service:8000',
  pathRewrite: {
    '^/api/ml': '',
  },
}));

// ==========================================

// Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'API Gateway' });
});

// Error handling
app.use(errorHandler);

// Start server
if (require.main === module) {
  const server = app.listen(PORT, () => {
    console.log(`🚀 API Gateway running on port ${PORT}`);
    console.log(`✅ Proxy configured for: auth, books, genres, users, favorites, collections, history, ml`);
  });
}

module.exports = app;