// const express = require('express');
// const { body, validationResult } = require('express-validator');
// const authController = require('../controllers/authController');
// const { validateToken } = require('../middleware/validateToken');

// const router = express.Router();

// // Validation rules
// const registerValidation = [
//   body('email').isEmail().withMessage('Email không hợp lệ'),
//   body('password')
//     .isLength({ min: 8 })
//     .withMessage('Mật khẩu phải có ít nhất 8 ký tự')
//     .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
//     .withMessage('Mật khẩu phải chứa chữ hoa, chữ thường và số'),
//   body('username')
//     .isLength({ min: 3, max: 50 })
//     .withMessage('Tên người dùng phải từ 3-50 ký tự')
//     .matches(/^[a-zA-Z0-9_]+$/)
//     .withMessage('Tên người dùng chỉ chứa chữ cái, số và dấu gạch dưới'),
//   body('name').optional().isLength({ min: 2, max: 100 })
// ];

// const loginValidation = [
//   body('email').isEmail().withMessage('Email không hợp lệ'),
//   body('password').notEmpty().withMessage('Mật khẩu không được để trống')
// ];

// // Validation middleware
// const validate = (req, res, next) => {
//   const errors = validationResult(req);
//   if (!errors.isEmpty()) {
//     return res.status(400).json({
//       success: false,
//       errors: errors.array().map(err => ({
//         field: err.path,
//         message: err.msg
//       }))
//     });
//   }
//   next();
// };

// // Routes
// router.post('/register', registerValidation, validate, authController.register);
// router.post('/login', loginValidation, validate, authController.login);
// router.post('/refresh', authController.refreshToken);
// router.post('/logout', validateToken, authController.logout);
// router.post('/forgot-password', authController.forgotPassword);
// router.post('/reset-password', authController.resetPassword);
// router.get('/me', validateToken, authController.getCurrentUser);

// module.exports = router;
const express = require('express');
const { body, validationResult } = require('express-validator');
const authController = require('../controllers/authController');

// Lưu ý: Đảm bảo file middleware tên là 'auth.js' hoặc sửa đường dẫn bên dưới thành 'validateToken.js' tùy file bạn tạo
const { validateToken } = require('../middleware/auth'); 

const router = express.Router();

// --- CONFIG VALIDATION RULES ---
const registerValidation = [
  body('email').isEmail().withMessage('Email không hợp lệ'),
  body('password')
    .isLength({ min: 6 }) // Giảm xuống 6 cho dễ test, hoặc giữ 8 tùy bạn
    .withMessage('Mật khẩu phải có ít nhất 6 ký tự'),
    // .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/) // Tạm bỏ check khó để dễ dev
    // .withMessage('Mật khẩu phải chứa chữ hoa, chữ thường và số'),
  body('username')
    .isLength({ min: 3, max: 50 })
    .withMessage('Tên người dùng phải từ 3-50 ký tự')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Tên người dùng chỉ chứa chữ cái, số và dấu gạch dưới'),
  body('name').optional().isLength({ min: 2, max: 100 })
];

const loginValidation = [
  body('email').isEmail().withMessage('Email không hợp lệ'),
  body('password').notEmpty().withMessage('Mật khẩu không được để trống')
];

// --- MIDDLEWARE XỬ LÝ LỖI VALIDATION ---
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: errors.array()[0].msg, // Trả về lỗi đầu tiên cho gọn
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg
      }))
    });
  }
  next();
};

// --- DEFINING ROUTES ---

// 1. Đăng ký & Đăng nhập
router.post('/register', registerValidation, validate, authController.register);
router.post('/login', loginValidation, validate, authController.login);

// 2. Token management
router.post('/refresh', authController.refreshToken);
router.post('/logout', authController.logout);

// 3. User Info (QUAN TRỌNG: Dùng để fix lỗi 401 ở frontend)
router.get('/me', validateToken, authController.getCurrentUser);

// 4. Password management
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

module.exports = router;

