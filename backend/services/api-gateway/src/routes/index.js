const express = require('express');
const { notFoundHandler } = require('../middleware/errorHandler');

const router = express.Router();

// Import route modules
const authRoutes = require('./auth');
const userRoutes = require('./users');
const bookRoutes = require('./books');
const collectionRoutes = require('./collections');
const readingProgressRoutes = require('./readingProgress');
const adminRoutes = require('./admin');

// Health check endpoints
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

router.get('/ready', async (req, res) => {
  // TODO: Check dependencies (database, other services)
  const checks = {
    server: 'ok',
    // database: await checkDatabase(),
    // authService: await checkService(process.env.AUTH_SERVICE_URL)
  };

  const isReady = Object.values(checks).every(status => status === 'ok');
  
  res.status(isReady ? 200 : 503).json({
    status: isReady ? 'ready' : 'not ready',
    checks,
    timestamp: new Date().toISOString()
  });
});

// API version info
router.get('/', (req, res) => {
  res.json({
    service: 'eShelf API Gateway',
    version: '1.0.0',
    environment: process.env.NODE_ENV,
    endpoints: {
      health: '/health',
      ready: '/ready',
      auth: '/api/auth',
      users: '/api/users',
      books: '/api/books',
      collections: '/api/collections',
      readingProgress: '/api/reading-progress',
      admin: '/api/admin'
    }
  });
});

// Service routes
router.use('/api/auth', authRoutes);
router.use('/api/users', userRoutes);
router.use('/api/books', bookRoutes);
router.use('/api/collections', collectionRoutes);
router.use('/api/reading-progress', readingProgressRoutes);
router.use('/api/admin', adminRoutes);

// 404 handler (must be last)
router.use(notFoundHandler);

module.exports = router;
