const express = require('express');
const { validateToken } = require('../middleware/auth');
const collectionsController = require('../controllers/collectionsController');

const router = express.Router();

router.get('/', validateToken, collectionsController.getCollections);
router.post('/', validateToken, collectionsController.createCollection);
router.get('/:id', validateToken, collectionsController.getCollectionById);
router.put('/:id', validateToken, collectionsController.updateCollection);
router.delete('/:id', validateToken, collectionsController.deleteCollection);
router.post('/:id/books/:bookId', validateToken, collectionsController.addBookToCollection);
router.delete('/:id/books/:bookId', validateToken, collectionsController.removeBookFromCollection);

module.exports = router;


