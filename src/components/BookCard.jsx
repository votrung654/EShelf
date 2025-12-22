import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { favoritesAPI } from '../services/api';

const BookCard = ({ book, isMLRecommendation = false }) => {
  const { isAuthenticated } = useAuth();
  const [isFavorite, setIsFavorite] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  // Check favorite status từ backend
  useEffect(() => {
    const checkFavorite = async () => {
      if (!isAuthenticated || !book?.isbn) return;
      
      try {
        const result = await favoritesAPI.check(book.isbn);
        setIsFavorite(result.data.isFavorite);
      } catch (error) {
        console.error('Check favorite error:', error);
      }
    };

    checkFavorite();
  }, [book?.isbn, isAuthenticated]);

  const handleToggleFavorite = async (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (!isAuthenticated) {
      alert('Vui lòng đăng nhập để thêm yêu thích');
      return;
    }

    if (!book?.isbn) return;
    
    setIsLoading(true);
    try {
      await favoritesAPI.toggle(book.isbn);
      setIsFavorite(!isFavorite);
    } catch (error) {
      console.error('Toggle favorite error:', error);
      alert('Không thể cập nhật yêu thích');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="book-card bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-all duration-300 group relative">
      {/* ML Badge */}
      {isMLRecommendation && (
        <div className="absolute top-2 left-2 bg-gradient-to-r from-purple-500 to-pink-500 text-white text-xs font-bold px-2 py-1 rounded-full z-10 flex items-center gap-1">
          <span>✨</span>
          <span>AI Gợi ý</span>
        </div>
      )}

      <Link to={`/book/${book.isbn || book.id}`} className="block">
        <div className="relative">
          <img 
            src={book.coverUrl || book.cover || '/images/default-cover.jpg'} 
            alt={book.title}
            className="w-full h-64 object-cover group-hover:scale-105 transition-transform duration-300"
          />
          
          {/* Favorite button overlay */}
          <button
            onClick={handleToggleFavorite}
            disabled={isLoading}
            className={`absolute top-2 right-2 p-2 rounded-full transition-all ${
              isFavorite 
                ? 'bg-red-500 text-white' 
                : 'bg-white/80 text-gray-600 hover:bg-white'
            } ${isLoading ? 'opacity-50 cursor-wait' : ''}`}
            title={isFavorite ? 'Bỏ yêu thích' : 'Thêm yêu thích'}
          >
            {isFavorite ? '❤️' : '🤍'}
          </button>
        </div>
        
        <div className="p-4">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white line-clamp-2 mb-1">
            {book.title}
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {Array.isArray(book.author) ? book.author.join(', ') : book.author}
          </p>
          
          {book.rating && (
            <div className="flex items-center mt-2">
              <span className="text-yellow-500">★</span>
              <span className="ml-1 text-sm text-gray-600 dark:text-gray-400">
                {book.rating}
              </span>
            </div>
          )}
          
          {book.genres && book.genres.length > 0 && (
            <span className="inline-block mt-2 px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-300 rounded">
              {book.genres[0]}
            </span>
          )}
        </div>
      </Link>
    </div>
  );
};

export default BookCard;
