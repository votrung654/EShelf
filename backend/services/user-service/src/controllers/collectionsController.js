const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Get user collections
exports.getCollections = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const collections = await prisma.collection.findMany({
      where: { userId },
      include: {
        books: {
          include: {
            book: true
          }
        }
      },
      orderBy: {
        updatedAt: 'desc'
      }
    });

    const formatted = collections.map(col => ({
      id: col.id,
      name: col.name,
      description: col.description,
      isPublic: col.isPublic,
      bookCount: col.books.length,
      books: col.books.map(cb => cb.bookId),
      createdAt: col.createdAt,
      updatedAt: col.updatedAt
    }));

    res.json({
      success: true,
      data: formatted
    });
  } catch (error) {
    console.error('Get collections error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Create collection
exports.createCollection = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, description, isPublic = false } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Tên bộ sưu tập không được để trống'
      });
    }

    const collection = await prisma.collection.create({
      data: {
        userId,
        name: name.trim(),
        description: description ? description.trim() : '',
        isPublic: Boolean(isPublic)
      },
      include: {
        books: true
      }
    });

    res.status(201).json({
      success: true,
      message: 'Tạo bộ sưu tập thành công',
      data: {
        ...collection,
        bookCount: 0,
        books: []
      }
    });
  } catch (error) {
    console.error('Create collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get collection by ID
exports.getCollectionById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const collection = await prisma.collection.findUnique({
      where: { id },
      include: {
        books: {
          include: {
            book: true
          }
        }
      }
    });

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bộ sưu tập'
      });
    }

    // Check access
    if (collection.userId !== userId && !collection.isPublic) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền truy cập'
      });
    }

    res.json({
      success: true,
      data: {
        ...collection,
        bookCount: collection.books.length,
        books: collection.books.map(cb => cb.book)
      }
    });
  } catch (error) {
    console.error('Get collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update collection
exports.updateCollection = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const { name, description, isPublic } = req.body;

    const collection = await prisma.collection.findUnique({
      where: { id }
    });

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bộ sưu tập'
      });
    }

    if (collection.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền sửa'
      });
    }

    const updated = await prisma.collection.update({
      where: { id },
      data: {
        name: name || collection.name,
        description: description !== undefined ? description : collection.description,
        isPublic: isPublic !== undefined ? isPublic : collection.isPublic
      }
    });

    res.json({
      success: true,
      message: 'Cập nhật bộ sưu tập thành công',
      data: updated
    });
  } catch (error) {
    console.error('Update collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Delete collection
exports.deleteCollection = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const collection = await prisma.collection.findUnique({
      where: { id }
    });

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bộ sưu tập'
      });
    }

    if (collection.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền xóa'
      });
    }

    await prisma.collection.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Xóa bộ sưu tập thành công'
    });
  } catch (error) {
    console.error('Delete collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Add book to collection
exports.addBookToCollection = async (req, res) => {
  try {
    const { id, bookId } = req.params;
    const userId = req.user.userId;

    const collection = await prisma.collection.findUnique({
      where: { id }
    });

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bộ sưu tập'
      });
    }

    if (collection.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền thêm sách'
      });
    }

    let actualBookId = bookId;
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    
    if (!isUUID) {
      try {
        const book = await prisma.book.findFirst({
          where: {
            OR: [
              { isbn: bookId },
              { id: bookId }
            ]
          },
          select: { id: true }
        });
        
        if (!book) {
          return res.status(404).json({
            success: false,
            message: 'Sách không tồn tại trong hệ thống'
          });
        }
        actualBookId = book.id;
      } catch (prismaError) {
        console.error('Prisma error when finding book:', prismaError);
        return res.status(500).json({
          success: false,
          message: 'Lỗi khi tìm sách trong database'
        });
      }
    }

    // Check if already exists
    const existing = await prisma.collectionBook.findUnique({
      where: {
        collectionId_bookId: {
          collectionId: id,
          bookId: actualBookId
        }
      }
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'Sách đã có trong bộ sưu tập'
      });
    }

    await prisma.collectionBook.create({
      data: {
        collectionId: id,
        bookId: actualBookId
      }
    });

    res.json({
      success: true,
      message: 'Đã thêm sách vào bộ sưu tập'
    });
  } catch (error) {
    console.error('Add book to collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Remove book from collection
exports.removeBookFromCollection = async (req, res) => {
  try {
    const { id, bookId } = req.params;
    const userId = req.user.userId;

    const collection = await prisma.collection.findUnique({
      where: { id }
    });

    if (!collection) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy bộ sưu tập'
      });
    }

    if (collection.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền xóa sách'
      });
    }

    let actualBookId = bookId;
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    if (!isUUID) {
      const book = await prisma.book.findFirst({
        where: {
          OR: [
            { isbn: bookId },
            { id: bookId }
          ]
        },
        select: { id: true }
      });
      if (!book) {
        return res.status(404).json({
          success: false,
          message: 'Sách không tồn tại trong hệ thống'
        });
      }
      actualBookId = book.id;
    }

    await prisma.collectionBook.delete({
      where: {
        collectionId_bookId: {
          collectionId: id,
          bookId: actualBookId
        }
      }
    });

    res.json({
      success: true,
      message: 'Đã xóa sách khỏi bộ sưu tập'
    });
  } catch (error) {
    console.error('Remove book from collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


