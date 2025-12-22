const jwt = require('jsonwebtoken');

exports.validateToken = (req, res, next) => {
  // Lấy token từ header: "Authorization: Bearer <token>"
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; 

  if (!token) {
    return res.status(401).json({ 
      success: false, 
      message: 'Token missing (Vui lòng đăng nhập)' 
    });
  }

  try {
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key-change-in-production');
    
    // Gán thông tin user vào request để các hàm sau dùng
    req.user = decoded; 
    
    next(); // Cho phép đi tiếp
  } catch (error) {
    console.error("Token verification failed:", error.message);
    return res.status(403).json({ 
      success: false, 
      message: 'Token invalid or expired (Phiên đăng nhập hết hạn)' 
    });
  }
};