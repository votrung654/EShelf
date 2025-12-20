import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';

const BookCard = ({ book }) => {
  const [isFavorite, setIsFavorite] = useState(false);

  useEffect(() => {
    const favorites = JSON.parse(localStorage.getItem('eshelf_favorites') || '[]');
    setIsFavorite(favorites.some(fav => fav.id === book.id));
  }, [book.id]);

  const handleToggleFavorite = (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    const favorites = JSON.parse(localStorage.getItem('eshelf_favorites') || '[]');
    
    if (isFavorite) {
      const newFavorites = favorites.filter(fav => fav.id !== book.id);
      localStorage.setItem('eshelf_favorites', JSON.stringify(newFavorites));
      setIsFavorite(false);
    } else {
      favorites.push(book);
      localStorage.setItem('eshelf_favorites', JSON.stringify(favorites));
      setIsFavorite(true);
    }
  };

  return (
    <div className="book-card bg-white dark:bg-gray-800 rounded-lg shadow-md overflow-hidden hover:shadow-xl transition-all duration-300 group">
      {/* ✅ Use Link - navigates in SAME tab */}
      <Link to={`/book/${book.id}`} className="block">
        <div className="relative">
          <img 
            src={book.coverUrl || book.cover || '/images/default-cover.jpg'} 
            alt={book.title}
            className="w-full h-64 object-cover group-hover:scale-105 transition-transform duration-300"
          />
          {/* Favorite button overlay */}
          <button
            onClick={handleToggleFavorite}
            className={`absolute top-2 right-2 p-2 rounded-full transition-all ${
              isFavorite 
                ? 'bg-red-500 text-white' 
                : 'bg-white/80 text-gray-600 hover:bg-white'
            }`}
            title={isFavorite ? 'Bỏ yêu thích' : 'Thêm yêu thích'}
          >
            {isFavorite ? '❤️' : '🤍'}
          </button>
        </div>
        
        <div className="p-4">
          {/* ✅ Display correct title from book data */}
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white line-clamp-2 mb-1">
            {book.title}
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {book.author}
          </p>
          
          {book.rating && (
            <div className="flex items-center mt-2">
              <span className="text-yellow-500">★</span>
              <span className="ml-1 text-sm text-gray-600 dark:text-gray-400">
                {book.rating}
              </span>
            </div>
          )}
          
          {book.genre && (
            <span className="inline-block mt-2 px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900 text-blue-600 dark:text-blue-300 rounded">
              {book.genre}
            </span>
          )}
        </div>
      </Link>
    </div>
  );
};

export default BookCard;
