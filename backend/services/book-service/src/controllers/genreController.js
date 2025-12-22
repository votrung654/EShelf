const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// Lấy danh sách tất cả thể loại
exports.getAllGenres = async (req, res) => {
  try {
    const genres = await prisma.genre.findMany({
      orderBy: { name: 'asc' },
      // (Tùy chọn) Đếm số lượng sách trong mỗi thể loại nếu muốn
      /*
      include: {
        _count: {
          select: { books: true }
        }
      }
      */
    });

    res.json({
      success: true,
      data: genres
    });
  } catch (error) {
    console.error('Get all genres error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server khi lấy danh sách thể loại' });
  }
};

// Lấy chi tiết thể loại theo slug
exports.getGenreBySlug = async (req, res) => {
  try {
    const { slug } = req.params;

    const genre = await prisma.genre.findFirst({
      where: {
        OR: [
          { slug: slug },
          { name: { equals: slug, mode: 'insensitive' } }
        ]
      }
    });

    if (!genre) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thể loại'
      });
    }

    res.json({
      success: true,
      data: genre
    });
  } catch (error) {
    console.error('Get genre by slug error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Lấy danh sách sách thuộc thể loại
exports.getBooksByGenre = async (req, res) => {
  try {
    const { slug } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // 1. Tìm Genre trước
    const genre = await prisma.genre.findFirst({
      where: {
        OR: [
          { slug: slug },
          { name: { equals: slug, mode: 'insensitive' } }
        ]
      }
    });

    if (!genre) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thể loại'
      });
    }

    // 2. Tìm Sách thuộc Genre đó
    // Sử dụng quan hệ many-to-many của Prisma (some)
    const books = await prisma.book.findMany({
      where: {
        genres: {
          some: {
            genreId: genre.id
          }
        }
      },
      skip,
      take: limit,
      include: {
        genres: {
            include: { genre: true } // Kèm thông tin genre để hiển thị
        }
      }
    });

    // 3. Đếm tổng số sách để phân trang
    const totalBooks = await prisma.book.count({
      where: {
        genres: {
          some: { genreId: genre.id }
        }
      }
    });

    res.json({
      success: true,
      data: {
        genre,
        books: books
      },
      pagination: {
        page,
        limit,
        total: totalBooks,
        totalPages: Math.ceil(totalBooks / limit)
      }
    });
  } catch (error) {
    console.error('Get books by genre error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Create genre (Admin)
exports.createGenre = async (req, res) => {
  try {
    const { name, description } = req.body;
    const slug = name.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');

    const newGenre = await prisma.genre.create({
      data: {
        name,
        slug,
        description
      }
    });

    res.status(201).json({
      success: true,
      message: 'Tạo thể loại thành công',
      data: newGenre
    });
  } catch (error) {
    console.error('Create genre error:', error);
    // Handle duplicate error (P2002)
    if (error.code === 'P2002') {
        return res.status(400).json({ success: false, message: 'Thể loại này đã tồn tại' });
    }
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update genre (Admin)
exports.updateGenre = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;
    
    // Nếu đổi tên thì update cả slug
    const dataToUpdate = { description };
    if (name) {
        dataToUpdate.name = name;
        dataToUpdate.slug = name.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, '');
    }

    const updatedGenre = await prisma.genre.update({
      where: { id },
      data: dataToUpdate
    });

    res.json({
      success: true,
      message: 'Cập nhật thể loại thành công',
      data: updatedGenre
    });
  } catch (error) {
    console.error('Update genre error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Delete genre (Admin)
exports.deleteGenre = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.genre.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Xóa thể loại thành công'
    });
  } catch (error) {
    console.error('Delete genre error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};