import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ArrowLeft, Trash2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { collectionsAPI } from '../services/api';

export default function CollectionDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { isAuthenticated } = useAuth();
  const [collection, setCollection] = useState(null);
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }

    loadCollection();
  }, [id, isAuthenticated]);

  const loadCollection = async () => {
    setLoading(true);
    try {
      const response = await collectionsAPI.getById(id);
      if (response.success && response.data) {
        setCollection(response.data);
        
        // Backend trả về books là array book objects hoặc bookIds
        const booksData = response.data.books || [];
        
        // Nếu là array bookIds, fetch book details
        if (booksData.length > 0 && typeof booksData[0] === 'string') {
          const { booksAPI } = await import('../services/api');
          const bookDetails = await Promise.all(
            booksData.map(async (bookId) => {
              try {
                const bookRes = await booksAPI.getById(bookId);
                if (bookRes.success && bookRes.data) {
                  return bookRes.data;
                }
                return null;
              } catch (error) {
                console.error('Error fetching book:', error);
                return null;
              }
            })
          );
          setBooks(bookDetails.filter(Boolean));
        } else {
          // Nếu đã là book objects
          setBooks(booksData);
        }
      }
    } catch (error) {
      console.error('Load collection error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleRemoveBook = async (bookId) => {
    if (!window.confirm('Xóa sách khỏi bộ sưu tập?')) return;

    try {
      await collectionsAPI.removeBook(id, bookId);
      // Reload collection để có data chính xác
      await loadCollection();
    } catch (error) {
      console.error('Remove book error:', error);
      alert('Không thể xóa sách');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  if (!collection) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500">Không tìm thấy bộ sưu tập</p>
        <Link to="/collections" className="text-blue-600 hover:underline mt-4 inline-block">
          Quay lại
        </Link>
      </div>
    );
  }

  return (
    <main className="max-w-7xl mx-auto px-4 py-8">
      {/* Header */}
      <button
        onClick={() => navigate('/collections')}
        className="flex items-center gap-2 text-gray-600 dark:text-gray-300 hover:text-blue-600 mb-6"
      >
        <ArrowLeft className="w-5 h-5" />
        Quay lại
      </button>

      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          {collection.name}
        </h1>
        {collection.description && (
          <p className="text-gray-600 dark:text-gray-400">
            {collection.description}
          </p>
        )}
        <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
          {books.length} cuốn sách
        </p>
      </div>

      {/* Books Grid */}
      {books.length > 0 ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6">
          {books.map((book) => {
            const bookId = book.id || book.isbn;
            return (
              <div key={bookId} className="relative group" style={{ position: 'relative' }}>
                <Link
                  to={`/book/${bookId}`}
                  className="block bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-all duration-300 group relative flex flex-col h-full"
                  onClick={(e) => {
                    e.stopPropagation();
                  }}
                >
                  {/* Book Cover */}
                  <div className="relative aspect-[2/3] w-full overflow-hidden">
                    <img 
                      src={book.coverUrl || book.cover || 'https://placehold.co/400x600?text=No+Cover'} 
                      alt={book.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      loading="lazy"
                    />
                  </div>
                  
                  <div className="p-4 flex flex-col flex-1">
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100 line-clamp-2 mb-1 hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                      {book.title}
                    </h3>
                    
                    <p className="text-sm text-gray-600 dark:text-gray-300 line-clamp-1 mb-2">
                      {Array.isArray(book.authors) ? book.authors.join(', ') : (book.author || 'Unknown')}
                    </p>
                    
                    <div className="mt-auto flex items-center justify-between">
                      {/* Rating */}
                      <div className="flex items-center">
                        <span className="text-yellow-500 text-sm">★</span>
                        <span className="ml-1 text-sm text-gray-600 dark:text-gray-300">
                          {book.rating || '4.5'}
                        </span>
                      </div>

                      {/* Genre Badge */}
                      {(book.genres && book.genres.length > 0) ? (
                        <span className="inline-block px-2 py-1 text-xs bg-blue-100 dark:bg-blue-800 text-blue-700 dark:text-blue-200 rounded">
                          {typeof book.genres[0] === 'string' ? book.genres[0] : book.genres[0].name}
                        </span>
                      ) : (
                        <span className="text-xs text-gray-400 dark:text-gray-500">General</span>
                      )}
                    </div>
                  </div>
                </Link>
                <button
                  onClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    handleRemoveBook(bookId);
                  }}
                  onMouseDown={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                  }}
                  className="absolute top-2 left-2 p-2 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-all z-50 hover:bg-red-600"
                  title="Xóa khỏi bộ sưu tập"
                  style={{ 
                    pointerEvents: 'auto'
                  }}
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="text-center py-12 bg-gray-50 dark:bg-gray-800 rounded-xl">
          <p className="text-gray-500 dark:text-gray-400">
            Bộ sưu tập chưa có sách nào
          </p>
        </div>
      )}
    </main>
  );
}
