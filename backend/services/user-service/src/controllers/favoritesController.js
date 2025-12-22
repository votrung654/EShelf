// In-memory storage
const favorites = new Map(); // userId -> Set of bookIds

// Get favorites
exports.getFavorites = async (req, res) => {
  try {
    const userId = req.user.userId;
    const userFavorites = favorites.get(userId) || new Set();

    res.json({
      success: true,
      data: Array.from(userFavorites)
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Add favorite
exports.addFavorite = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    let userFavorites = favorites.get(userId);
    if (!userFavorites) {
      userFavorites = new Set();
      favorites.set(userId, userFavorites);
    }

    userFavorites.add(bookId);

    res.json({
      success: true,
      message: 'Đã thêm vào yêu thích'
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Remove favorite
exports.removeFavorite = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    const userFavorites = favorites.get(userId);
    if (userFavorites) {
      userFavorites.delete(bookId);
    }

    res.json({
      success: true,
      message: 'Đã xóa khỏi yêu thích'
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Check if book is favorite
exports.checkFavorite = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    const userFavorites = favorites.get(userId);
    const isFavorite = userFavorites ? userFavorites.has(bookId) : false;

    res.json({
      success: true,
      data: { isFavorite }
    });
  } catch (error) {
    console.error('Check favorite error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


