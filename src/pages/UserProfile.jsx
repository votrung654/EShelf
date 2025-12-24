import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { favoritesAPI, historyAPI, booksAPI, profileAPI } from '../services/api';
import ProfileSidebar from '../components/user/ProfileSidebar';
import ProfileStats from '../components/user/ProfileStats';
import { formatTimeAgo } from '../components/book/ReadingProgress';

export default function UserProfile() {
  const navigate = useNavigate();
  const { user, isAuthenticated } = useAuth();
  const [activeTab, setActiveTab] = useState('info');
  const [favoriteBooks, setFavoriteBooks] = useState([]);
  const [readingHistory, setReadingHistory] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }

    const loadData = async () => {
      setIsLoading(true);
      try {
        const [favRes, histRes] = await Promise.all([
          favoritesAPI.getAll(),
          historyAPI.getAll()
        ]);

        if (favRes.success && favRes.data) {
          const bookIds = favRes.data;
          const books = await Promise.all(
            bookIds.map(async (bookId) => {
              try {
                const bookRes = await booksAPI.getById(bookId);
                if (bookRes.success && bookRes.data) {
                  return bookRes.data;
                }
                return null;
              } catch (error) {
                return null;
              }
            })
          );
          setFavoriteBooks(books.filter(Boolean));
        }

        if (histRes.success && histRes.data) {
          const historyWithBooks = await Promise.all(
            histRes.data.map(async (historyItem) => {
              try {
                const bookId = historyItem.bookId;
                const bookRes = await booksAPI.getById(bookId);
                if (bookRes.success && bookRes.data) {
                  return {
                    id: bookRes.data.id || bookRes.data.isbn, // Dùng id từ book response
                    bookId: historyItem.bookId, // Giữ lại bookId từ history
                    isbn: bookRes.data.isbn,
                    title: bookRes.data.title,
                    author: Array.isArray(bookRes.data.authors) ? bookRes.data.authors.join(', ') : (bookRes.data.author || 'Unknown'),
                    progress: historyItem.progressPercent || 0,
                    lastRead: formatTimeAgo(historyItem.lastReadAt),
                    cover: bookRes.data.coverUrl || bookRes.data.cover
                  };
                }
                return null;
              } catch (error) {
                console.error('Error fetching book for history:', error);
                return null;
              }
            })
          );
          setReadingHistory(historyWithBooks.filter(Boolean));
        }
      } catch (error) {
        console.error('Error loading profile data:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, [isAuthenticated, navigate]);

  if (!isAuthenticated || !user) {
    return null;
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'info':
        return <ProfileInfo user={user} />;
      case 'favorites':
        return <FavoritesSection books={favoriteBooks} isLoading={isLoading} />;
      case 'history':
        return <ReadingHistorySection history={readingHistory} isLoading={isLoading} />;
      case 'settings':
        return <SettingsSection user={user} />;
      default:
        return <ProfileInfo user={user} />;
    }
  };

  return (
    <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
      {/* Breadcrumb */}
      <nav className="mb-6">
        <ol className="flex items-center space-x-2 text-sm">
          <li>
            <Link to="/" className="text-blue-600 hover:underline">Trang chủ</Link>
          </li>
          <li className="text-gray-400">/</li>
          <li className="text-gray-600">Hồ sơ cá nhân</li>
        </ol>
      </nav>

      {/* Profile Header */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6 mb-6">
        <div className="flex flex-col md:flex-row items-center gap-6">
          {user.avatar ? (
            <img
              src={user.avatar}
              alt={user.name || user.username}
              className="w-24 h-24 rounded-full border-4 border-blue-500 shadow-lg object-cover"
            />
          ) : (
            <div className="w-24 h-24 rounded-full border-4 border-blue-500 shadow-lg bg-blue-100 dark:bg-blue-900 flex items-center justify-center text-3xl font-bold text-blue-600 dark:text-blue-300">
              {(user.name || user.username || 'U')[0].toUpperCase()}
            </div>
          )}
          <div className="text-center md:text-left flex-1">
            <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-100">{user.name || user.username}</h1>
            <p className="text-gray-500 dark:text-gray-400">@{user.username}</p>
            <p className="text-gray-600 dark:text-gray-300 mt-2 max-w-xl">{user.bio || 'Chưa có giới thiệu'}</p>
            <div className="flex flex-wrap justify-center md:justify-start gap-4 mt-3 text-sm text-gray-500 dark:text-gray-400">
              <span className="flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Tham gia: {user.createdAt ? new Date(user.createdAt).toLocaleDateString('vi-VN') : 'N/A'}
              </span>
            </div>
          </div>
          <button 
            onClick={() => {
              // TODO: Implement edit profile modal/page
              alert('Tính năng chỉnh sửa hồ sơ đang được phát triển');
            }}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Chỉnh sửa hồ sơ
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="mb-6">
        <ProfileStats />
      </div>

      {/* Main Content */}
      <div className="flex flex-col md:flex-row gap-6">
        <ProfileSidebar activeTab={activeTab} onTabChange={setActiveTab} />
        <div className="flex-1 bg-white rounded-xl shadow-md p-6">
          {renderContent()}
        </div>
      </div>
    </main>
  );
}

// Profile Info Section
function ProfileInfo({ user }) {
  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100 mb-6">Thông tin cá nhân</h2>
      <div className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Họ và tên</label>
            <p className="text-gray-800 dark:text-gray-100 font-medium">{user.name || user.username}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Tên người dùng</label>
            <p className="text-gray-800 dark:text-gray-100 font-medium">@{user.username}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Email</label>
            <p className="text-gray-800 dark:text-gray-100 font-medium">{user.email}</p>
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-1">Giới thiệu</label>
          <p className="text-gray-800 dark:text-gray-100">{user.bio || 'Chưa có giới thiệu'}</p>
        </div>
      </div>
    </div>
  );
}

// Favorites Section
function FavoritesSection({ books, isLoading }) {
  if (isLoading) {
    return (
      <div>
        <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100 mb-6">Sách yêu thích</h2>
        <div className="text-center py-8">Đang tải...</div>
      </div>
    );
  }

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100 mb-6">Sách yêu thích</h2>
      {books.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {books.map((book) => (
            <Link
              key={book.id}
              to={`/book/${book.id || book.isbn}`}
              className="flex gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <img
                src={book.coverUrl || book.cover || '/images/book-placeholder.svg'}
                alt={book.title}
                className="w-16 h-20 object-cover rounded shadow"
                onError={(e) => {
                  e.target.src = '/images/book-placeholder.svg';
                }}
              />
              <div className="flex-1 min-w-0">
                <h3 className="font-medium text-gray-800 dark:text-gray-100 truncate">{book.title}</h3>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  {Array.isArray(book.authors) ? book.authors.join(', ') : (book.author || 'Unknown')}
                </p>
                <button 
                  onClick={async (e) => {
                    e.preventDefault();
                    if (!window.confirm('Bỏ yêu thích sách này?')) return;
                    
                    try {
                      const { favoritesAPI } = await import('../services/api');
                      await favoritesAPI.remove(book.id || book.isbn);
                      // Reload page để cập nhật danh sách
                      window.location.reload();
                    } catch (error) {
                      console.error('Error removing favorite:', error);
                      alert('Không thể bỏ yêu thích');
                    }
                  }}
                  className="mt-2 text-red-500 hover:text-red-600 text-sm flex items-center gap-1"
                >
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                  </svg>
                  Bỏ yêu thích
                </button>
              </div>
            </Link>
          ))}
        </div>
      ) : (
        <p className="text-gray-500 dark:text-gray-400 text-center py-8">Chưa có sách yêu thích nào.</p>
      )}
    </div>
  );
}

