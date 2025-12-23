import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { historyAPI, booksAPI } from '../services/api';
import { formatTimeAgo } from '../components/book/ReadingProgress';

export default function ReadingHistory() {
  const navigate = useNavigate();
  const { user, isAuthenticated } = useAuth();
  const [historyItems, setHistoryItems] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Redirect if not logged in
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
    }
  }, [isAuthenticated, navigate]);

  useEffect(() => {
    const loadHistory = async () => {
      if (!isAuthenticated || !user?.id) {
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      try {
        const response = await historyAPI.getAll();
        if (response.success && response.data) {
          // Fetch book details for each history item
          const itemsWithBooks = await Promise.all(
            response.data.map(async (historyItem) => {
              try {
                const bookResponse = await booksAPI.getById(historyItem.bookId);
                if (bookResponse.success && bookResponse.data) {
                  return {
                    ...bookResponse.data,
                    id: bookResponse.data.id || bookResponse.data.isbn, // Đảm bảo có id
                    isbn: bookResponse.data.isbn,
                    bookId: historyItem.bookId, // Giữ lại bookId từ history
                    historyId: historyItem.id, // Thêm historyId để có unique key
                    progress: {
                      id: historyItem.id, // Thêm id vào progress để dùng làm key
                      currentPage: historyItem.currentPage,
                      totalPages: historyItem.totalPages,
                      progressPercent: historyItem.progressPercent,
                      lastReadAt: historyItem.lastReadAt,
                      startedAt: historyItem.startedAt,
                      finishedAt: historyItem.finishedAt,
                    }
                  };
                }
                return null;
              } catch (error) {
                console.error('Error fetching book:', error);
                return null;
              }
            })
          );
          
          const validItems = itemsWithBooks.filter(Boolean);
          setHistoryItems(validItems);
        } else {
          setHistoryItems([]);
        }
      } catch (error) {
        console.error('Error loading reading history:', error);
        setHistoryItems([]);
      } finally {
        setIsLoading(false);
      }
    };

    loadHistory();
  }, [isAuthenticated, user?.id]);

  if (!isAuthenticated) {
    return null;
  }

  if (isLoading) {
    return (
      <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full" />
        </div>
      </main>
    );
  }

  return (
    <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
      {/* Breadcrumb */}
      <nav className="mb-6">
        <ol className="flex items-center space-x-2 text-sm">
          <li><Link to="/" className="text-blue-600 dark:text-blue-400 hover:underline">Trang chủ</Link></li>
          <li className="text-gray-400 dark:text-gray-500">/</li>
          <li className="text-gray-600 dark:text-gray-400">Lịch sử đọc</li>
        </ol>
      </nav>

      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-100 mb-2">Lịch sử đọc sách</h1>
        <p className="text-gray-500 dark:text-gray-400">{historyItems.length} sách đã đọc</p>
      </div>

      {historyItems.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {historyItems.map((item, index) => {
            // Tạo unique key - dùng historyItem id từ backend nếu có, nếu không thì dùng bookId + index
            const historyId = item.progress?.id || item.historyId;
            const uniqueKey = historyId || `${item.id || item.isbn || item.bookId || 'book'}-${index}`;
            
            return (
              <div
                key={uniqueKey}
                className="bg-white dark:bg-gray-800 rounded-xl shadow-md dark:shadow-gray-900/50 p-4 flex gap-4 hover:shadow-lg transition-shadow"
              >
                <Link 
                  to={`/book/${item.id || item.isbn || item.bookId}`} 
                  className="flex-shrink-0"
                  onClick={(e) => e.stopPropagation()}
                >
                  <img
                    src={item.coverUrl || item.cover || '/images/book-placeholder.svg'}
                    alt={item.title}
                    className="w-20 h-28 object-cover rounded-lg shadow"
                    onError={(e) => { e.target.src = '/images/book-placeholder.svg'; }}
                  />
                </Link>

                <div className="flex-1 min-w-0">
                  <Link 
                    to={`/book/${item.id || item.isbn || item.bookId}`} 
                    className="font-semibold text-gray-800 dark:text-gray-100 hover:text-blue-600 dark:hover:text-blue-400 line-clamp-1"
                    onClick={(e) => e.stopPropagation()}
                  >
                    {item.title}
                  </Link>
                  <p className="text-sm text-gray-500 dark:text-gray-400 mb-2">
                    {Array.isArray(item.authors) ? item.authors.join(', ') : (item.author || 'Unknown')}
                  </p>
                  <p className="text-xs text-gray-400 dark:text-gray-500">
                    Đọc lần cuối: {formatTimeAgo(item.progress?.lastReadAt)}
                  </p>
                  {item.progress && (
                    <div className="mt-2">
                      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                        <div 
                          className="bg-blue-600 h-2 rounded-full" 
                          style={{ width: `${item.progress.progressPercent || 0}%` }}
                        />
                      </div>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        {item.progress.currentPage || 0} / {item.progress.totalPages || 0} trang
                      </p>
                    </div>
                  )}
                </div>

                <div className="flex flex-col gap-2">
                  <Link
                    to={`/reading/${item.id || item.isbn || item.bookId}`}
                    state={item.pdfUrl}
                    className="px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 transition-colors text-center"
                    onClick={(e) => e.stopPropagation()}
                  >
                    Đọc tiếp
                  </Link>
                  <Link
                    to={`/book/${item.id || item.isbn || item.bookId}`}
                    className="px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-300 text-sm rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-center"
                    onClick={(e) => e.stopPropagation()}
                  >
                    Chi tiết
                  </Link>
                  <button
                    onClick={async (e) => {
                      e.preventDefault();
                      if (!window.confirm('Xóa khỏi lịch sử đọc?')) return;
                      
                      try {
                        const { historyAPI } = await import('../services/api');
                        await historyAPI.deleteBook(item.id || item.isbn);
                        // Reload history
                        setHistoryItems(prev => prev.filter(h => (h.id || h.isbn) !== (item.id || item.isbn)));
                      } catch (error) {
                        console.error('Error deleting history:', error);
                        alert('Không thể xóa lịch sử');
                      }
                    }}
                    className="px-4 py-2 border border-red-300 dark:border-red-600 text-red-600 dark:text-red-300 text-sm rounded-lg hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors"
                  >
                    Xóa
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="text-center py-16 bg-gray-50 dark:bg-gray-800 rounded-xl">
          <div className="w-20 h-20 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-10 h-10 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-800 dark:text-gray-100 mb-2">Chưa có lịch sử đọc</h3>
          <p className="text-gray-500 dark:text-gray-400 mb-4">Bắt đầu đọc sách để lưu lại lịch sử</p>
          <Link to="/" className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">
            Khám phá sách
          </Link>
        </div>
      )}
    </main>
  );
}
