const express = require('express');
const { validateToken } = require('../middleware/auth');
const favoritesController = require('../controllers/favoritesController');

const router = express.Router();

router.get('/', validateToken, favoritesController.getFavorites);
router.post('/:bookId', validateToken, favoritesController.addFavorite);
router.delete('/:bookId', validateToken, favoritesController.removeFavorite);
router.get('/check/:bookId', validateToken, favoritesController.checkFavorite);

module.exports = router;


