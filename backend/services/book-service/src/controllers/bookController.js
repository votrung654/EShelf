const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// ==========================================
// 1. GET ALL BOOKS (Trang chủ)
// ==========================================
exports.getAllBooks = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const sortBy = req.query.sortBy || 'createdAt';
    const order = req.query.order || 'desc';
    const skip = (page - 1) * limit;

    const orderBy = {};
    orderBy[sortBy] = order;

    // Lấy dữ liệu và đếm tổng song song
    const [books, total] = await Promise.all([
      prisma.book.findMany({
        skip,
        take: limit,
        orderBy,
        include: {
          genres: {
            include: { genre: true }
          }
        }
      }),
      prisma.book.count()
    ]);

    // Format dữ liệu trả về cho Frontend
    res.json({
      success: true,
      data: {
        books: books.map(book => ({
          ...book,
          genres: book.genres.map(bg => bg.genre.name) // Chuyển object genre thành mảng tên
        })),
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get all books error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// ==========================================
// 2. SEARCH BOOKS (Tìm kiếm nâng cao)
// ==========================================
exports.searchBooks = async (req, res) => {
  try {
    const { q, genre, year, fromYear, toYear, language, page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    console.log('Search request params:', { q, genre, year, fromYear, toYear, language, page, limit });
    
    // Xây dựng điều kiện lọc (Where clause)
    const where = {};

    // Tìm kiếm text (Title, ISBN, Description)
    if (q) {
      where.OR = [
        { title: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { isbn: { contains: q, mode: 'insensitive' } }
      ];
    }

    // Lọc theo thể loại
    if (genre && genre !== 'all') {
      where.genres = {
        some: {
          genre: {
            OR: [
              { name: { equals: genre, mode: 'insensitive' } },
              { slug: { equals: genre, mode: 'insensitive' } }
            ]
          }
        }
      };
    }

    // Lọc theo năm (hỗ trợ cả year cụ thể và range fromYear-toYear)
    if (year) {
      where.publishedYear = parseInt(year);
    } else if (fromYear || toYear) {
      const yearFilter = {};
      if (fromYear) {
        yearFilter.gte = parseInt(fromYear);
      }
      if (toYear) {
        yearFilter.lte = parseInt(toYear);
      }
      // Chỉ thêm filter nếu có ít nhất một điều kiện
      if (Object.keys(yearFilter).length > 0) {
        where.publishedYear = yearFilter;
      }
    }
    
    // Lọc theo ngôn ngữ
    if (language) {
      where.language = { equals: language, mode: 'insensitive' };
    }

    console.log('Where clause:', JSON.stringify(where, null, 2));

    // Nếu không có bất kỳ điều kiện nào, trả về mảng rỗng thay vì tất cả sách
    const hasAnyFilter = q || (genre && genre !== 'all') || year || fromYear || toYear || language;
    if (!hasAnyFilter) {
      console.log('No filters provided, returning empty array');
      return res.json({
        success: true,
        data: {
          books: [],
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: 0,
            totalPages: 0
          }
        }
      });
    }

    const [results, total] = await Promise.all([
      prisma.book.findMany({
        where,
        skip,
        take: parseInt(limit),
        include: {
          genres: { include: { genre: true } }
        },
        orderBy: { createdAt: 'desc' }
      }),
      prisma.book.count({ where })
    ]);

    console.log(`Found ${total} books matching criteria`);

    res.json({
      success: true,
      data: {
        books: results.map(book => ({
          ...book,
          genres: book.genres.map(bg => bg.genre.name)
        })),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          totalPages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Search books error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// ==========================================
// 3. GET BOOK BY ID (Chi tiết sách)
// ==========================================
exports.getBookById = async (req, res) => {
  try {
    const { id } = req.params;

    const book = await prisma.book.findFirst({
      where: {
        OR: [
          { id: id },   // UUID
          { isbn: id }  // ISBN
        ]
      },
      include: {
        genres: { include: { genre: true } },
        reviews: {
          include: {
            user: { select: { id: true, username: true, name: true, avatarUrl: true } }
          },
          orderBy: { createdAt: 'desc' }
        }
      }
    });

    if (!book) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy sách' });
    }

    // Tăng lượt xem (View Count)
    await prisma.book.update({
      where: { id: book.id },
      data: { viewCount: { increment: 1 } }
    });

    res.json({
      success: true,
      data: {
        ...book,
        genres: book.genres.map(bg => bg.genre.name),
        // Trả về viewCount mới
        viewCount: book.viewCount + 1 
      }
    });
  } catch (error) {
    console.error('Get book by ID error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// ==========================================
// 4. GET FEATURED & POPULAR (Gợi ý)
// ==========================================
exports.getFeaturedBooks = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const featured = await prisma.book.findMany({
      take: limit,
      orderBy: [
        { ratingAvg: 'desc' }, // Điểm cao nhất
        { ratingCount: 'desc' } // Nhiều người vote nhất
      ],
      include: { genres: { include: { genre: true } } }
    });

    res.json({
      success: true,
      data: featured.map(book => ({ ...book, genres: book.genres.map(bg => bg.genre.name) }))
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

exports.getPopularBooks = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const popular = await prisma.book.findMany({
      take: limit,
      orderBy: { viewCount: 'desc' }, // Xem nhiều nhất
      include: { genres: { include: { genre: true } } }
    });

    res.json({
      success: true,
      data: popular.map(book => ({ ...book, genres: book.genres.map(bg => bg.genre.name) }))
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// ==========================================
// 5. REVIEWS & RATINGS
// ==========================================
exports.getBookReviews = async (req, res) => {
  try {
    const { id } = req.params;
    const book = await prisma.book.findFirst({
        where: { OR: [{id: id}, {isbn: id}] }
    });
    
    if(!book) return res.status(404).json({success: false, message: 'Book not found'});

    const reviews = await prisma.review.findMany({
      where: { bookId: book.id },
      include: {
        user: { select: { id: true, username: true, name: true, avatarUrl: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: reviews });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

exports.addReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, content } = req.body;
    const userId = req.user.userId; // Lấy từ middleware auth

    const book = await prisma.book.findFirst({
      where: { OR: [{ id }, { isbn: id }] }
    });

    if (!book) return res.status(404).json({ success: false, message: 'Không tìm thấy sách' });

    // Tạo hoặc cập nhật review
    const review = await prisma.review.upsert({
      where: {
        userId_bookId: { userId, bookId: book.id }
      },
      update: { rating, content, updatedAt: new Date() },
      create: { userId, bookId: book.id, rating, content },
      include: { user: { select: { id: true, username: true, name: true } } }
    });

    // Tính toán lại điểm trung bình cho sách
    const agg = await prisma.review.aggregate({
      where: { bookId: book.id },
      _avg: { rating: true },
      _count: { rating: true }
    });

    await prisma.book.update({
      where: { id: book.id },
      data: {
        ratingAvg: agg._avg.rating || 0,
        ratingCount: agg._count.rating || 0
      }
    });

    res.status(201).json({ success: true, data: review });
  } catch (error) {
    console.error('Add review error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// ==========================================
// 6. ADMIN OPERATIONS (Create, Update, Delete)
// ==========================================
exports.createBook = async (req, res) => {
  try {
    const bookData = req.body;
    const genreIds = bookData.genreIds || [];
    
    // Xử lý authors (đảm bảo là mảng)
    let authors = bookData.authors || bookData.author || [];
    if (!Array.isArray(authors)) authors = [authors];

    const newBook = await prisma.book.create({
      data: {
        isbn: bookData.isbn,
        title: bookData.title,
        description: bookData.description,
        authors: authors,
        publisher: bookData.publisher,
        coverUrl: bookData.coverUrl,
        publishedYear: parseInt(bookData.publishedYear) || 2024,
        pageCount: parseInt(bookData.pageCount) || 0,
        language: bookData.language || 'vi',
        genres: {
          create: genreIds.map(gid => ({ genre: { connect: { id: gid } } }))
        }
      },
      include: { genres: { include: { genre: true } } }
    });

    res.status(201).json({ success: true, data: newBook });
  } catch (error) {
    console.error('Create book error:', error);
    res.status(500).json({ success: false, message: 'Lỗi tạo sách (Trùng ISBN hoặc lỗi server)' });
  }
};

exports.updateBook = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    // Xử lý genre update phức tạp hơn (xóa cũ thêm mới), tạm thời chỉ update thông tin cơ bản
    const updatedBook = await prisma.book.update({
      where: { id },
      data: {
        title: updates.title,
        description: updates.description,
        coverUrl: updates.coverUrl
      }
    });
    res.json({ success: true, data: updatedBook });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

exports.deleteBook = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.book.delete({ where: { id } });
    res.json({ success: true, message: 'Đã xóa sách' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};