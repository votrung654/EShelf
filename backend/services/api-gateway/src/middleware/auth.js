const { UnauthorizedError } = require('./errorHandler');

// Mock user storage (in production, this would be in Auth Service)
// This is a temporary solution until Auth Service is implemented
const userTokens = {};

// Store user token mapping (in production, decode JWT)
function storeUserToken(token, user) {
  userTokens[token] = user;
}

// Get user from token (in production, verify JWT)
function getUserFromToken(token) {
  return userTokens[token] || null;
}

// Placeholder for JWT verification
// Will be implemented when Auth Service is ready
const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      throw new UnauthorizedError('No token provided');
    }

    // For mock tokens, extract user info from token storage
    // In production, verify JWT token with Auth Service
    const user = getUserFromToken(token);
    
    if (!user) {
      // Try to parse mock token format: mock_token_userId_timestamp
      const tokenParts = token.split('_');
      if (tokenParts.length >= 3 && tokenParts[0] === 'mock' && tokenParts[1] === 'token') {
        // Extract user ID from token
        const userId = tokenParts[2];
        req.user = { id: userId, role: 'user' };
      } else {
        throw new UnauthorizedError('Invalid token');
      }
    } else {
      req.user = user;
    }
    
    next();
  } catch (error) {
    next(error);
  }
};

// Check if user is admin
const requireAdmin = (req, res, next) => {
  if (req.user?.role !== 'admin') {
    return next(new UnauthorizedError('Admin access required'));
  }
  next();
};

module.exports = {
  authenticate,
  requireAdmin,
  storeUserToken,
  getUserFromToken
};
