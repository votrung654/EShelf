const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/auth');
const bookDetails = require('../../../../src/data/book-details.json');

// All admin routes require authentication and admin role
router.use(authenticate);
router.use(requireAdmin);

// Mock books storage for admin operations
let adminBooks = [...bookDetails];

// Get all books (admin view with pagination)
router.get('/books', async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, genre } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    let filteredBooks = [...adminBooks];

    if (search) {
      const searchLower = search.toLowerCase();
      filteredBooks = filteredBooks.filter(book =>
        book.title?.toLowerCase().includes(searchLower) ||
        book.author?.toLowerCase().includes(searchLower)
      );
    }

    if (genre) {
      filteredBooks = filteredBooks.filter(book =>
        book.genres?.some(g => g.toLowerCase() === genre.toLowerCase())
      );
    }

    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedBooks = filteredBooks.slice(startIndex, endIndex);

    res.json({
      books: paginatedBooks,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: filteredBooks.length,
        totalPages: Math.ceil(filteredBooks.length / limitNum),
      },
    });
  } catch (error) {
    next(error);
  }
});

// Create book
router.post('/books', async (req, res, next) => {
  try {
    const { title, author, description, genres, coverUrl, pdfUrl } = req.body;

    if (!title || !author) {
      return res.status(400).json({ message: 'Title and author are required' });
    }

    const newBook = {
      id: `book_${Date.now()}`,
      isbn: `ISBN_${Date.now()}`,
      title,
      author,
      description: description || '',
      genres: genres || [],
      coverUrl: coverUrl || '',
      pdfUrl: pdfUrl || '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    adminBooks.push(newBook);
    res.status(201).json(newBook);
  } catch (error) {
    next(error);
  }
});

// Update book
router.put('/books/:bookId', async (req, res, next) => {
  try {
    const { bookId } = req.params;
    const bookIndex = adminBooks.findIndex(
      b => b.id === bookId || b.isbn === bookId
    );

    if (bookIndex === -1) {
      return res.status(404).json({ message: 'Book not found' });
    }

    adminBooks[bookIndex] = {
      ...adminBooks[bookIndex],
      ...req.body,
      updatedAt: new Date().toISOString(),
    };

    res.json(adminBooks[bookIndex]);
  } catch (error) {
    next(error);
  }
});

// Delete book
router.delete('/books/:bookId', async (req, res, next) => {
  try {
    const { bookId } = req.params;
    const bookIndex = adminBooks.findIndex(
      b => b.id === bookId || b.isbn === bookId
    );

    if (bookIndex === -1) {
      return res.status(404).json({ message: 'Book not found' });
    }

    adminBooks.splice(bookIndex, 1);
    res.json({ message: 'Book deleted successfully' });
  } catch (error) {
    next(error);
  }
});

// Get all users (admin only)
router.get('/users', async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    // In production, fetch from User Service
    res.json({
      users: [],
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: 0,
        totalPages: 0,
      },
    });
  } catch (error) {
    next(error);
  }
});

// Get admin stats
router.get('/stats', async (req, res, next) => {
  try {
    // In production, fetch from various services
    res.json({
      totalBooks: adminBooks.length,
      totalUsers: 0,
      totalCollections: 0,
      totalReadingSessions: 0,
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

