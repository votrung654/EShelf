const express = require('express');
const genreController = require('../controllers/genreController');

const router = express.Router();

// Public routes
router.get('/', genreController.getAllGenres);
router.get('/:slug', genreController.getGenreBySlug);
router.get('/:slug/books', genreController.getBooksByGenre);

// Admin routes (TODO: Add auth middleware)
router.post('/', genreController.createGenre); 
router.put('/:id', genreController.updateGenre);
router.delete('/:id', genreController.deleteGenre);

module.exports = router;