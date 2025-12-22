import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { favoritesAPI } from '../services/api';

const BookCard = ({ book, isMLRecommendation = false }) => {
  const { isAuthenticated } = useAuth();
  const [isFavorite, setIsFavorite] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // ID để gửi lên server (ưu tiên ID uuid, nếu không có thì dùng isbn)
  const bookIdentifier = book.id || book.isbn;

  // Check favorite status từ backend khi load component
  useEffect(() => {
    const checkFavorite = async () => {
      if (!isAuthenticated || !bookIdentifier) return;
      
      try {
        // Gọi API kiểm tra xem sách này đã like chưa
        // Lưu ý: Backend cần endpoint check, hoặc ta có thể check từ list favorites đã load ở trang cha
        // Ở đây giả sử gọi API check riêng lẻ
        const result = await favoritesAPI.check(bookIdentifier);
        if (result.success) {
             setIsFavorite(result.data.isFavorite);
        }
      } catch (error) {
        // Không log lỗi quá nhiều để tránh spam console
      }
    };

    checkFavorite();
  }, [bookIdentifier, isAuthenticated]);

  const handleToggleFavorite = async (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!isAuthenticated) {
      alert('Vui lòng đăng nhập để thêm yêu thích');
      return;
    }

    setIsLoading(true);
    try {
      if (isFavorite) {
        await favoritesAPI.remove(bookIdentifier);
        setIsFavorite(false);
      } else {
        await favoritesAPI.add(bookIdentifier);
        setIsFavorite(true);
      }
    } catch (error) {
      console.error('Toggle favorite error:', error);
      alert('Không thể cập nhật yêu thích. Kiểm tra kết nối!');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="book-card bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-all duration-300 group relative flex flex-col h-full">
      {/* ML Badge */}
      {isMLRecommendation && (
        <div className="absolute top-2 left-2 bg-gradient-to-r from-purple-500 to-pink-500 text-white text-xs font-bold px-2 py-1 rounded-full z-10 flex items-center gap-1">
          <span>✨</span>
          <span>AI Gợi ý</span>
        </div>
      )}

      <Link to={`/book/${bookIdentifier}`} className="block relative">
        <div className="relative aspect-[2/3] w-full overflow-hidden">
          <img 
            src={book.coverUrl || book.cover || 'https://placehold.co/400x600?text=No+Cover'} 
            alt={book.title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
            loading="lazy"
          />
          
          {/* Favorite button overlay */}
          <button
            onClick={handleToggleFavorite}
            disabled={isLoading}
            className={`absolute top-2 right-2 p-2 rounded-full transition-all shadow-sm ${
              isFavorite 
                ? 'bg-red-500 text-white' 
                : 'bg-white/90 text-gray-600 hover:bg-white hover:text-red-500'
            } ${isLoading ? 'opacity-70 cursor-wait' : ''}`}
            title={isFavorite ? 'Bỏ yêu thích' : 'Thêm yêu thích'}
          >
            <span className="text-lg leading-none">{isFavorite ? '❤️' : '🤍'}</span>
          </button>
        </div>
      </Link>
        
      <div className="p-4 flex flex-col flex-1">
        <Link to={`/book/${bookIdentifier}`}>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white line-clamp-2 mb-1 hover:text-blue-600 transition-colors">
            {book.title}
            </h3>
        </Link>
        
        <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-1 mb-2">
          {Array.isArray(book.authors) ? book.authors.join(', ') : (book.author || 'Unknown')}
        </p>
        
        <div className="mt-auto flex items-center justify-between">
            {/* Rating giả lập nếu backend chưa có */}
            <div className="flex items-center">
                <span className="text-yellow-500 text-sm">★</span>
                <span className="ml-1 text-sm text-gray-600 dark:text-gray-400">
                {book.rating || '4.5'}
                </span>
            </div>

            {/* Genre Badge */}
            {(book.genres && book.genres.length > 0) ? (
                <span className="inline-block px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-300 rounded">
                {typeof book.genres[0] === 'string' ? book.genres[0] : book.genres[0].name}
                </span>
            ) : (
                <span className="text-xs text-gray-400">General</span>
            )}
        </div>
      </div>
    </div>
  );
};

export default BookCard;