// Reading History Section
function ReadingHistorySection({ history, isLoading }) {
  if (isLoading) {
    return (
      <div>
        <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100 mb-6">Lịch sử đọc</h2>
        <div className="text-center py-8">Đang tải...</div>
      </div>
    );
  }

  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100 mb-6">Lịch sử đọc</h2>
      {history.length > 0 ? (
        <div className="space-y-4">
          {history.map((item, index) => {
            const uniqueKey = item.id || `history-${index}`;
            return (
              <Link
                key={uniqueKey}
                to={`/book/${item.id || item.isbn || item.bookId}`}
                className="flex items-center gap-4 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors"
              >
                {item.cover && (
                  <img
                    src={item.cover}
                    alt={item.title}
                    className="w-16 h-20 object-cover rounded shadow"
                    onError={(e) => {
                      e.target.src = '/images/book-placeholder.svg';
                    }}
                  />
                )}
                <div className="flex-1">
                  <h3 className="font-medium text-gray-800 dark:text-gray-100">{item.title}</h3>
                  <p className="text-sm text-gray-500 dark:text-gray-400">{item.author}</p>
                  <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">Đọc lần cuối: {item.lastRead}</p>
                </div>
                <div className="text-right">
                  <div className="w-32 bg-gray-200 dark:bg-gray-600 rounded-full h-2 mb-1">
                    <div
                      className={`h-2 rounded-full ${item.progress === 100 ? 'bg-green-500' : 'bg-blue-500'}`}
                      style={{ width: `${item.progress}%` }}
                    />
                  </div>
                  <span className="text-sm text-gray-600 dark:text-gray-300">{item.progress}%</span>
                </div>
                <Link
                  to={`/reading/${item.id || item.isbn || item.bookId}`}
                  className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition-colors"
                >
                  {item.progress === 100 ? 'Đọc lại' : 'Tiếp tục'}
                </Link>
              </Link>
            );
          })}
        </div>
      ) : (
        <p className="text-gray-500 dark:text-gray-400 text-center py-8">Chưa có lịch sử đọc sách.</p>
      )}
    </div>
  );
}

