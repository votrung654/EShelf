const express = require('express');
const genreController = require('../controllers/genreController');

// Nếu bạn CHƯA copy file middleware auth sang book-service, hãy comment dòng dưới lại
// const { validateToken, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Public routes (Ai cũng xem được)
router.get('/', genreController.getAllGenres);
router.get('/:slug', genreController.getGenreBySlug);
router.get('/:slug/books', genreController.getBooksByGenre);

// Admin routes 
// (Tạm thời mở public để test trước, sau này thêm middleware sau nếu cần bảo mật chặt)
router.post('/', genreController.createGenre); 
router.put('/:id', genreController.updateGenre);
router.delete('/:id', genreController.deleteGenre);

/* // KHI NÀO CÓ MIDDLEWARE AUTH THÌ DÙNG CÁI NÀY:
router.post('/', validateToken, requireAdmin, genreController.createGenre);
router.put('/:id', validateToken, requireAdmin, genreController.updateGenre);
router.delete('/:id', validateToken, requireAdmin, genreController.deleteGenre);
*/

module.exports = router;