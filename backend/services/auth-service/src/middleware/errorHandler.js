exports.errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Dữ liệu không hợp lệ',
      errors: err.errors
    });
  }

  if (err.name === 'UnauthorizedError') {
    return res.status(401).json({
      success: false,
      message: 'Không có quyền truy cập'
    });
  }

  res.status(500).json({
    success: false,
    message: 'Lỗi server',
    ...(process.env.NODE_ENV === 'development' && { error: err.message })
  });
};


