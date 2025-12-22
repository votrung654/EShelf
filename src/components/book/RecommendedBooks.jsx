import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Sparkles, ChevronRight } from 'lucide-react';
import { mlAPI } from '../../services/api';
import { useAuth } from '../../context/AuthContext';

export default function RecommendedBooks() {
  const { user, isAuthenticated } = useAuth();
  const [books, setBooks] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchRecommendations = async () => {
      setIsLoading(true);
      try {
        const userId = user?.id || 'anonymous';
        const response = await mlAPI.getRecommendations(userId, 12);
        if (response.success && response.data) {
          setBooks(response.data);
        }
      } catch (err) {
        console.error('Error fetching recommendations:', err);
        setBooks([]);
      } finally {
        setIsLoading(false);
      }
    };

    fetchRecommendations();
  }, [user]);

  if (!isLoading && books.length === 0) {
    return null;
  }

  return (
    <section className="my-12">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-800 dark:text-white flex items-center gap-2">
          <Sparkles className="w-6 h-6 text-yellow-500" />
          {isAuthenticated ? 'Dành cho bạn' : 'Gợi ý cho bạn'}
        </h2>
        <Link
          to="/genres"
          className="flex items-center gap-1 text-blue-600 dark:text-blue-400 hover:underline text-sm"
        >
          Xem tất cả
          <ChevronRight className="w-4 h-4" />
        </Link>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="aspect-[2/3] bg-gray-200 dark:bg-gray-700 rounded-lg mb-2" />
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-1" />
              <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2" />
            </div>
          ))}
        </div>
      ) : (
        <div className="relative">
          <div className="flex overflow-x-auto gap-4 pb-4 scrollbar-hide">
            {books.map((book) => (
              <Link
                key={book.isbn}
                to={`/book/${book.isbn}`}
                className="flex-shrink-0 w-36 md:w-40 group"
              >
                <div className="relative aspect-[2/3] rounded-lg overflow-hidden shadow-md group-hover:shadow-xl transition-all">
                  <img
                    src={book.coverUrl || '/images/book-placeholder.svg'}
                    alt={book.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    onError={(e) => { e.target.src = '/images/book-placeholder.svg'; }}
                  />
                  {book.score && (
                    <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-2">
                      <div className="flex items-center gap-1 text-white text-xs">
                        <Sparkles className="w-3 h-3" />
                        {Math.round(book.score * 100)}% match
                      </div>
                    </div>
                  )}
                </div>
                <div className="mt-2">
                  <h3 className="font-medium text-gray-800 dark:text-white text-sm line-clamp-2 group-hover:text-blue-600 dark:group-hover:text-blue-400">
                    {book.title}
                  </h3>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-1">
                    {Array.isArray(book.author) ? book.author.join(', ') : book.author}
                  </p>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}
    </section>
  );
}


