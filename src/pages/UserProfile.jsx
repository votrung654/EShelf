import { useState } from 'react';
import { Link } from 'react-router-dom';
import ProfileSidebar from '../components/user/ProfileSidebar';
import ProfileStats from '../components/user/ProfileStats';

// Mock user data
const mockUser = {
  id: 1,
  username: 'levanvu',
  email: 'levanvu@example.com',
  fullName: 'Lê Văn Vũ',
  avatar: 'https://ui-avatars.com/api/?name=Le+Van+Vu&size=200&background=3b82f6&color=fff',
  bio: 'Đam mê đọc sách và khám phá tri thức mới. Yêu thích thể loại khoa học viễn tưởng và lịch sử.',
  joinDate: '2024-01-15',
  location: 'TP. Hồ Chí Minh, Việt Nam',
};

// Mock favorite books
const mockFavoriteBooks = [
  { id: 1, title: 'Đắc Nhân Tâm', author: 'Dale Carnegie', cover: '/images/book-covers/book1.jpg' },
  { id: 2, title: 'Nhà Giả Kim', author: 'Paulo Coelho', cover: '/images/book-covers/book2.jpg' },
  { id: 3, title: 'Sapiens: Lược Sử Loài Người', author: 'Yuval Noah Harari', cover: '/images/book-covers/book3.jpg' },
];

// Mock reading history
const mockReadingHistory = [
  { id: 1, title: 'Atomic Habits', author: 'James Clear', progress: 75, lastRead: '2 giờ trước' },
  { id: 2, title: 'Think and Grow Rich', author: 'Napoleon Hill', progress: 100, lastRead: '1 ngày trước' },
  { id: 3, title: 'The Alchemist', author: 'Paulo Coelho', progress: 45, lastRead: '3 ngày trước' },
];

export default function UserProfile() {
  const [activeTab, setActiveTab] = useState('info');

  const renderContent = () => {
    switch (activeTab) {
      case 'info':
        return <ProfileInfo user={mockUser} />;
      case 'favorites':
        return <FavoritesSection books={mockFavoriteBooks} />;
      case 'history':
        return <ReadingHistorySection history={mockReadingHistory} />;
      case 'settings':
        return <SettingsSection user={mockUser} />;
      default:
        return <ProfileInfo user={mockUser} />;
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
      <div className="bg-white rounded-xl shadow-md p-6 mb-6">
        <div className="flex flex-col md:flex-row items-center gap-6">
          <img
            src={mockUser.avatar}
            alt={mockUser.fullName}
            className="w-24 h-24 rounded-full border-4 border-blue-500 shadow-lg"
          />
          <div className="text-center md:text-left flex-1">
            <h1 className="text-2xl font-bold text-gray-800">{mockUser.fullName}</h1>
            <p className="text-gray-500">@{mockUser.username}</p>
            <p className="text-gray-600 mt-2 max-w-xl">{mockUser.bio}</p>
            <div className="flex flex-wrap justify-center md:justify-start gap-4 mt-3 text-sm text-gray-500">
              <span className="flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                {mockUser.location}
              </span>
              <span className="flex items-center gap-1">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                Tham gia: {new Date(mockUser.joinDate).toLocaleDateString('vi-VN')}
              </span>
            </div>
          </div>
          <button className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
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
      <h2 className="text-xl font-bold text-gray-800 mb-6">Thông tin cá nhân</h2>
      <div className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-500 mb-1">Họ và tên</label>
            <p className="text-gray-800 font-medium">{user.fullName}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500 mb-1">Tên người dùng</label>
            <p className="text-gray-800 font-medium">@{user.username}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500 mb-1">Email</label>
            <p className="text-gray-800 font-medium">{user.email}</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-500 mb-1">Địa điểm</label>
            <p className="text-gray-800 font-medium">{user.location}</p>
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-500 mb-1">Giới thiệu</label>
          <p className="text-gray-800">{user.bio}</p>
        </div>
      </div>
    </div>
  );
}

// Favorites Section
function FavoritesSection({ books }) {
  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-6">Sách yêu thích</h2>
      {books.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {books.map((book) => (
            <Link
              key={book.id}
              to={`/book/${book.id}`}
              className="flex gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
            >
              <img
                src={book.cover}
                alt={book.title}
                className="w-16 h-20 object-cover rounded shadow"
                onError={(e) => {
                  e.target.src = 'https://via.placeholder.com/64x80?text=Book';
                }}
              />
              <div className="flex-1 min-w-0">
                <h3 className="font-medium text-gray-800 truncate">{book.title}</h3>
                <p className="text-sm text-gray-500">{book.author}</p>
                <button className="mt-2 text-red-500 hover:text-red-600 text-sm flex items-center gap-1">
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
        <p className="text-gray-500 text-center py-8">Chưa có sách yêu thích nào.</p>
      )}
    </div>
  );
}

// Reading History Section
function ReadingHistorySection({ history }) {
  return (
    <div>
      <h2 className="text-xl font-bold text-gray-800 mb-6">Lịch sử đọc</h2>
      {history.length > 0 ? (
        <div className="space-y-4">
          {history.map((item) => (
            <div key={item.id} className="flex items-center gap-4 p-4 bg-gray-50 rounded-lg">
              <div className="flex-1">
                <h3 className="font-medium text-gray-800">{item.title}</h3>
                <p className="text-sm text-gray-500">{item.author}</p>
                <p className="text-xs text-gray-400 mt-1">Đọc lần cuối: {item.lastRead}</p>
              </div>
              <div className="text-right">
                <div className="w-32 bg-gray-200 rounded-full h-2 mb-1">
                  <div
                    className={`h-2 rounded-full ${item.progress === 100 ? 'bg-green-500' : 'bg-blue-500'}`}
                    style={{ width: `${item.progress}%` }}
                  />
                </div>
                <span className="text-sm text-gray-600">{item.progress}%</span>
              </div>
              <Link
                to={`/reading/${item.id}`}
                className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition-colors"
              >
                {item.progress === 100 ? 'Đọc lại' : 'Tiếp tục'}
              </Link>
            </div>
          ))}
        </div>
      ) : (
        <p className="text-gray-500 text-center py-8">Chưa có lịch sử đọc sách.</p>
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
          <button className="px-4 py-2 border border-blue-600 text-blue-600 rounded-lg hover:bg-blue-50 transition-colors">
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
          <button className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors">
            Xóa tài khoản
          </button>
        </div>
      </div>
    </div>
  );
}
