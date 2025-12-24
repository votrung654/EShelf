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
// Proxy Configuration
// ==========================================

// Auth Service
// Note: http-proxy-middleware automatically forwards the raw request body
// We don't need to parse it here, let the proxy forward the stream
app.use('/api/auth', createProxyMiddleware({
  target: process.env.AUTH_SERVICE_URL || 'http://auth-service:3001',
  changeOrigin: true,
  timeout: 30000,
  proxyTimeout: 30000,
  onProxyReq: (proxyReq, req, res) => {
    console.log(`[Auth Proxy] ${req.method} ${req.url} -> auth-service:3001${req.url}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`[Auth Proxy] Response: ${proxyRes.statusCode} for ${req.url}`);
  },
  onError: (err, req, res) => {
    console.error('[Auth Proxy Error]', err.message);
    console.error('[Target URL]', process.env.AUTH_SERVICE_URL || 'http://auth-service:3001');
    console.error('[Request URL]', req.url);
    if (!res.headersSent) {
      res.status(503).json({
        success: false,
        message: 'Auth service temporarily unavailable',
        error: err.message
      });
    }
  }
}));

// Book Service (handles both Books and Genres)
app.use(['/api/books', '/api/genres'], createProxyMiddleware({
  target: process.env.BOOK_SERVICE_URL || 'http://book-service:3002',
  changeOrigin: true,
}));

// User Service - separate routes for reliability
// Default to localhost for local development, can be overridden via env var
const userServiceUrl = process.env.USER_SERVICE_URL || 'http://localhost:3003';

const userServiceProxyOptions = {
  target: userServiceUrl,
  changeOrigin: true,
  timeout: 30000,
  proxyTimeout: 30000,
  onError: (err, req, res) => {
    console.error('Proxy error to user-service:', err.message);
    console.error('Target URL:', userServiceUrl);
    console.error('Request URL:', req.url);
    if (!res.headersSent) {
      res.status(503).json({
        success: false,
        message: 'User service temporarily unavailable',
        error: err.message
      });
    }
  },
  onProxyReq: (proxyReq, req, res) => {
    console.log(`[Proxy] ${req.method} ${req.url} -> ${userServiceUrl}${req.url}`);
  },
  onProxyRes: (proxyRes, req, res) => {
    console.log(`[Proxy] Response: ${proxyRes.statusCode} for ${req.url}`);
  }
};

app.use('/api/users', createProxyMiddleware(userServiceProxyOptions));
app.use('/api/favorites', createProxyMiddleware(userServiceProxyOptions));
app.use('/api/reading-history', createProxyMiddleware(userServiceProxyOptions));
app.use('/api/collections', createProxyMiddleware(userServiceProxyOptions));

// ML Service
// Note: ML Service uses root paths, so pathRewrite removes /api/ml prefix
app.use('/api/ml', createProxyMiddleware({
  target: process.env.ML_SERVICE_URL || 'http://ml-service:8000',
  changeOrigin: true,
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
    console.log(`API Gateway running on port ${PORT}`);
    console.log(`Routes configured: /api/auth, /api/books, /api/genres, /api/users, /api/favorites, /api/collections, /api/reading-history, /api/ml`);
  });
}

module.exports = app;