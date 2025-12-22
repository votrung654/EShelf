// In-memory storage (replace with database)
const users = new Map();

// Get profile
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    let user = users.get(userId);

    if (!user) {
      // Create default profile
      user = {
        id: userId,
        name: req.user.email?.split('@')[0] || 'User',
        email: req.user.email,
        avatar: null,
        bio: '',
        createdAt: new Date().toISOString()
      };
      users.set(userId, user);
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update profile
exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, bio } = req.body;

    let user = users.get(userId) || {
      id: userId,
      email: req.user.email,
      createdAt: new Date().toISOString()
    };

    user = {
      ...user,
      name: name || user.name,
      bio: bio !== undefined ? bio : user.bio,
      updatedAt: new Date().toISOString()
    };

    users.set(userId, user);

    res.json({
      success: true,
      message: 'Cập nhật profile thành công',
      data: user
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Update avatar
exports.updateAvatar = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { avatar } = req.body;

    let user = users.get(userId) || {
      id: userId,
      email: req.user.email,
      createdAt: new Date().toISOString()
    };

    user = {
      ...user,
      avatar,
      updatedAt: new Date().toISOString()
    };

    users.set(userId, user);

    res.json({
      success: true,
      message: 'Cập nhật avatar thành công',
      data: user
    });
  } catch (error) {
    console.error('Update avatar error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

// Get user stats
exports.getStats = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Mock stats - replace with actual data from database
    const stats = {
      booksRead: 12,
      pagesRead: 1500,
      readingTime: 45, // hours
      collectionsCount: 3,
      favoritesCount: 8
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};


