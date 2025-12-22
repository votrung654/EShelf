const express = require('express');
const { body, query, param, validationResult } = require('express-validator');
const bookController = require('../controllers/bookController');
const { validateToken, optionalToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Validation middleware
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg
      }))
    });
  }
  next();
};

// Book validation
const bookValidation = [
  body('title').notEmpty().withMessage('Tiêu đề không được để trống'),
  body('author').isArray({ min: 1 }).withMessage('Phải có ít nhất một tác giả'),
  body('genres').optional().isArray(),
  body('year').optional().isInt({ min: 1000, max: new Date().getFullYear() + 1 }),
  body('pages').optional().isInt({ min: 1 }),
  body('language').optional().isString()
];

// Public routes
router.get('/', optionalToken, bookController.getAllBooks);
router.get('/search', optionalToken, bookController.searchBooks);
router.get('/featured', bookController.getFeaturedBooks);
router.get('/popular', bookController.getPopularBooks);
router.get('/:id', optionalToken, bookController.getBookById);
router.get('/:id/reviews', bookController.getBookReviews);

// Protected routes
router.post('/:id/reviews', validateToken, bookController.addReview);

// Admin routes
router.post('/', validateToken, requireAdmin, bookValidation, validate, bookController.createBook);
router.put('/:id', validateToken, requireAdmin, bookValidation, validate, bookController.updateBook);
router.delete('/:id', validateToken, requireAdmin, bookController.deleteBook);

module.exports = router;


