const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Get reading history - từ database
exports.getReadingHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const history = await prisma.readingHistory.findMany({
      where: { userId },
      include: {
        book: true
      },
      orderBy: {
        lastReadAt: 'desc'
      },
      take: 50
    });

    res.json({
      success: true,
      data: history
    });
  } catch (error) {
    console.error('Get reading history error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Save reading progress - vào database
exports.saveReadingProgress = async (req, res) => {
  try {
    const userId = req.user.userId;
    let { bookId, currentPage, totalPages } = req.body;

    if (!bookId || currentPage === undefined || !totalPages) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu thông tin cần thiết'
      });
    }

    // Nếu bookId là ISBN (không phải UUID), tìm book bằng ISBN để lấy id
    const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookId);
    console.log('saveReadingProgress - bookId:', bookId, 'isUUID:', isUUID);
    
    if (!isUUID) {
      console.log('Converting ISBN to UUID. ISBN:', bookId);
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
          bookId = bookById.id;
        } else {
          console.log('Found book. UUID:', book.id, 'Title:', book.title);
          bookId = book.id;
        }
      } catch (prismaError) {
        console.error('Prisma error when finding book:', prismaError);
        return res.status(500).json({
          success: false,
          message: 'Lỗi khi tìm sách trong database'
        });
      }
    }
    
    console.log('Using bookId (UUID):', bookId);

    const progressPercent = Math.min(Math.round((currentPage / totalPages) * 100), 100);
    const finishedAt = currentPage >= totalPages ? new Date() : null;

    // Prisma không hỗ trợ composite key trong upsert với @@unique, cần dùng findFirst + create/update
    const existing = await prisma.readingHistory.findFirst({
      where: {
        userId,
        bookId
      }
    });

    const entry = existing 
      ? await prisma.readingHistory.update({
          where: { id: existing.id },
          data: {
            currentPage,
            totalPages,
            progressPercent,
            lastReadAt: new Date(),
            finishedAt
          },
          include: {
            book: true
          }
        })
      : await prisma.readingHistory.create({
          data: {
            userId,
            bookId,
            currentPage,
            totalPages,
            progressPercent,
            lastReadAt: new Date(),
            startedAt: new Date(),
            finishedAt
          },
          include: {
            book: true
          }
        });

    res.json({
      success: true,
      message: 'Đã lưu tiến độ đọc',
      data: entry
    });
  } catch (error) {
    console.error('Save reading progress error:', error);
    // Log chi tiết lỗi để debug
    if (error.code === 'P2003') {
      console.error('Foreign key constraint failed. bookId:', req.body.bookId);
      return res.status(400).json({ 
        success: false, 
        message: 'Sách không tồn tại trong hệ thống' 
      });
    }
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get book progress - từ database
exports.getBookProgress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    const entry = await prisma.readingHistory.findFirst({
      where: {
        userId,
        bookId
      },
      include: {
        book: true
      }
    });

    res.json({
      success: true,
      data: entry
    });
  } catch (error) {
    console.error('Get book progress error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Delete book history - khỏi database
exports.deleteBookHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    const entry = await prisma.readingHistory.findFirst({
      where: {
        userId,
        bookId
      }
    });

    if (entry) {
      await prisma.readingHistory.delete({
        where: { id: entry.id }
      });
    }

    res.json({
      success: true,
      message: 'Đã xóa lịch sử đọc'
    });
  } catch (error) {
    console.error('Delete book history error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


