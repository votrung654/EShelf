const { UnauthorizedError } = require('./errorHandler');

// Placeholder for JWT verification
// Will be implemented when Auth Service is ready
const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      throw new UnauthorizedError('No token provided');
    }

    // TODO: Verify JWT token with Auth Service
    // For now, just pass through
    req.user = { id: 'temp-user-id' };
    
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
  requireAdmin
};
