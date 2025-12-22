const { PrismaClient } = require('@prisma/client');
const { v4: uuidv4 } = require('uuid');

const prisma = new PrismaClient();

// Get all books with pagination
exports.getAllBooks = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const sortBy = req.query.sortBy || 'title';
    const order = req.query.order || 'asc';

    const skip = (page - 1) * limit;

    // Build orderBy object
    const orderBy = {};
    orderBy[sortBy] = order;

    const [books, total] = await Promise.all([
      prisma.book.findMany({
        skip,
        take: limit,
        orderBy,
        include: {
          genres: {
            include: {
              genre: true
            }
          }
        }
      }),
      prisma.book.count()
    ]);

    res.json({
      success: true,
      data: books.map(book => ({
        ...book,
        genres: book.genres.map(bg => bg.genre.name)
      })),
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get all books error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Search books
exports.searchBooks = async (req, res) => {
  try {
    const { q, genre, year, language, page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    // Build where clause
    const where = {};

    // Text search across multiple fields
    if (q) {
      where.OR = [
        { title: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { authors: { has: q } },
        { isbn: { contains: q } }
      ];
    }

    // Filter by genre
    if (genre) {
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

    // Filter by year
    if (year) {
      where.publishedYear = parseInt(year);
    }

    // Filter by language
    if (language) {
      where.language = { equals: language, mode: 'insensitive' };
    }

    const [results, total] = await Promise.all([
      prisma.book.findMany({
        where,
        skip,
        take: parseInt(limit),
        include: {
          genres: {
            include: {
              genre: true
            }
          }
        }
      }),
      prisma.book.count({ where })
    ]);

    res.json({
      success: true,
      data: results.map(book => ({
        ...book,
        genres: book.genres.map(bg => bg.genre.name)
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Search books error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get featured books (highest rated)
exports.getFeaturedBooks = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    
    const featured = await prisma.book.findMany({
      take: limit,
      orderBy: [
        { ratingAvg: 'desc' },
        { ratingCount: 'desc' }
      ],
      include: {
        genres: {
          include: {
            genre: true
          }
        }
      }
    });

    res.json({
      success: true,
      data: featured.map(book => ({
        ...book,
        genres: book.genres.map(bg => bg.genre.name)
      }))
    });
  } catch (error) {
    console.error('Get featured books error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get popular books (most viewed)
exports.getPopularBooks = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    
    const popular = await prisma.book.findMany({
      take: limit,
      orderBy: { viewCount: 'desc' },
      include: {
        genres: {
          include: {
            genre: true
          }
        }
      }
    });

    res.json({
      success: true,
      data: popular.map(book => ({
        ...book,
        genres: book.genres.map(bg => bg.genre.name)
      }))
    });
  } catch (error) {
    console.error('Get popular books error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get book by ID
exports.getBookById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const book = await prisma.book.findFirst({
      where: {
        OR: [
          { id },
          { isbn: id }
        ]
      },
      include: {
        genres: {
          include: {
            genre: true
          }
        },
        reviews: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                name: true,
                avatarUrl: true
              }
            }
          },
          orderBy: { createdAt: 'desc' }
        }
      }
    });

    if (!book) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy sách'
      });
    }

    // Increment view count
    await prisma.book.update({
      where: { id: book.id },
      data: { viewCount: { increment: 1 } }
    });

    res.json({
      success: true,
      data: {
        ...book,
        genres: book.genres.map(bg => bg.genre.name),
        viewCount: book.viewCount + 1
      }
    });
  } catch (error) {
    console.error('Get book by ID error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get book reviews
exports.getBookReviews = async (req, res) => {
  try {
    const { id } = req.params;
    
    const reviews = await prisma.review.findMany({
      where: { bookId: id },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            name: true,
            avatarUrl: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: reviews
    });
  } catch (error) {
    console.error('Get book reviews error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Add review
exports.addReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, content } = req.body;
    const userId = req.user.userId;

    // Check if book exists
    const book = await prisma.book.findFirst({
      where: {
        OR: [
          { id },
          { isbn: id }
        ]
      }
    });

    if (!book) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy sách'
      });
    }

    // Create or update review
    const review = await prisma.review.upsert({
      where: {
        userId_bookId: {
          userId,
          bookId: book.id
        }
      },
      update: {
        rating,
        content,
        updatedAt: new Date()
      },
      create: {
        userId,
        bookId: book.id,
        rating,
        content
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            name: true,
            avatarUrl: true
          }
        }
      }
    });

    // Recalculate book rating
    const reviewStats = await prisma.review.aggregate({
      where: { bookId: book.id },
      _avg: { rating: true },
      _count: { rating: true }
    });

    await prisma.book.update({
      where: { id: book.id },
      data: {
        ratingAvg: reviewStats._avg.rating || 0,
        ratingCount: reviewStats._count.rating || 0
      }
    });

    res.status(201).json({
      success: true,
      data: review
    });
  } catch (error) {
    console.error('Add review error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Create book (Admin)
exports.createBook = async (req, res) => {
  try {
    const bookData = req.body;

    // Extract genre IDs if provided
    const genreIds = bookData.genreIds || [];
    delete bookData.genreIds;

    // Ensure authors is an array
    if (bookData.author && !Array.isArray(bookData.author)) {
      bookData.authors = [bookData.author];
      delete bookData.author;
    } else if (bookData.author) {
      bookData.authors = bookData.author;
      delete bookData.author;
    }

    // Create book with genres
    const newBook = await prisma.book.create({
      data: {
        isbn: bookData.isbn || `ISBN-${Date.now()}`,
        title: bookData.title,
        description: bookData.description,
        authors: bookData.authors || [],
        translators: bookData.translators || [],
        publisher: bookData.publisher,
        coverUrl: bookData.coverUrl,
        pdfUrl: bookData.pdfUrl,
        pageCount: bookData.pageCount,
        language: bookData.language || 'vi',
        publishedYear: bookData.publishedYear,
        extension: bookData.extension,
        fileSize: bookData.fileSize,
        genres: {
          create: genreIds.map(genreId => ({
            genre: { connect: { id: genreId } }
          }))
        }
      },
      include: {
        genres: {
          include: {
            genre: true
          }
        }
      }
    });

    res.status(201).json({
      success: true,
      message: 'Tạo sách thành công',
      data: {
        ...newBook,
        genres: newBook.genres.map(bg => bg.genre.name)
      }
    });
  } catch (error) {
    console.error('Create book error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update book (Admin)
exports.updateBook = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    // Extract genre IDs if provided
    const genreIds = updates.genreIds;
    delete updates.genreIds;

    // Ensure authors is an array
    if (updates.author && !Array.isArray(updates.author)) {
      updates.authors = [updates.author];
      delete updates.author;
    } else if (updates.author) {
      updates.authors = updates.author;
      delete updates.author;
    }

    // Check if book exists
    const existingBook = await prisma.book.findFirst({
      where: {
        OR: [
          { id },
          { isbn: id }
        ]
      }
    });

    if (!existingBook) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy sách'
      });
    }

    // Update book
    const updateData = { ...updates };
    
    // Handle genres update if provided
    if (genreIds) {
      await prisma.bookGenre.deleteMany({
        where: { bookId: existingBook.id }
      });
      updateData.genres = {
        create: genreIds.map(genreId => ({
          genre: { connect: { id: genreId } }
        }))
      };
    }

    const updatedBook = await prisma.book.update({
      where: { id: existingBook.id },
      data: updateData,
      include: {
        genres: {
          include: {
            genre: true
          }
        }
      }
    });

    res.json({
      success: true,
      message: 'Cập nhật sách thành công',
      data: {
        ...updatedBook,
        genres: updatedBook.genres.map(bg => bg.genre.name)
      }
    });
  } catch (error) {
    console.error('Update book error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Delete book (Admin)
exports.deleteBook = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if book exists
    const book = await prisma.book.findFirst({
      where: {
        OR: [
          { id },
          { isbn: id }
        ]
      }
    });

    if (!book) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy sách'
      });
    }

    // Delete book (cascades will handle related records)
    await prisma.book.delete({
      where: { id: book.id }
    });

    res.json({
      success: true,
      message: 'Xóa sách thành công'
    });
  } catch (error) {
    console.error('Delete book error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Graceful shutdown
process.on('SIGINT', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});


