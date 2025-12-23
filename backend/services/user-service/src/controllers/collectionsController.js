const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');
const prisma = new PrismaClient();

// In-memory storage
const collections = new Map(); // collectionId -> collection
const userCollections = new Map(); // userId -> Set of collectionIds

// Get user collections - từ database
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

    // Format response để frontend dễ xử lý
    const formatted = collections.map(col => ({
      id: col.id,
      name: col.name,
      description: col.description,
      isPublic: col.isPublic,
      bookCount: col.books.length,
      books: col.books.map(cb => cb.bookId), // Chỉ trả về array bookIds
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

// Create collection - vào database
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

// Get collection by ID - từ database
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
        books: collection.books.map(cb => cb.book) // Trả về full book objects
      }
    });
  } catch (error) {
    console.error('Get collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update collection - database
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

// Delete collection - khỏi database
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

// Add book to collection - database
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

    // Nếu bookId là ISBN (không phải UUID), tìm book bằng ISBN để lấy id
    let actualBookId = bookId;
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    console.log('addBookToCollection - bookId:', bookId, 'isUUID:', isUUID);
    
    if (!isUUID) {
      console.log('Converting ISBN to UUID for collection. ISBN:', bookId);
      try {
        const book = await prisma.book.findUnique({
          where: { isbn: bookId },
          select: { id: true, isbn: true, title: true }
        });
        if (!book) {
          console.error('Book not found with ISBN:', bookId);
          // Thử tìm bằng id nếu ISBN không tìm thấy
          const bookById = await prisma.book.findUnique({
            where: { id: bookId },
            select: { id: true }
          });
          if (!bookById) {
            // Debug: List một vài books để xem có gì trong DB
            const sampleBooks = await prisma.book.findMany({ take: 3, select: { id: true, isbn: true, title: true } });
            console.error('Sample books in DB:', sampleBooks);
            return res.status(404).json({
              success: false,
              message: `Sách không tồn tại trong hệ thống (ISBN/ID: ${bookId})`
            });
          }
          actualBookId = bookById.id;
        } else {
          console.log('Found book for collection. UUID:', book.id, 'Title:', book.title);
          actualBookId = book.id;
        }
      } catch (prismaError) {
        console.error('Prisma error when finding book:', prismaError);
        return res.status(500).json({
          success: false,
          message: 'Lỗi khi tìm sách trong database'
        });
      }
    }
    
    console.log('Using actualBookId (UUID):', actualBookId);

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

// Remove book from collection - database
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

    // Nếu bookId là ISBN (không phải UUID), tìm book bằng ISBN để lấy id
    let actualBookId = bookId;
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


