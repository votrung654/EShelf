import { useState, useEffect } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import BookCard from '../components/BookCard';
import booksData from '../data/book-details.json';

const Search = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [searchTerm, setSearchTerm] = useState(searchParams.get('q') || '');
  const [results, setResults] = useState([]);
  const [selectedGenre, setSelectedGenre] = useState(searchParams.get('genre') || 'all');

  // Get unique genres from books
  const genres = ['all', ...new Set(booksData.flatMap(book => book.genres || [book.genre]))];

  useEffect(() => {
    const query = searchParams.get('q') || '';
    const genre = searchParams.get('genre') || 'all';
    
    setSearchTerm(query);
    setSelectedGenre(genre);
    
    let filtered = booksData;
    
    // Filter by search term
    if (query) {
      filtered = filtered.filter(book => 
        book.title?.toLowerCase().includes(query.toLowerCase()) ||
        book.author?.toLowerCase().includes(query.toLowerCase()) ||
        book.description?.toLowerCase().includes(query.toLowerCase())
      );
    }
    
    // Filter by genre
    if (genre !== 'all') {
      filtered = filtered.filter(book => 
        book.genres?.includes(genre) || book.genre === genre
      );
    }
    
    setResults(filtered);
  }, [searchParams]);

  const handleSearch = (e) => {
    e.preventDefault();
    setSearchParams({ q: searchTerm });
  };

  return (
    <div className="container mx-auto px-4 py-8 bg-slate-50 dark:bg-gray-900 min-h-screen">
      {/* Navigation Buttons - NO SEARCH BAR HERE */}
      <div className="flex flex-wrap gap-3 mb-6">
        <Link 
          to="/collections" 
          className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
        >
          Bộ sưu tập
        </Link>
        <Link 
          to="/reading-history" 
          className="px-4 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
        >
          Lịch sử đọc
        </Link>
        
        {/* Genre filter dropdown */}
        <select
          value={selectedGenre}
          onChange={(e) => {
            setSelectedGenre(e.target.value);
            const query = searchParams.get('q') || '';
            if (e.target.value === 'all') {
              setSearchParams(query ? { q: query } : {});
            } else {
              setSearchParams(query ? { q: query, genre: e.target.value } : { genre: e.target.value });
            }
          }}
          className="px-4 py-2 border rounded-lg bg-white text-gray-900 border-gray-300"
        >
          {genres.map(genre => (
            <option key={genre} value={genre}>
              {genre === 'all' ? 'Tất cả thể loại' : genre}
            </option>
          ))}
        </select>
      </div>

      {/* Main Search Bar - ONLY ONE */}
      <form onSubmit={handleSearch} className="mb-8">
        <div className="flex gap-2">
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Tìm kiếm sách theo tên, tác giả..."
            className="flex-1 px-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white text-gray-900 border-gray-300"
          />
          <button
            type="submit"
            className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Tìm kiếm
          </button>
        </div>
      </form>

      {/* Results count */}
      <p className="text-gray-600 mb-4">
        Tìm thấy {results.length} kết quả
        {searchParams.get('q') && ` cho "${searchParams.get('q')}"`}
      </p>

      {/* Results Grid */}
      {results.length > 0 ? (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-6">
          {results.map(book => (
            <BookCard key={book.id || book.isbn} book={book} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 bg-white rounded-xl">
          <p className="text-gray-500 text-lg">
            Không tìm thấy sách phù hợp. Thử từ khóa khác?
          </p>
        </div>
      )}
    </div>
  );
};

export default Search;
