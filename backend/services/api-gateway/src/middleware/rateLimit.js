const rateLimit = require('express-rate-limit');

// Rate limiter for public endpoints
const rateLimiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests',
    message: 'Too many requests from this IP, please try again later.',
    retryAfter: 15
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health checks
    return req.path === '/health' || req.path === '/ready';
  }
});

// Rate limiter for authenticated users
const authenticatedRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: parseInt(process.env.RATE_LIMIT_AUTH_MAX_REQUESTS) || 1000,
  keyGenerator: (req) => {
    return req.user?.id || req.ip;
  },
  message: {
    error: 'Too many requests',
    message: 'Rate limit exceeded for this user.',
    retryAfter: 60
  }
});

module.exports = {
  rateLimiter,
  authenticatedRateLimiter
};
