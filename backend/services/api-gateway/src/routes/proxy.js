// Proxy routes for API Gateway
// This file will be used when http-proxy-middleware is installed

const { createProxyMiddleware } = require('http-proxy-middleware');

// Service URLs
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://localhost:3001';
const BOOK_SERVICE_URL = process.env.BOOK_SERVICE_URL || 'http://localhost:3002';
const USER_SERVICE_URL = process.env.USER_SERVICE_URL || 'http://localhost:3003';
const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:8000';

// Proxy options
const createProxy = (target, pathRewrite = {}) => createProxyMiddleware({
  target,
  changeOrigin: true,
  pathRewrite,
  onError: (err, req, res) => {
    console.error(`Proxy error to ${target}:`, err.message);
    res.status(503).json({
      success: false,
      message: 'Service temporarily unavailable',
      service: target
    });
  },
  onProxyReq: (proxyReq, req, res) => {
    // Forward original IP
    proxyReq.setHeader('X-Forwarded-For', req.ip);
  }
});

module.exports = {
  authProxy: createProxy(AUTH_SERVICE_URL, { '^/api/auth': '/api/auth' }),
  bookProxy: createProxy(BOOK_SERVICE_URL, { '^/api/books': '/api/books' }),
  genreProxy: createProxy(BOOK_SERVICE_URL, { '^/api/genres': '/api/genres' }),
  profileProxy: createProxy(USER_SERVICE_URL, { '^/api/profile': '/api/profile' }),
  favoritesProxy: createProxy(USER_SERVICE_URL, { '^/api/favorites': '/api/favorites' }),
  collectionsProxy: createProxy(USER_SERVICE_URL, { '^/api/collections': '/api/collections' }),
  historyProxy: createProxy(USER_SERVICE_URL, { '^/api/reading-history': '/api/reading-history' }),
  mlProxy: createProxy(ML_SERVICE_URL, { '^/api/ml': '' }),
};

// To use in routes/index.js:
// const proxies = require('./proxy');
// router.use('/api/auth', proxies.authProxy);
// router.use('/api/books', proxies.bookProxy);
// etc.

