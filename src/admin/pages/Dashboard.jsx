import { useState, useEffect } from 'react';
import { BookOpen, Users, Eye, Star } from 'lucide-react';
import StatsCard from '../components/StatsCard';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import { booksAPI, genresAPI, usersAPI } from '../../services/api';

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalBooks: 0,
    totalUsers: 0,
    totalGenres: 0,
  });
  const [genreData, setGenreData] = useState([]);
  const [recentUsers, setRecentUsers] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadRealData();
  }, []);

  const loadRealData = async () => {
    setIsLoading(true);
    try {
      const [booksRes, genresRes, usersRes] = await Promise.all([
        booksAPI.getAll(1, 1000),
        genresAPI.getAll(),
        usersAPI.getAll(1, 10).catch(() => ({ success: false, data: { users: [], pagination: { total: 0 } } }))
      ]);

      const books = booksRes.success && booksRes.data ? booksRes.data.books : [];
      const genres = genresRes.success && genresRes.data ? genresRes.data : [];
      
      const totalUsers = usersRes.success 
        ? (usersRes.data?.pagination?.total ?? usersRes.pagination?.total ?? 0)
        : 0;

      const users = usersRes.success && usersRes.data?.users 
        ? usersRes.data.users 
        : (usersRes.success && usersRes.data ? usersRes.data : []);

      const recentUsersList = Array.isArray(users) 
        ? users.slice(0, 5).map(user => ({
            id: user.id,
            name: user.name || user.username || 'N/A',
            email: user.email,
            createdAt: user.createdAt
          }))
        : [];

      const genreCounts = {};
      books.forEach(book => {
        if (Array.isArray(book.genres)) {
          book.genres.forEach(genre => {
            const genreName = typeof genre === 'string' ? genre : genre.name;
            if (genreName) {
              genreCounts[genreName] = (genreCounts[genreName] || 0) + 1;
            }
          });
        }
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
        totalUsers: totalUsers,
        totalGenres: genres.length,
      });

      setRecentUsers(recentUsersList);
    } catch (error) {
      console.error('Error loading dashboard data:', error);
    } finally {
      setIsLoading(false);
    }
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
          {isLoading ? (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent"></div>
              <p className="mt-2">Đang tải...</p>
            </div>
          ) : stats.totalBooks > 0 ? (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <BookOpen className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>{stats.totalBooks} sách trong hệ thống</p>
              <p className="text-sm mt-1">Danh sách chi tiết xem tại Quản lý sách</p>
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
          {isLoading ? (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent"></div>
              <p className="mt-2">Đang tải...</p>
            </div>
          ) : recentUsers.length > 0 ? (
            <div className="space-y-3">
              {recentUsers.map((user) => (
                <div key={user.id} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                  <div className="flex items-center space-x-3">
                    <div className="w-10 h-10 rounded-full bg-blue-500 flex items-center justify-center text-white font-semibold">
                      {(user.name || user.email || 'U').charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <p className="font-medium text-gray-800 dark:text-white">{user.name || user.email}</p>
                      <p className="text-sm text-gray-500 dark:text-gray-400">{user.email}</p>
                    </div>
                  </div>
                  <div className="text-sm text-gray-500 dark:text-gray-400">
                    {formatTimeAgo(user.createdAt)}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-gray-500 dark:text-gray-400">
              <Users className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>Chưa có người dùng</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
