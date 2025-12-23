const { v4: uuidv4 } = require('uuid');

// In-memory storage
const collections = new Map(); // collectionId -> collection
const userCollections = new Map(); // userId -> Set of collectionIds

// Get user collections
exports.getCollections = async (req, res) => {
  try {
    const userId = req.user.userId;
    const collectionIds = userCollections.get(userId) || new Set();
    
    const userColls = Array.from(collectionIds)
      .map(id => collections.get(id))
      .filter(Boolean)
      .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

    res.json({
      success: true,
      data: userColls
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

    const collection = {
      id: uuidv4(),
      userId,
      name: name.trim(),
      description: description ? description.trim() : '',
      isPublic: Boolean(isPublic),
      books: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    collections.set(collection.id, collection);

    let userColls = userCollections.get(userId);
    if (!userColls) {
      userColls = new Set();
      userCollections.set(userId, userColls);
    }
    userColls.add(collection.id);

    res.status(201).json({
      success: true,
      message: 'Tạo bộ sưu tập thành công',
      data: collection
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

    const collection = collections.get(id);

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
      data: collection
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

    const collection = collections.get(id);

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

    collection.name = name || collection.name;
    collection.description = description !== undefined ? description : collection.description;
    collection.isPublic = isPublic !== undefined ? isPublic : collection.isPublic;
    collection.updatedAt = new Date().toISOString();

    res.json({
      success: true,
      message: 'Cập nhật bộ sưu tập thành công',
      data: collection
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

    const collection = collections.get(id);

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

    collections.delete(id);
    const userColls = userCollections.get(userId);
    if (userColls) {
      userColls.delete(id);
    }

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

    const collection = collections.get(id);

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

    if (!collection.books.includes(bookId)) {
      collection.books.push(bookId);
      collection.updatedAt = new Date().toISOString();
    }

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

    const collection = collections.get(id);

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

    collection.books = collection.books.filter(b => b !== bookId);
    collection.updatedAt = new Date().toISOString();

    res.json({
      success: true,
      message: 'Đã xóa sách khỏi bộ sưu tập'
    });
  } catch (error) {
    console.error('Remove book from collection error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


