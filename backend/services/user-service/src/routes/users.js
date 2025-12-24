const express = require('express');
const { validateToken, requireAdmin } = require('../middleware/auth');
const usersController = require('../controllers/usersController');

const router = express.Router();

// Tất cả routes này cần admin
router.use(validateToken);
router.use(requireAdmin);

// Logging middleware for debugging
router.use((req, res, next) => {
  console.log(`[Users Route] ${req.method} ${req.path} - Query:`, req.query);
  next();
});

router.get('/', usersController.getAllUsers);
router.get('/stats', usersController.getUserStats);
router.get('/:id', usersController.getUserById);
router.put('/:id', usersController.updateUser);
router.delete('/:id', usersController.deleteUser);

module.exports = router;


