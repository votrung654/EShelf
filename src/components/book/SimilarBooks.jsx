import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Star, BookOpen } from 'lucide-react';
import { mlAPI } from '../../services/api';

export default function SimilarBooks({ bookId, bookGenres = [] }) {
  const [books, setBooks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchSimilarBooks = async () => {
      if (!bookId) return;
      
      setIsLoading(true);
      setError(null);

      try {
        const response = await mlAPI.getSimilarBooks(bookId, 6);
        if (response.success && response.data) {
          setBooks(response.data);
        }
      } catch (err) {
        console.error('Error fetching similar books:', err);
        setError('Không thể tải sách tương tự');
        // Fallback to showing books with same genres
        setBooks([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchSimilarBooks();
  }, [bookId]);

  if (isLoading) {
    return (
      <div className="mt-8">
        <h2 className="text-xl font-bold text-gray-800 dark:text-white mb-4">
          Sách tương tự
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="aspect-[2/3] bg-gray-200 dark:bg-gray-700 rounded-lg mb-2" />
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-1" />
              <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (error || books.length === 0) {
    return null;
  }

  return (
    <div className="mt-8">
      <h2 className="text-xl font-bold text-gray-800 dark:text-white mb-4 flex items-center gap-2">
        <BookOpen className="w-5 h-5" />
        Sách tương tự
      </h2>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {books.map((book) => (
          <Link
            key={book.isbn}
            to={`/book/${book.isbn}`}
            className="group"
          >
            <div className="relative aspect-[2/3] rounded-lg overflow-hidden shadow-md group-hover:shadow-lg transition-shadow">
              <img
                src={book.coverUrl || '/images/book-placeholder.svg'}
                alt={book.title}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                onError={(e) => { e.target.src = '/images/book-placeholder.svg'; }}
              />
              {book.similarity && (
                <div className="absolute top-2 right-2 bg-blue-600 text-white text-xs px-2 py-1 rounded-full">
                  {Math.round(book.similarity * 100)}% match
                </div>
              )}
            </div>
            <div className="mt-2">
              <h3 className="font-medium text-gray-800 dark:text-white text-sm line-clamp-2 group-hover:text-blue-600 dark:group-hover:text-blue-400">
                {book.title}
              </h3>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                {Array.isArray(book.author) ? book.author.join(', ') : book.author}
              </p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}


