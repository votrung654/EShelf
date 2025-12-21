const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');

// Mock collections storage (in production, use database)
const collections = {};

// Get all collections for a user
router.get('/', authenticate, async (req, res, next) => {
  try {
    const userId = req.query.userId || req.user.id;

    // Check if user can access these collections
    if (userId !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    const userCollections = collections[userId] || [];
    res.json(userCollections);
  } catch (error) {
    next(error);
  }
});

// Get collection by ID
router.get('/:collectionId', authenticate, async (req, res, next) => {
  try {
    const { collectionId } = req.params;
    
    // Find collection across all users
    let foundCollection = null;
    for (const userId in collections) {
      const collection = collections[userId].find(c => c.id === collectionId);
      if (collection) {
        foundCollection = collection;
        // Check if user can access
        if (userId !== req.user.id && req.user.role !== 'admin') {
          return res.status(403).json({ message: 'Forbidden' });
        }
        break;
      }
    }

    if (!foundCollection) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    res.json(foundCollection);
  } catch (error) {
    next(error);
  }
});

// Create collection
router.post('/', authenticate, async (req, res, next) => {
  try {
    const { name, description } = req.body;
    const userId = req.user.id;

    if (!name) {
      return res.status(400).json({ message: 'Collection name is required' });
    }

    if (!collections[userId]) {
      collections[userId] = [];
    }

    const newCollection = {
      id: `collection_${Date.now()}`,
      userId,
      name,
      description: description || '',
      books: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    collections[userId].push(newCollection);
    res.status(201).json(newCollection);
  } catch (error) {
    next(error);
  }
});

// Update collection
router.put('/:collectionId', authenticate, async (req, res, next) => {
  try {
    const { collectionId } = req.params;
    const userId = req.user.id;

    if (!collections[userId]) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    const collectionIndex = collections[userId].findIndex(c => c.id === collectionId);
    if (collectionIndex === -1) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    collections[userId][collectionIndex] = {
      ...collections[userId][collectionIndex],
      ...req.body,
      updatedAt: new Date().toISOString(),
    };

    res.json(collections[userId][collectionIndex]);
  } catch (error) {
    next(error);
  }
});

// Delete collection
router.delete('/:collectionId', authenticate, async (req, res, next) => {
  try {
    const { collectionId } = req.params;
    const userId = req.user.id;

    if (!collections[userId]) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    const collectionIndex = collections[userId].findIndex(c => c.id === collectionId);
    if (collectionIndex === -1) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    collections[userId].splice(collectionIndex, 1);
    res.json({ message: 'Collection deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Add book to collection
router.post('/:collectionId/books', authenticate, async (req, res, next) => {
  try {
    const { collectionId } = req.params;
    const { bookId } = req.body;
    const userId = req.user.id;

    if (!bookId) {
      return res.status(400).json({ message: 'Book ID is required' });
    }

    if (!collections[userId]) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    const collection = collections[userId].find(c => c.id === collectionId);
    if (!collection) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    // Check if book already exists
    if (collection.books.some(b => b.id === bookId || b.isbn === bookId)) {
      return res.status(409).json({ message: 'Book already in collection' });
    }

    // Add book (in production, fetch book details from Book Service)
    collection.books.push({ id: bookId, addedAt: new Date().toISOString() });
    collection.updatedAt = new Date().toISOString();

    res.json(collection);
  } catch (error) {
    next(error);
  }
});

// Remove book from collection
router.delete('/:collectionId/books/:bookId', authenticate, async (req, res, next) => {
  try {
    const { collectionId, bookId } = req.params;
    const userId = req.user.id;

    if (!collections[userId]) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    const collection = collections[userId].find(c => c.id === collectionId);
    if (!collection) {
      return res.status(404).json({ message: 'Collection not found' });
    }

    const bookIndex = collection.books.findIndex(
      b => b.id === bookId || b.isbn === bookId
    );
    if (bookIndex === -1) {
      return res.status(404).json({ message: 'Book not found in collection' });
    }

    collection.books.splice(bookIndex, 1);
    collection.updatedAt = new Date().toISOString();

    res.json(collection);
  } catch (error) {
    next(error);
  }
});

module.exports = router;

