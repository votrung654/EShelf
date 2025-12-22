const { v4: uuidv4 } = require('uuid');
const bookController = require('./bookController');

// Get all genres from books
const getGenresFromBooks = () => {
  const books = bookController.getBooks();
  const genreMap = new Map();

  books.forEach(book => {
    (book.genres || []).forEach(genre => {
      if (!genreMap.has(genre)) {
        genreMap.set(genre, {
          id: uuidv4(),
          name: genre,
          slug: genre.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, ''),
          bookCount: 1
        });
      } else {
        genreMap.get(genre).bookCount++;
      }
    });
  });

  return Array.from(genreMap.values()).sort((a, b) => a.name.localeCompare(b.name, 'vi'));
};

// Get all genres
exports.getAllGenres = async (req, res) => {
  try {
    const genres = getGenresFromBooks();

    res.json({
      success: true,
      data: genres
    });
  } catch (error) {
    console.error('Get all genres error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get genre by slug
exports.getGenreBySlug = async (req, res) => {
  try {
    const { slug } = req.params;
    const genres = getGenresFromBooks();
    const genre = genres.find(g => g.slug === slug);

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

// Get books by genre
exports.getBooksByGenre = async (req, res) => {
  try {
    const { slug } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;

    const genres = getGenresFromBooks();
    const genre = genres.find(g => g.slug === slug);

    if (!genre) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thể loại'
      });
    }

    const books = bookController.getBooks();
    const genreBooks = books.filter(book => 
      book.genres?.some(g => g.toLowerCase() === genre.name.toLowerCase())
    );

    const start = (page - 1) * limit;
    const paginatedBooks = genreBooks.slice(start, start + limit);

    res.json({
      success: true,
      data: {
        genre,
        books: paginatedBooks
      },
      pagination: {
        page,
        limit,
        total: genreBooks.length,
        totalPages: Math.ceil(genreBooks.length / limit)
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

    const genre = {
      id: uuidv4(),
      name,
      slug: name.toLowerCase().replace(/\s+/g, '-').replace(/[^\w-]/g, ''),
      description,
      bookCount: 0,
      createdAt: new Date().toISOString()
    };

    res.status(201).json({
      success: true,
      message: 'Tạo thể loại thành công',
      data: genre
    });
  } catch (error) {
    console.error('Create genre error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update genre (Admin)
exports.updateGenre = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;

    res.json({
      success: true,
      message: 'Cập nhật thể loại thành công',
      data: { id, name, description }
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

    res.json({
      success: true,
      message: 'Xóa thể loại thành công'
    });
  } catch (error) {
    console.error('Delete genre error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


