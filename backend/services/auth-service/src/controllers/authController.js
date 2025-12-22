const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { PrismaClient } = require('@prisma/client');

// Khởi tạo Prisma Client
const prisma = new PrismaClient();

// In-memory storage cho Refresh Token (Tạm thời giữ cái này để xử lý Logout)
// Lưu ý: Trong môi trường Production thực tế, nên dùng Redis để lưu cái này.
const refreshTokens = new Map();

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-change-in-production';
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

// Generate tokens
const generateTokens = (user) => {
  const accessToken = jwt.sign(
    { 
      userId: user.id, 
      email: user.email, 
      role: user.role 
    },
    JWT_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );

  const refreshToken = jwt.sign(
    { userId: user.id },
    JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );

  return { accessToken, refreshToken };
};

// Register
exports.register = async (req, res) => {
  try {
    const { email, password, username, name } = req.body;

    // 1. Kiểm tra user đã tồn tại trong DB chưa (Check Email hoặc Username)
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email: email },
          { username: username }
        ]
      }
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: existingUser.email === email 
          ? 'Email đã được sử dụng' 
          : 'Tên người dùng đã tồn tại'
      });
    }

    // 2. Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // 3. Tạo user mới trong DB
    const newUser = await prisma.user.create({
      data: {
        // id: uuidv4(), // Prisma thường tự sinh UUID nếu schema để @default(uuid()), nhưng để chắc chắn ta tự sinh
        email,
        username,
        name: name || username,
        passwordHash, // Lưu ý: Tên cột này phải khớp với schema.prisma (passwordHash hoặc password)
        role: 'USER', // Mặc định là USER
        emailVerified: false
      }
    });

    // 4. Generate tokens
    const tokens = generateTokens(newUser);
    refreshTokens.set(tokens.refreshToken, newUser.id);

    // Response (Bỏ password hash)
    const { passwordHash: _, ...userWithoutPassword } = newUser;
    
    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công',
      data: {
        user: userWithoutPassword,
        ...tokens
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
};

// Login
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Tìm user trong DB
    const user = await prisma.user.findUnique({
      where: { email: email }
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Email hoặc mật khẩu không đúng'
      });
    }

    // 2. Verify password
    const isMatch = await bcrypt.compare(password, user.passwordHash);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Email hoặc mật khẩu không đúng'
      });
    }

    // 3. Generate tokens
    const tokens = generateTokens(user);
    refreshTokens.set(tokens.refreshToken, user.id);

    // Response
    const { passwordHash: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      message: 'Đăng nhập thành công',
      data: {
        user: userWithoutPassword,
        ...tokens
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
};

// Refresh Token
exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token không được cung cấp'
      });
    }

    // Kiểm tra trong Map bộ nhớ (Để chặn các token đã logout)
    const storedUserId = refreshTokens.get(refreshToken);
    if (!storedUserId) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token không hợp lệ hoặc đã hết hạn'
      });
    }

    // Verify chữ ký JWT
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    } catch (error) {
      refreshTokens.delete(refreshToken);
      return res.status(401).json({
        success: false,
        message: 'Refresh token đã hết hạn'
      });
    }

    // Lấy user từ DB (ĐỂ ĐẢM BẢO USER VẪN TỒN TẠI)
    const user = await prisma.user.findUnique({
        where: { id: decoded.userId }
    });

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }

    // Generate new tokens
    refreshTokens.delete(refreshToken); // Xóa token cũ
    const tokens = generateTokens(user);
    refreshTokens.set(tokens.refreshToken, user.id); // Lưu token mới

    res.json({
      success: true,
      data: tokens
    });
  } catch (error) {
    console.error('Refresh token error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
};

// Logout
exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (refreshToken) {
      refreshTokens.delete(refreshToken);
    }

    res.json({
      success: true,
      message: 'Đăng xuất thành công'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
};

// Forgot Password (Mock - chưa có DB lưu token reset)
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    // Check user tồn tại trong DB cho chắc
    const user = await prisma.user.findUnique({ where: { email } });

    res.json({
      success: true,
      message: 'Nếu email tồn tại, bạn sẽ nhận được link đặt lại mật khẩu'
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Reset Password (Mock)
exports.resetPassword = async (req, res) => {
  try {
    // Logic reset password cần lưu token vào DB hoặc Redis
    // Tạm thời trả về thành công
    res.json({
      success: true,
      message: 'Đặt lại mật khẩu thành công'
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get Current User
exports.getCurrentUser = async (req, res) => {
  try {
    // Lấy thông tin từ DB dựa trên ID trong Token
    const user = await prisma.user.findUnique({
        where: { id: req.user.userId }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Người dùng không tồn tại'
      });
    }

    const { passwordHash: _, ...userWithoutPassword } = user;

    res.json({
      success: true,
      data: userWithoutPassword
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi server'
    });
  }
};

