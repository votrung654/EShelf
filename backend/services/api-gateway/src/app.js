require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { createProxyMiddleware } = require('http-proxy-middleware'); // 👇 Thêm cái này
const { errorHandler } = require('./middleware/errorHandler');
const { rateLimiter } = require('./middleware/rateLimit');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration (Mở rộng để dễ Dev)
app.use(cors({
  origin: true, // Cho phép tất cả origin (Frontend, Postman, Curl)
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

// Logging
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Rate limiting
app.use(rateLimiter);

// ==========================================
// 👇 CẤU HÌNH PROXY (DẪN ĐƯỜNG CHO CÁC SERVICE)
// ==========================================
// Lưu ý: Phải đặt Proxy TRƯỚC express.json() để tránh lỗi body parsing

// 1. Auth Service
app.use('/api/auth', createProxyMiddleware({
  target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001',
  changeOrigin: true,
  pathRewrite: {
    // Nếu Auth Service của bạn đã có sẵn prefix /api/auth thì không cần dòng này.
    // Nếu Auth Service chỉ nghe ở /login thì bỏ comment dòng dưới:
    // '^/api/auth': '/api/auth', 
  },
  onProxyReq: (proxyReq, req, res) => {
    // Fix lỗi body parser nếu có
    if (req.body && !req.headers['content-type']?.includes('multipart/form-data')) {
      const bodyData = JSON.stringify(req.body);
      proxyReq.setHeader('Content-Type', 'application/json');
      proxyReq.setHeader('Content-Length', Buffer.byteLength(bodyData));
      proxyReq.write(bodyData);
    }
  }
}));

// 2. Book Service
app.use('/api/books', createProxyMiddleware({
  target: process.env.BOOK_SERVICE_URL || 'http://book-service:3002',
  changeOrigin: true,
}));

// 3. User Service (Bao gồm cả Profile và Favorites)
// Vì User Service xử lý cả /api/users và /api/favorites
app.use(['/api/users', '/api/favorites'], createProxyMiddleware({
  target: process.env.USER_SERVICE_URL || 'http://user-service:3003',
  changeOrigin: true,
}));

// 4. ML Service (Gợi ý sách)
app.use('/api/ml', createProxyMiddleware({
  target: process.env.ML_SERVICE_URL || 'http://ml-service:8000',
  changeOrigin: true,
  // Nếu ML Service (Python) không có prefix /api/ml, bạn có thể cần rewrite:
  // pathRewrite: { '^/api/ml': '' }, 
}));

// ==========================================
// KẾT THÚC CẤU HÌNH PROXY
// ==========================================

// Body parsing (Chỉ dùng cho các route nội bộ của Gateway nếu có)
// Đặt SAU Proxy để tránh nuốt mất luồng dữ liệu của Proxy
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health Check cho Gateway
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'API Gateway' });
});

// Error handling (must be last)
app.use(errorHandler);

// Start server
if (require.main === module) {
  const server = app.listen(PORT, () => {
    console.log(`🚀 API Gateway running on port ${PORT}`);
    console.log(`📝 Environment: ${process.env.NODE_ENV}`);
    console.log(`👉 Auth Service Target: ${process.env.AUTH_SERVICE_URL || 'http://auth-service:3001'}`);
  });

  server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
      console.error(`❌ Port ${PORT} in use`);
      process.exit(1);
    } else {
      console.error('❌ Server error:', error);
      process.exit(1);
    }
  });

  process.on('SIGTERM', () => {
    server.close(() => process.exit(0));
  });
}

module.exports = app;