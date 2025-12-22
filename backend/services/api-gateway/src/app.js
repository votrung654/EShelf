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

// Rate limiting
app.use(rateLimiter);

// ==========================================
// 👇 CẤU HÌNH PROXY (ĐÃ BỔ SUNG ĐẦY ĐỦ)
// ==========================================

// 1. Auth Service
app.use('/api/auth', createProxyMiddleware({
  target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001',
  changeOrigin: true,
  onProxyReq: (proxyReq, req, res) => {
    if (req.body && !req.headers['content-type']?.includes('multipart/form-data')) {
      const bodyData = JSON.stringify(req.body);
      proxyReq.setHeader('Content-Type', 'application/json');
      proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
      proxyReq.write(bodyData);
    }
  }
}));

// 2. Book Service (Xử lý cả Books và Genres)
// 👉 BỔ SUNG ROUTE GENRES VÀO ĐÂY
app.use(['/api/books', '/api/genres'], createProxyMiddleware({
  target: process.env.BOOK_SERVICE_URL || 'http://book-service:3002',
  changeOrigin: true,
  // Không cần pathRewrite vì Book Service thường được thiết kế để nhận /api/books
}));

// 3. User Service (Users, Favorites, History)
app.use(['/api/users', '/api/favorites', '/api/reading-history'], createProxyMiddleware({
  target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
  changeOrigin: true,
}));

// 4. ML Service (Gợi ý sách)
// 👉 QUAN TRỌNG: ML Service Python thường dùng đường dẫn gốc (/recommendations)
// Nên ta cần pathRewrite để cắt bỏ chữ /api/ml đi
app.use('/api/ml', createProxyMiddleware({
  target: process.env.ML_SERVICE_URL || 'http://ml-service:8000',
  changeOrigin: true,
  pathRewrite: {
    '^/api/ml': '', // Biến /api/ml/recommendations thành /recommendations
  },
}));

// ==========================================

// Body parsing (Đặt sau Proxy)
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

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
    console.log(`Routes configured: /api/auth, /api/books, /api/genres, /api/users, /api/favorites, /api/ml`);
  });
}

module.exports = app;