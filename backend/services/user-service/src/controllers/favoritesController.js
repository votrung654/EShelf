const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Get favorites - từ database
exports.getFavorites = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const favorites = await prisma.favorite.findMany({
      where: { userId },
      include: {
        book: true
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    // Trả về array bookIds để frontend xử lý
    const bookIds = favorites.map(f => f.bookId);

    res.json({
      success: true,
      data: bookIds
    });
  } catch (error) {
    console.error('Get favorites error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Add favorite - vào database
exports.addFavorite = async (req, res) => {
  try {
    const userId = req.user.userId;
    let { bookId } = req.params;

    // Nếu bookId là ISBN (không phải UUID), tìm book bằng ISBN để lấy id
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    if (!isUUID) {
      const book = await prisma.book.findUnique({
        where: { isbn: bookId },
        select: { id: true }
      });
      if (!book) {
        return res.status(404).json({
          success: false,
          message: 'Sách không tồn tại trong hệ thống'
        });
      }
      bookId = book.id;
    }

    // Check if already exists (Favorite có composite key @@id([userId, bookId]))
    const existing = await prisma.favorite.findUnique({
      where: {
        userId_bookId: {
          userId,
          bookId
        }
      }
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'Sách đã có trong yêu thích'
      });
    }

    await prisma.favorite.create({
      data: {
        userId,
        bookId
      }
    });

    res.json({
      success: true,
      message: 'Đã thêm vào yêu thích'
    });
  } catch (error) {
    console.error('Add favorite error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Remove favorite - khỏi database
exports.removeFavorite = async (req, res) => {
  try {
    const userId = req.user.userId;
    let { bookId } = req.params;

    // Nếu bookId là ISBN (không phải UUID), tìm book bằng ISBN để lấy id
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    if (!isUUID) {
      const book = await prisma.book.findUnique({
        where: { isbn: bookId },
        select: { id: true }
      });
      if (!book) {
        return res.status(404).json({
          success: false,
          message: 'Sách không tồn tại trong hệ thống'
        });
      }
      bookId = book.id;
    }

    // Favorite có composite key @@id([userId, bookId]) nên có thể dùng findUnique
    await prisma.favorite.delete({
      where: {
        userId_bookId: {
          userId,
          bookId
        }
      }
    });

    res.json({
      success: true,
      message: 'Đã xóa khỏi yêu thích'
    });
  } catch (error) {
    console.error('Remove favorite error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Check if book is favorite - từ database
exports.checkFavorite = async (req, res) => {
  try {
    const userId = req.user.userId;
    let { bookId } = req.params;

    // Nếu bookId là ISBN (không phải UUID), tìm book bằng ISBN để lấy id
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    if (!isUUID) {
      const book = await prisma.book.findUnique({
        where: { isbn: bookId },
        select: { id: true }
      });
      if (!book) {
        return res.json({
          success: true,
          data: { isFavorite: false }
        });
      }
      bookId = book.id;
    }

    const favorite = await prisma.favorite.findUnique({
      where: {
        userId_bookId: {
          userId,
          bookId
        }
      }
    });

    res.json({
      success: true,
      data: { isFavorite: !!favorite }
    });
  } catch (error) {
    console.error('Check favorite error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


