const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

// Mock reading progress storage (in production, use database)
const readingProgress = {};

// Get reading progress for a book
router.get('/:bookId', authenticate, async (req, res, next) => {
  try {
    const { bookId } = req.params;
    const userId = req.query.userId || req.user.id;

    // Check if user can access this progress
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const key = `${userId}_${bookId}`;
    const progress = readingProgress[key] || null;

    res.json(progress);
  } catch (error) {
    next(error);
  }
});

// Update reading progress
router.put('/:bookId', authenticate, async (req, res, next) => {
  try {
    const { bookId } = req.params;
    const { page, percentage, lastReadAt } = req.body;
    const userId = req.user.id;

    if (page === undefined && percentage === undefined) {
      return res.status(400).json({ message: 'Page or percentage is required' });
    }

    const key = `${userId}_${bookId}`;
    const existingProgress = readingProgress[key];

    const updatedProgress = {
      userId,
      bookId,
      page: page !== undefined ? page : existingProgress?.page,
      percentage: percentage !== undefined ? percentage : existingProgress?.percentage,
      lastReadAt: lastReadAt || new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    readingProgress[key] = updatedProgress;
    res.json(updatedProgress);
  } catch (error) {
    next(error);
  }
});

// Get reading history for a user
router.get('/history', authenticate, async (req, res, next) => {
  try {
    const userId = req.query.userId || req.user.id;

    // Check if user can access this history
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    // Get all progress entries for this user
    const history = Object.keys(readingProgress)
      .filter(key => key.startsWith(`${userId}_`))
      .map(key => readingProgress[key])
      .sort((a, b) => new Date(b.lastReadAt) - new Date(a.lastReadAt));

    res.json(history);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

