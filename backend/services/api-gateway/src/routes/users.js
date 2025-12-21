const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

// Mock reading history storage
const readingHistory = {};

// Get user profile
router.get('/:userId', authenticate, async (req, res, next) => {
  try {
    const { userId } = req.params;
    
    // In production, fetch from User Service
    // For now, return mock data
    res.json({
      id: userId,
      username: 'User',
      email: 'user@example.com',
      avatar: null,
      createdAt: new Date().toISOString(),
    });
  } catch (error) {
    next(error);
  }
});

// Update user profile
router.put('/:userId', authenticate, async (req, res, next) => {
  try {
    const { userId } = req.params;
    
    // Check if user can update this profile
    if (req.user.id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    // In production, update in User Service
    res.json({
      id: userId,
      ...req.body,
      updatedAt: new Date().toISOString(),
    });
  } catch (error) {
    next(error);
  }
});

// Get reading history
router.get('/:userId/reading-history', authenticate, async (req, res, next) => {
  try {
    const { userId } = req.params;
    
    // Check if user can access this history
    if (req.user.id !== userId && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    // In production, fetch from database
    const history = readingHistory[userId] || [];
    res.json(history);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

