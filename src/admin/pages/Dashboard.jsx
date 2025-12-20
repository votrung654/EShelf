import { useState, useEffect } from 'react';
import { BookOpen, Users, Eye, Star } from 'lucide-react';
import StatsCard from '../components/StatsCard';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import bookDetailsData from '../../data/book-details.json';

const USERS_KEY = 'eshelf_users';

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalBooks: 0,
    totalUsers: 0,
    totalGenres: 0,
  });
  const [genreData, setGenreData] = useState([]);
  const [recentUsers, setRecentUsers] = useState([]);

  useEffect(() => {
    loadRealData();
  }, []);

  const loadRealData = () => {
    // Real books data
    const books = bookDetailsData || [];
    
    // Real users data from localStorage
    const usersData = localStorage.getItem(USERS_KEY);
    const users = usersData ? JSON.parse(usersData) : [];
    
    // Calculate real genre distribution
    const genreCounts = {};
    books.forEach(book => {
      book.genres?.forEach(genre => {
        genreCounts[genre] = (genreCounts[genre] || 0) + 1;
      });
    });
    
    const colors = ['#3B82F6', '#10B981', '#F59E0B', '#8B5CF6', '#EF4444', '#EC4899', '#06B6D4'];
    const genreChartData = Object.entries(genreCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 7)
      .map(([name, value], idx) => ({
        name: name.length > 15 ? name.substring(0, 15) + '...' : name,
        fullName: name,
        value,
        color: colors[idx % colors.length],
      }));

    setGenreData(genreChartData);
    
    setStats({
      totalBooks: books.length,
      totalUsers: users.length,
      totalGenres: Object.keys(genreCounts).length,
    });

    // Recent registered users
    const sortedUsers = [...users]
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
      .slice(0, 5);
    setRecentUsers(sortedUsers);
  };

  const formatTimeAgo = (dateStr) => {
    if (!dateStr) return 'Không rõ';
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'Vừa xong';
    if (mins < 60) return `${mins} phút trước`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours} giờ trước`;
    const days = Math.floor(hours / 24);
    if (days < 7) return `${days} ngày trước`;
    return new Date(dateStr).toLocaleDateString('vi-VN');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Dashboard</h1>
          <p className="text-gray-500 dark:text-gray-400">Tổng quan hệ thống eShelf</p>
        </div>
        <div className="text-sm text-gray-500 dark:text-gray-400">
          Cập nhật: {new Date().toLocaleString('vi-VN')}
        </div>
      </div>

      {/* Stats Cards - Real data */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatsCard
          title="Tổng số sách"
          value={stats.totalBooks.toLocaleString()}
          icon={BookOpen}
          trend={stats.totalBooks > 0 ? `${stats.totalBooks} sách trong thư viện` : 'Chưa có sách'}
          trendUp={stats.totalBooks > 0}
          color="blue"
        />
        <StatsCard
          title="Người dùng đã đăng ký"
          value={stats.totalUsers.toLocaleString()}
          icon={Users}
          trend={stats.totalUsers > 0 ? `${stats.totalUsers} tài khoản` : 'Chưa có người dùng'}
          trendUp={stats.totalUsers > 0}
          color="green"
        />
        <StatsCard
          title="Thể loại sách"
          value={stats.totalGenres.toLocaleString()}
          icon={Star}
          trend={stats.totalGenres > 0 ? `${stats.totalGenres} thể loại` : 'Chưa có thể loại'}
          trendUp={stats.totalGenres > 0}
          color="purple"
        />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bar Chart - Genre distribution */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-4">
            Phân bố sách theo thể loại
          </h3>
          {genreData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={genreData} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.3} />
                <XAxis type="number" stroke="#9CA3AF" fontSize={12} />
                <YAxis dataKey="name" type="category" stroke="#9CA3AF" fontSize={11} width={100} />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: '#1F2937', 
                    border: 'none', 
                    borderRadius: '8px',
                    color: '#fff'
                  }}
                  formatter={(value, name, props) => [value, props.payload.fullName]}
                />
                <Bar dataKey="value" fill="#3B82F6" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-gray-500 dark:text-gray-400">
              <div className="text-center">
                <BookOpen className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>Chưa có dữ liệu thể loại</p>
              </div>
            </div>
          )}
        </div>

        {/* Pie Chart */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-4">
            Tỷ lệ sách theo thể loại (Top 7)
          </h3>
          {genreData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={genreData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={90}
                  paddingAngle={2}
                  dataKey="value"
                >
                  {genreData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip 
                  formatter={(value, name, props) => [`${value} sách`, props.payload.fullName]}
                />
                <Legend 
                  formatter={(value, entry) => (
                    <span className="text-gray-600 dark:text-gray-300 text-xs">
                      {entry.payload.name}
                    </span>
                  )}
                />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-gray-500 dark:text-gray-400">
              <div className="text-center">
                <Star className="w-12 h-12 mx-auto mb-2 opacity-50" />
                <p>Chưa có dữ liệu</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Bottom Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Books */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-4">
            Sách trong thư viện
          </h3>
          {bookDetailsData && bookDetailsData.length > 0 ? (
            <div className="space-y-4">
              {bookDetailsData.slice(0, 5).map((book, idx) => (
                <div key={book.isbn} className="flex items-center gap-4">
                  <span className="w-6 h-6 bg-blue-100 dark:bg-blue-900/30 rounded-full flex items-center justify-center text-sm font-bold text-blue-600">
                    {idx + 1}
                  </span>
                  <img
                    src={book.coverUrl}
                    alt={book.title}
                    className="w-10 h-14 object-cover rounded"
                    onError={(e) => { e.target.src = '/images/book-placeholder.svg'; }}
                  />
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-gray-800 dark:text-gray-200 truncate">
                      {book.title}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">
                      {Array.isArray(book.author) ? book.author.join(', ') : book.author}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <BookOpen className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>Chưa có sách trong thư viện</p>
            </div>
          )}
        </div>

        {/* Recent Users */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-6">
          <h3 className="text-lg font-semibold text-gray-800 dark:text-white mb-4">
            Người dùng đăng ký gần đây
          </h3>
          {recentUsers.length > 0 ? (
            <div className="space-y-4">
              {recentUsers.map((user) => (
                <div 
                  key={user.id}
                  className="flex items-center justify-between py-3 border-b border-gray-100 dark:border-gray-700 last:border-0"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-green-100 dark:bg-green-900/30 rounded-full flex items-center justify-center">
                      <span className="text-green-600 font-medium">
                        {user.username?.[0]?.toUpperCase() || 'U'}
                      </span>
                    </div>
                    <div>
                      <p className="text-gray-800 dark:text-gray-200 font-medium">{user.username}</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">{user.email}</p>
                    </div>
                  </div>
                  <span className="text-xs text-gray-400">{formatTimeAgo(user.createdAt)}</span>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <Users className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>Chưa có người dùng đăng ký</p>
              <p className="text-sm mt-1">Người dùng mới sẽ hiển thị ở đây</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
