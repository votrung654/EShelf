// const rateLimit = require('express-rate-limit');

// // Rate limiter for public endpoints
// const rateLimiter = rateLimit({
//   windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
//   max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
//   message: {
//     error: 'Too many requests',
//     message: 'Too many requests from this IP, please try again later.',
//     retryAfter: 15
//   },
//   standardHeaders: true,
//   legacyHeaders: false,
//   skip: (req) => {
//     // Skip rate limiting for health checks
//     return req.path === '/health' || req.path === '/ready';
//   }
// });

// // Rate limiter for authenticated users
// const authenticatedRateLimiter = rateLimit({
//   windowMs: 60 * 60 * 1000, // 1 hour
//   max: parseInt(process.env.RATE_LIMIT_AUTH_MAX_REQUESTS) || 1000,
//   keyGenerator: (req) => {
//     return req.user?.id || req.ip;
//   },
//   message: {
//     error: 'Too many requests',
//     message: 'Rate limit exceeded for this user.',
//     retryAfter: 60
//   }
// });

// module.exports = {
//   rateLimiter,
//   authenticatedRateLimiter
// };
const rateLimit = require('express-rate-limit');

const rateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 phút
  max: 10000, // Tăng lên 10,000 requests (Thoải mái test tẹt ga)
  message: {
    status: 429,
    message: "Too many requests from this IP, please try again later."
  },
  standardHeaders: true, // Trả về thông tin Rate Limit trong header
  legacyHeaders: false,
  
  // Thêm dòng này để nó bỏ qua chặn nếu đang chạy localhost/docker nội bộ
  skip: (req) => {
    // Nếu IP là localhost hoặc docker internal
    const ip = req.ip || req.connection.remoteAddress;
    return ip === '::1' || ip === '127.0.0.1' || (ip && ip.startsWith('::ffff:127.0.0.1')); 
  }
});

module.exports = { rateLimiter };