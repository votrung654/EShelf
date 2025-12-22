// In-memory storage
const readingHistory = new Map(); // `${userId}-${bookId}` -> history entry

// Get reading history
exports.getReadingHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const history = [];
    for (const [key, value] of readingHistory.entries()) {
      if (key.startsWith(`${userId}-`)) {
        history.push(value);
      }
    }

    // Sort by last read
    history.sort((a, b) => new Date(b.lastReadAt) - new Date(a.lastReadAt));

    res.json({
      success: true,
      data: history
    });
  } catch (error) {
    console.error('Get reading history error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Save reading progress
exports.saveReadingProgress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId, currentPage, totalPages } = req.body;

    const key = `${userId}-${bookId}`;
    const existingEntry = readingHistory.get(key);

    const entry = {
      userId,
      bookId,
      currentPage,
      totalPages,
      progressPercent: Math.round((currentPage / totalPages) * 100),
      lastReadAt: new Date().toISOString(),
      startedAt: existingEntry?.startedAt || new Date().toISOString(),
      finishedAt: currentPage >= totalPages ? new Date().toISOString() : null
    };

    readingHistory.set(key, entry);

    res.json({
      success: true,
      message: 'Đã lưu tiến độ đọc',
      data: entry
    });
  } catch (error) {
    console.error('Save reading progress error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get book progress
exports.getBookProgress = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    const key = `${userId}-${bookId}`;
    const entry = readingHistory.get(key);

    res.json({
      success: true,
      data: entry || null
    });
  } catch (error) {
    console.error('Get book progress error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Delete book history
exports.deleteBookHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { bookId } = req.params;

    const key = `${userId}-${bookId}`;
    readingHistory.delete(key);

    res.json({
      success: true,
      message: 'Đã xóa lịch sử đọc'
    });
  } catch (error) {
    console.error('Delete book history error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


