exports.errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  res.status(500).json({
    success: false,
    message: 'Lỗi server',
    ...(process.env.NODE_ENV === 'development' && { error: err.message })
  });
};