// Settings Section
function SettingsSection({ user }) {
  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-6">Cài đặt tài khoản</h2>
      <div className="space-y-6">
        <div className="p-4 border border-gray-200 rounded-lg">
          <h3 className="font-medium text-gray-800 mb-2">Đổi mật khẩu</h3>
          <p className="text-sm text-gray-500 mb-3">Cập nhật mật khẩu để bảo vệ tài khoản của bạn.</p>
          <button 
            onClick={() => {
              // TODO: Implement change password modal
              alert('Tính năng đổi mật khẩu đang được phát triển');
            }}
            className="px-4 py-2 border border-blue-600 text-blue-600 rounded-lg hover:bg-blue-50 transition-colors"
          >
            Đổi mật khẩu
          </button>
        </div>
        <div className="p-4 border border-gray-200 rounded-lg">
          <h3 className="font-medium text-gray-800 mb-2">Thông báo</h3>
          <div className="space-y-3">
            <label className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Thông báo email sách mới</span>
              <input type="checkbox" defaultChecked className="w-5 h-5 text-blue-600 rounded" />
            </label>
            <label className="flex items-center justify-between">
              <span className="text-sm text-gray-600">Nhắc nhở đọc sách hàng ngày</span>
              <input type="checkbox" className="w-5 h-5 text-blue-600 rounded" />
            </label>
          </div>
        </div>
        <div className="p-4 border border-red-200 bg-red-50 rounded-lg">
          <h3 className="font-medium text-red-800 mb-2">Xóa tài khoản</h3>
          <p className="text-sm text-red-600 mb-3">Hành động này không thể hoàn tác. Tất cả dữ liệu sẽ bị xóa vĩnh viễn.</p>
          <button 
            onClick={() => {
              if (window.confirm('Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác!')) {
                // TODO: Implement delete account API call
                alert('Tính năng xóa tài khoản đang được phát triển');
              }
            }}
            className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
          >
            Xóa tài khoản
          </button>
        </div>
      </div>
    </div>
  );
}
