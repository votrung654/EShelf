const express = require('express');
const genreController = require('../controllers/genreController');
const { validateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Public routes
router.get('/', genreController.getAllGenres);
router.get('/:slug', genreController.getGenreBySlug);
router.get('/:slug/books', genreController.getBooksByGenre);

// Admin routes
router.post('/', validateToken, requireAdmin, genreController.createGenre);
router.put('/:id', validateToken, requireAdmin, genreController.updateGenre);
router.delete('/:id', validateToken, requireAdmin, genreController.deleteGenre);

module.exports = router;


