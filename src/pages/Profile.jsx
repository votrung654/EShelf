import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { User, Mail, Calendar, BookOpen, Clock, Heart, Settings, Camera } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const COLLECTIONS_BASE_KEY = 'eshelf_collections';
const PROGRESS_BASE_KEY = 'eshelf_reading_progress';

export default function Profile() {
  const navigate = useNavigate();
  const { user, isAuthenticated, updateUser } = useAuth();
  const [stats, setStats] = useState({
    totalBooks: 0,
    favorites: 0,
    collections: 0,
    readingTime: 0,
  });
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState({
    name: '',
    bio: '',
  });

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }

    loadUserStats();
    setEditForm({
      name: user?.name || user?.username || '',
      bio: user?.bio || '',
    });
  }, [isAuthenticated, user?.id, navigate]);

  const loadUserStats = () => {
    if (!user?.id) return;

    // Get user's collections
    const collectionsKey = `${COLLECTIONS_BASE_KEY}_${user.id}`;
    const collectionsData = localStorage.getItem(collectionsKey);
    const collections = collectionsData ? JSON.parse(collectionsData) : [];
    
    // Get user's reading progress
    const progressKey = `${PROGRESS_BASE_KEY}_${user.id}`;
    const progressData = localStorage.getItem(progressKey);
    const progress = progressData ? JSON.parse(progressData) : {};
    
    // Calculate real stats
    const favoritesCollection = collections.find(c => c.id === 'favorites');
    const favoritesCount = favoritesCollection?.books?.length || 0;
    const totalBooksRead = Object.keys(progress).length;
    
    // Calculate total reading sessions (each entry = 1 session ≈ estimated time)
    const readingSessions = Object.values(progress).length;
    const estimatedMinutes = readingSessions * 15; // 15 mins per session estimate
    
    setStats({
      totalBooks: totalBooksRead,
      favorites: favoritesCount,
      collections: collections.length,
      readingTime: estimatedMinutes,
    });
  };

  const handleSaveProfile = () => {
    if (!editForm.name.trim()) {
      return;
    }
    updateUser({
      name: editForm.name.trim(),
      bio: editForm.bio.trim(),
    });
    setIsEditing(false);
  };

  if (!isAuthenticated) return null;

  return (
    <main className="flex-1 max-w-4xl mx-auto w-full px-4 py-8">
      {/* Profile Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-8 mb-8 text-white relative overflow-hidden">
        <div className="absolute inset-0 bg-black/10" />
        <div className="relative flex flex-col md:flex-row items-center gap-6">
          {/* Avatar */}
          <div className="relative">
            <div className="w-28 h-28 rounded-full bg-white/20 flex items-center justify-center text-4xl font-bold border-4 border-white/30">
              {user?.avatar ? (
                <img src={user.avatar} alt="" className="w-full h-full rounded-full object-cover" />
              ) : (
                user?.name?.[0]?.toUpperCase() || user?.username?.[0]?.toUpperCase() || 'U'
              )}
            </div>
          </div>

          {/* Info */}
          <div className="text-center md:text-left flex-1">
            {isEditing ? (
              <div className="space-y-3">
                <input
                  type="text"
                  value={editForm.name}
                  onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                  className="px-4 py-2 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70 w-full max-w-xs"
                  placeholder="Tên hiển thị"
                />
                <textarea
                  value={editForm.bio}
                  onChange={(e) => setEditForm({ ...editForm, bio: e.target.value })}
                  className="px-4 py-2 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70 w-full max-w-md resize-none"
                  placeholder="Giới thiệu bản thân (tùy chọn)..."
                  rows={2}
                />
                <div className="flex gap-2">
                  <button onClick={handleSaveProfile} className="px-4 py-2 bg-white text-blue-600 rounded-lg font-medium">
                    Lưu
                  </button>
                  <button onClick={() => setIsEditing(false)} className="px-4 py-2 bg-white/20 rounded-lg">
                    Hủy
                  </button>
                </div>
              </div>
            ) : (
              <>
                <h1 className="text-2xl font-bold mb-1">{user?.name || user?.username || 'Chưa đặt tên'}</h1>
                <p className="text-white/80 flex items-center justify-center md:justify-start gap-2 mb-2">
                  <Mail className="w-4 h-4" />
                  {user?.email}
                </p>
                {user?.bio ? (
                  <p className="text-white/70 text-sm">{user.bio}</p>
                ) : (
                  <p className="text-white/50 text-sm italic">Chưa có giới thiệu</p>
                )}
                <p className="text-white/60 text-xs mt-2 flex items-center justify-center md:justify-start gap-1">
                  <Calendar className="w-3 h-3" />
                  Tham gia từ {user?.createdAt ? new Date(user.createdAt).toLocaleDateString('vi-VN') : 'Không rõ'}
                </p>
              </>
            )}
          </div>

          {/* Edit button */}
          {!isEditing && (
            <button
              onClick={() => setIsEditing(true)}
              className="absolute top-4 right-4 p-2 bg-white/20 rounded-lg hover:bg-white/30"
              title="Chỉnh sửa hồ sơ"
            >
              <Settings className="w-5 h-5" />
            </button>
          )}
        </div>
      </div>

      {/* Stats Cards - Real data */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-md text-center">
          <div className="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center mx-auto mb-3">
            <BookOpen className="w-6 h-6 text-blue-600" />
          </div>
          <p className="text-2xl font-bold text-gray-800 dark:text-white">{stats.totalBooks}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Sách đã đọc</p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-md text-center">
          <div className="w-12 h-12 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center mx-auto mb-3">
            <Heart className="w-6 h-6 text-red-500" />
          </div>
          <p className="text-2xl font-bold text-gray-800 dark:text-white">{stats.favorites}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Yêu thích</p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-md text-center">
          <div className="w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-full flex items-center justify-center mx-auto mb-3">
            <svg className="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </div>
          <p className="text-2xl font-bold text-gray-800 dark:text-white">{stats.collections}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Bộ sưu tập</p>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-md text-center">
          <div className="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center mx-auto mb-3">
            <Clock className="w-6 h-6 text-green-600" />
          </div>
          <p className="text-2xl font-bold text-gray-800 dark:text-white">{stats.readingTime}</p>
          <p className="text-sm text-gray-500 dark:text-gray-400">Phút đọc</p>
        </div>
      </div>

      {/* Quick Links */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Link
          to="/collections"
          className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-md hover:shadow-lg transition-shadow flex items-center gap-4"
        >
          <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-500 rounded-xl flex items-center justify-center">
            <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </div>
          <div>
            <h3 className="font-semibold text-gray-800 dark:text-white">Bộ sưu tập của tôi</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {stats.collections > 0 ? `${stats.collections} bộ sưu tập` : 'Chưa có bộ sưu tập'}
            </p>
          </div>
        </Link>

        <Link
          to="/reading-history"
          className="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-md hover:shadow-lg transition-shadow flex items-center gap-4"
        >
          <div className="w-14 h-14 bg-gradient-to-br from-green-500 to-teal-500 rounded-xl flex items-center justify-center">
            <Clock className="w-7 h-7 text-white" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-800 dark:text-white">Lịch sử đọc</h3>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {stats.totalBooks > 0 ? `${stats.totalBooks} sách đã đọc` : 'Chưa đọc sách nào'}
            </p>
          </div>
        </Link>
      </div>
    </main>
  );
}
