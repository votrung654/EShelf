const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const bookDetails = require('../../../../src/data/book-details.json');

// Get all books with pagination and filters
router.get('/', authenticate, async (req, res, next) => {
  try {
    const { page = 1, limit = 20, genre, search } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    let filteredBooks = [...bookDetails];

    // Apply filters
    if (genre) {
      filteredBooks = filteredBooks.filter(book => 
        book.genres?.some(g => g.toLowerCase() === genre.toLowerCase())
      );
    }

    if (search) {
      const searchLower = search.toLowerCase();
      filteredBooks = filteredBooks.filter(book =>
        book.title?.toLowerCase().includes(searchLower) ||
        book.author?.toLowerCase().includes(searchLower) ||
        book.description?.toLowerCase().includes(searchLower)
      );
    }

    // Pagination
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

// Get book by ID
router.get('/:bookId', authenticate, async (req, res, next) => {
  try {
    const { bookId } = req.params;
    const book = bookDetails.find(b => b.isbn === bookId || b.id === bookId);

    if (!book) {
      return res.status(404).json({ message: 'Book not found' });
    }

    res.json(book);
  } catch (error) {
    next(error);
  }
});

// Search books
router.get('/search', authenticate, async (req, res, next) => {
  try {
    const { q, genre, author } = req.query;

    if (!q) {
      return res.status(400).json({ message: 'Search query is required' });
    }

    let results = bookDetails.filter(book => {
      const matchesQuery = 
        book.title?.toLowerCase().includes(q.toLowerCase()) ||
        book.author?.toLowerCase().includes(q.toLowerCase()) ||
        book.description?.toLowerCase().includes(q.toLowerCase());

      const matchesGenre = !genre || book.genres?.some(g => 
        g.toLowerCase() === genre.toLowerCase()
      );

      const matchesAuthor = !author || book.author?.toLowerCase().includes(author.toLowerCase());

      return matchesQuery && matchesGenre && matchesAuthor;
    });

    res.json({
      query: q,
      results,
      count: results.length,
    });
  } catch (error) {
    next(error);
  }
});

// Get genres
router.get('/genres', authenticate, async (req, res, next) => {
  try {
    // Extract unique genres from books
    const genresSet = new Set();
    bookDetails.forEach(book => {
      if (book.genres && Array.isArray(book.genres)) {
        book.genres.forEach(genre => genresSet.add(genre));
      }
    });

    const genres = Array.from(genresSet).sort();
    res.json({ genres });
  } catch (error) {
    next(error);
  }
});

module.exports = router;

