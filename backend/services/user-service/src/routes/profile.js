const express = require('express');
const { validateToken } = require('../middleware/auth');
const profileController = require('../controllers/profileController');

const router = express.Router();

router.get('/', validateToken, profileController.getProfile);
router.put('/', validateToken, profileController.updateProfile);
router.put('/avatar', validateToken, profileController.updateAvatar);
router.get('/stats', validateToken, profileController.getStats);

module.exports = router;


