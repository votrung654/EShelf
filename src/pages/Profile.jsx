import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mail, Calendar, BookOpen, Clock, Heart, Settings } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { favoritesAPI, historyAPI, profileAPI, collectionsAPI, mlAPI } from '../services/api';

export default function Profile() {
  const navigate = useNavigate();
  const { user, isAuthenticated, updateUser, logout } = useAuth();
  
  const [stats, setStats] = useState({
    totalBooks: 0,
    favorites: 0,
    collections: 0,
    readingTime: 0,
  });
  
  const [isEditing, setIsEditing] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [editForm, setEditForm] = useState({
    name: '',
    bio: '',
  });

  // Load Data Thật từ Server
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }

    const loadRealStats = async () => {
        setIsLoading(true);
        try {
            const [favRes, histRes, collRes] = await Promise.all([
                favoritesAPI.getAll(),
                historyAPI.getAll(),
                collectionsAPI.getAll()
            ]);

            const favoritesCount = favRes.success ? (favRes.data?.length || 0) : 0;
            const historyList = histRes.success ? (histRes.data || []) : [];
            const collectionsList = collRes.success ? (collRes.data || []) : [];
            const totalBooksRead = historyList.length;
            const collectionsCount = collectionsList.length;

            let estimatedMinutes = totalBooksRead * 30;
            
            if (historyList.length > 0) {
              try {
                const totalPages = historyList.reduce((sum, item) => {
                  return sum + (item.progress?.totalPages || item.book?.pageCount || 200);
                }, 0);
                const avgGenre = historyList[0]?.book?.genres?.[0] || 'Fiction';
                const timeRes = await mlAPI.estimateReadingTime(totalPages, avgGenre);
                if (timeRes.success && timeRes.data?.minutes) {
                  estimatedMinutes = timeRes.data.minutes;
                }
              } catch (error) {
                console.error('Error estimating reading time:', error);
              }
            }

            setStats({
                totalBooks: totalBooksRead,
                favorites: favoritesCount,
                collections: collectionsCount,
                readingTime: estimatedMinutes,
            });

        } catch (error) {
            console.error("Lỗi tải thống kê:", error);
        } finally {
            setIsLoading(false);
        }
    };

    loadRealStats();

    setEditForm({
      name: user?.name || user?.username || '',
      bio: user?.bio || '',
    });
  }, [isAuthenticated, user, navigate]);

  const handleSaveProfile = async () => {
    if (!editForm.name.trim()) return;

    try {
        // Gọi API update profile
        const res = await profileAPI.update({
            name: editForm.name.trim(),
            bio: editForm.bio.trim()
        });

        if (res.success) {
            // Cập nhật Context
            updateUser(res.data);
            setIsEditing(false);
        } else {
            alert(res.message || "Cập nhật thất bại");
        }
    } catch (error) {
        alert("Lỗi kết nối server");
    }
  };

  if (!isAuthenticated) return null;

  return (
    <main className="flex-1 max-w-4xl mx-auto w-full px-4 py-8">
      {/* Profile Header */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-8 mb-8 text-white relative overflow-hidden shadow-lg">
        <div className="absolute inset-0 bg-black/10" />
        <div className="relative flex flex-col md:flex-row items-center gap-6">
          {/* Avatar */}
          <div className="relative">
            <div className="w-28 h-28 rounded-full bg-white/20 flex items-center justify-center text-4xl font-bold border-4 border-white/30 backdrop-blur-sm">
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
              <div className="space-y-3 animate-fade-in">
                <input
                  type="text"
                  value={editForm.name}
                  onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                  className="px-4 py-2 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70 w-full max-w-xs focus:outline-none focus:bg-white/30 transition-all"
                  placeholder="Tên hiển thị"
                />
                <textarea
                  value={editForm.bio}
                  onChange={(e) => setEditForm({ ...editForm, bio: e.target.value })}
                  className="px-4 py-2 rounded-lg bg-white/20 border border-white/30 text-white placeholder-white/70 w-full max-w-md resize-none focus:outline-none focus:bg-white/30 transition-all"
                  placeholder="Giới thiệu bản thân..."
                  rows={2}
                />
                <div className="flex gap-2 justify-center md:justify-start">
                  <button onClick={handleSaveProfile} className="px-4 py-2 bg-white text-blue-600 rounded-lg font-bold hover:bg-gray-100 transition-colors">
                    Lưu
                  </button>
                  <button onClick={() => setIsEditing(false)} className="px-4 py-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors">
                    Hủy
                  </button>
                </div>
              </div>
            ) : (
              <>
                <h1 className="text-3xl font-bold mb-1">{user?.name || user?.username}</h1>
                <p className="text-white/80 flex items-center justify-center md:justify-start gap-2 mb-2">
                  <Mail className="w-4 h-4" />
                  {user?.email}
                </p>
                <p className="text-white/70 text-sm mb-3 max-w-lg">{user?.bio || "Chưa có giới thiệu"}</p>
                
                <div className="flex items-center justify-center md:justify-start gap-4">
                     <p className="text-white/60 text-xs flex items-center gap-1">
                        <Calendar className="w-3 h-3" />
                        Tham gia: {user?.createdAt ? new Date(user.createdAt).toLocaleDateString('vi-VN') : 'N/A'}
                    </p>
                </div>
              </>
            )}
          </div>

          {/* Actions */}
          <div className="flex flex-col gap-2">
            {!isEditing && (
                <button
                onClick={() => setIsEditing(true)}
                className="p-2 bg-white/20 rounded-lg hover:bg-white/30 transition-colors"
                title="Chỉnh sửa hồ sơ"
                >
                <Settings className="w-5 h-5" />
                </button>
            )}
            <button
                onClick={logout}
                className="px-4 py-2 bg-red-500/80 hover:bg-red-500 text-white text-sm font-medium rounded-lg transition-colors"
            >
                Đăng xuất
            </button>
          </div>
        </div>
      </div>

      {/* Stats Cards - Real data */}
      {isLoading ? (
          <div className="text-center py-10">Đang tải thống kê...</div>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <StatsCard icon={<BookOpen className="text-blue-600" />} value={stats.totalBooks} label="Sách đã đọc" bg="bg-blue-100 dark:bg-blue-900/30" />
            <StatsCard icon={<Heart className="text-red-500" />} value={stats.favorites} label="Yêu thích" bg="bg-red-100 dark:bg-red-900/30" />
            <StatsCard icon={<Settings className="text-purple-600" />} value={stats.collections} label="Bộ sưu tập" bg="bg-purple-100 dark:bg-purple-900/30" />
            <StatsCard icon={<Clock className="text-green-600" />} value={stats.readingTime} label="Phút đọc" bg="bg-green-100 dark:bg-green-900/30" />
        </div>
      )}

    </main>
  );
}

// Component con để hiển thị thẻ thống kê cho gọn
const StatsCard = ({ icon, value, label, bg }) => (
    <div className="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm hover:shadow-md transition-shadow text-center border border-gray-100 dark:border-gray-700">
        <div className={`w-12 h-12 ${bg} rounded-full flex items-center justify-center mx-auto mb-3`}>
            {React.cloneElement(icon, { className: "w-6 h-6" })}
        </div>
        <p className="text-2xl font-bold text-gray-800 dark:text-white">{value}</p>
        <p className="text-sm text-gray-500 dark:text-gray-400">{label}</p>
    </div>
);
import React from 'react';