const express = require('express');
const { validateToken } = require('../middleware/auth');
const historyController = require('../controllers/historyController');

const router = express.Router();

router.get('/', validateToken, historyController.getReadingHistory);
router.post('/', validateToken, historyController.saveReadingProgress);
router.get('/:bookId', validateToken, historyController.getBookProgress);
router.delete('/:bookId', validateToken, historyController.deleteBookHistory);

module.exports = router;


