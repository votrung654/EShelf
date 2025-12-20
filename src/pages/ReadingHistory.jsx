import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import bookDetails from '../data/book-details.json';
import { formatTimeAgo } from '../components/book/ReadingProgress';

const PROGRESS_BASE_KEY = 'eshelf_reading_progress';

export default function ReadingHistory() {
  const navigate = useNavigate();
  const { user, isAuthenticated } = useAuth();
  const [historyItems, setHistoryItems] = useState([]);

  // Redirect if not logged in
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
    }
  }, [isAuthenticated, navigate]);

  useEffect(() => {
    if (!user?.id) return;

    const storageKey = `${PROGRESS_BASE_KEY}_${user.id}`;
    const saved = localStorage.getItem(storageKey);
    
    if (!saved) {
      setHistoryItems([]);
      return;
    }

    try {
      const allProgress = JSON.parse(saved);
      
      const items = Object.entries(allProgress)
        .map(([isbn, progress]) => {
          const book = bookDetails.find(b => b.isbn === isbn);
          if (!book) return null;
          return { ...book, progress };
        })
        .filter(Boolean)
        .sort((a, b) => new Date(b.progress.lastReadAt) - new Date(a.progress.lastReadAt));
      
      setHistoryItems(items);
    } catch {
      setHistoryItems([]);
    }
  }, [user?.id]);

  if (!isAuthenticated) {
    return null;
  }

  return (
    <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
      {/* Breadcrumb */}
      <nav className="mb-6">
        <ol className="flex items-center space-x-2 text-sm">
          <li><Link to="/" className="text-blue-600 hover:underline">Trang chủ</Link></li>
          <li className="text-gray-400">/</li>
          <li className="text-gray-600">Lịch sử đọc</li>
        </ol>
      </nav>

      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-2">Lịch sử đọc sách</h1>
        <p className="text-gray-500">{historyItems.length} sách đã đọc</p>
      </div>

      {historyItems.length > 0 ? (
        <div className="space-y-4">
          {historyItems.map(item => (
            <div
              key={item.isbn}
              className="bg-white rounded-xl shadow-md p-4 flex gap-4 hover:shadow-lg transition-shadow"
            >
              <Link to={`/book/${item.isbn}`} className="flex-shrink-0">
                <img
                  src={item.coverUrl}
                  alt={item.title}
                  className="w-20 h-28 object-cover rounded-lg shadow"
                  onError={(e) => { e.target.src = '/images/book-placeholder.svg'; }}
                />
              </Link>

              <div className="flex-1 min-w-0">
                <Link to={`/book/${item.isbn}`} className="font-semibold text-gray-800 hover:text-blue-600 line-clamp-1">
                  {item.title}
                </Link>
                <p className="text-sm text-gray-500 mb-2">
                  {Array.isArray(item.author) ? item.author.join(', ') : item.author}
                </p>
                <p className="text-xs text-gray-400">
                  Đọc lần cuối: {formatTimeAgo(item.progress.lastReadAt)}
                </p>
              </div>

              <div className="flex flex-col gap-2">
                <Link
                  to={`/reading/${item.isbn}`}
                  state={item.pdfUrl}
                  className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition-colors text-center"
                >
                  Đọc tiếp
                </Link>
                <Link
                  to={`/book/${item.isbn}`}
                  className="px-4 py-2 border border-gray-300 text-gray-600 text-sm rounded-lg hover:bg-gray-50 transition-colors text-center"
                >
                  Chi tiết
                </Link>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-16 bg-gray-50 rounded-xl">
          <div className="w-20 h-20 bg-gray-200 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-800 mb-2">Chưa có lịch sử đọc</h3>
          <p className="text-gray-500 mb-4">Bắt đầu đọc sách để lưu lại lịch sử</p>
          <Link to="/" className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            Khám phá sách
          </Link>
        </div>
      )}
    </main>
  );
}
