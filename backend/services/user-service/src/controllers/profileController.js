const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        name: true,
        avatarUrl: true,
        bio: true,
        role: true,
        createdAt: true,
        updatedAt: true
      }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        email: user.email,
        username: user.username,
        name: user.name || user.username,
        avatar: user.avatarUrl,
        bio: user.bio || '',
        role: user.role,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, bio } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: {
        name: name !== undefined ? name : undefined,
        bio: bio !== undefined ? bio : undefined
      },
      select: {
        id: true,
        email: true,
        username: true,
        name: true,
        avatarUrl: true,
        bio: true,
        updatedAt: true
      }
    });

    res.json({
      success: true,
      message: 'Cập nhật profile thành công',
      data: {
        id: updatedUser.id,
        email: updatedUser.email,
        username: updatedUser.username,
        name: updatedUser.name || updatedUser.username,
        avatar: updatedUser.avatarUrl,
        bio: updatedUser.bio || '',
        updatedAt: updatedUser.updatedAt
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

exports.updateAvatar = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { avatar } = req.body;

    if (!avatar) {
      return res.status(400).json({
        success: false,
        message: 'Thiếu URL avatar'
      });
    }

    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: avatar },
      select: {
        id: true,
        email: true,
        username: true,
        name: true,
        avatarUrl: true,
        bio: true,
        updatedAt: true
      }
    });

    res.json({
      success: true,
      message: 'Cập nhật avatar thành công',
      data: {
        id: updatedUser.id,
        email: updatedUser.email,
        username: updatedUser.username,
        name: updatedUser.name || updatedUser.username,
        avatar: updatedUser.avatarUrl,
        bio: updatedUser.bio || '',
        updatedAt: updatedUser.updatedAt
      }
    });
  } catch (error) {
    console.error('Update avatar error:', error);
    res.status(500).json({ success: false, message: 'Lỗi server' });
  }
};

exports.getStats = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [historyCount, historyPages, favoritesCount, collectionsCount] = await Promise.all([
      prisma.readingHistory.count({
        where: { userId }
      }),
      prisma.readingHistory.aggregate({
        where: { userId },
        _sum: {
          currentPage: true
        }
      }),
      prisma.favorite.count({
        where: { userId }
      }),
      prisma.collection.count({
        where: { userId }
      })
    ]);

    const pagesRead = historyPages._sum.currentPage || 0;
    const readingTime = Math.round(pagesRead / 20);

    const stats = {
      booksRead: historyCount,
      pagesRead: pagesRead,
      readingTime: readingTime,
      collectionsCount: collectionsCount,
      favoritesCount: favoritesCount
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
