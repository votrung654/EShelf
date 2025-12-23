import { useState, useEffect } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import BookCard from '../components/BookCard';
import { booksAPI, genresAPI } from '../services/api';
import Select from 'react-select';

const Search = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const [searchTerm, setSearchTerm] = useState(searchParams.get('q') || '');
  const [results, setResults] = useState([]);
  const [selectedGenre, setSelectedGenre] = useState(searchParams.get('genre') || 'all');
  const [fromYear, setFromYear] = useState(searchParams.get('fromYear') || '');
  const [toYear, setToYear] = useState(searchParams.get('toYear') || '');
  const [selectedLanguage, setSelectedLanguage] = useState(searchParams.get('language') || null);
  const [genres, setGenres] = useState(['all']);
  const [isLoading, setIsLoading] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);

  // Load genres from API
  useEffect(() => {
    const loadGenres = async () => {
      try {
        const response = await genresAPI.getAll();
        if (response.success && response.data) {
          const genreNames = response.data.map(g => g.name || g);
          setGenres(['all', ...genreNames]);
        }
      } catch (error) {
        console.error('Error loading genres:', error);
      }
    };
    loadGenres();
  }, []);

  // Search books from API
  useEffect(() => {
    const searchBooks = async () => {
      const query = searchParams.get('q') || '';
      const genre = searchParams.get('genre') || 'all';
      const fromYearParam = searchParams.get('fromYear') || '';
      const toYearParam = searchParams.get('toYear') || '';
      const languageParam = searchParams.get('language') || '';

      // Chỉ search nếu có ít nhất 1 điều kiện
      const hasAnyFilter = query || (genre !== 'all') || fromYearParam || toYearParam || languageParam;
      
      if (!hasAnyFilter) {
        setResults([]);
        setIsLoading(false);
        return;
      }

      setIsLoading(true);
      try {
        // Build search params
        const searchParams_obj = {};
        if (query) searchParams_obj.q = query;
        if (genre !== 'all') searchParams_obj.genre = genre;
        if (fromYearParam) searchParams_obj.fromYear = fromYearParam;
        if (toYearParam) searchParams_obj.toYear = toYearParam;
        if (languageParam) searchParams_obj.language = languageParam;

        console.log('Searching with params:', searchParams_obj);

        const response = await booksAPI.search(searchParams_obj);
        if (response.success && response.data) {
          setResults(response.data.books || []);
        } else {
          setResults([]);
        }
      } catch (error) {
        console.error('Search error:', error);
        setResults([]);
      } finally {
        setIsLoading(false);
      }
    };

    searchBooks();
  }, [searchParams]);

  // Update state from URL params
  useEffect(() => {
    setSearchTerm(searchParams.get('q') || '');
    setSelectedGenre(searchParams.get('genre') || 'all');
    setFromYear(searchParams.get('fromYear') || '');
    setToYear(searchParams.get('toYear') || '');
    const lang = searchParams.get('language');
    setSelectedLanguage(lang ? { value: lang, label: lang } : null);
    setShowAdvanced(!!(searchParams.get('fromYear') || searchParams.get('toYear') || searchParams.get('language')));
  }, [searchParams]);

  const handleSearch = (e) => {
    if (e) e.preventDefault();
    const params = {};
    if (searchTerm) params.q = searchTerm;
    if (selectedGenre !== 'all') params.genre = selectedGenre;
    if (fromYear) params.fromYear = fromYear;
    if (toYear) params.toYear = toYear;
    if (selectedLanguage) params.language = selectedLanguage.value;
    
    // Chỉ search nếu có ít nhất 1 điều kiện
    if (Object.keys(params).length > 0) {
      setSearchParams(params);
    } else {
      // Nếu không có điều kiện nào, clear results
      setResults([]);
    }
  };

  const handleAdvancedChange = () => {
    if (!showAdvanced) {
      setShowAdvanced(true);
    }
  };

  const languageOptions = [
    { value: 'Tiếng Việt', label: 'Tiếng Việt' },
    { value: 'Tiếng Anh', label: 'Tiếng Anh' },
  ];

  return (
    <div className="container mx-auto px-4 py-8 bg-slate-50 dark:bg-gray-900 min-h-screen">
      {/* Navigation Buttons */}
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
            const params = { ...Object.fromEntries(searchParams) };
            if (e.target.value === 'all') {
              delete params.genre;
            } else {
              params.genre = e.target.value;
            }
            setSearchParams(params);
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

      {/* Main Search Bar */}
      <form onSubmit={handleSearch} className="mb-4">
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

      {/* Advanced Search */}
      {showAdvanced ? (
        <form onSubmit={handleSearch} className="mb-6 p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-300 dark:border-gray-700">
          <div className="flex flex-wrap gap-4 items-end">
            <div className="flex gap-2">
              <input
                type="number"
                value={fromYear}
                onChange={(e) => setFromYear(e.target.value)}
                placeholder="Từ năm"
                className="w-24 px-3 py-2 border rounded-lg bg-white text-gray-900 border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
              <input
                type="number"
                value={toYear}
                onChange={(e) => setToYear(e.target.value)}
                placeholder="Đến năm"
                className="w-24 px-3 py-2 border rounded-lg bg-white text-gray-900 border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
            <div className="w-52">
              <Select
                value={selectedLanguage}
                onChange={(value) => {
                  setSelectedLanguage(value);
                  // Auto search when language changes
                  const params = {};
                  if (searchTerm) params.q = searchTerm;
                  if (selectedGenre !== 'all') params.genre = selectedGenre;
                  if (fromYear) params.fromYear = fromYear;
                  if (toYear) params.toYear = toYear;
                  if (value) params.language = value.value;
                  setSearchParams(params);
                }}
                options={languageOptions}
                placeholder="Chọn ngôn ngữ"
                isClearable
                classNamePrefix="select"
                styles={{
                  control: (base) => ({
                    ...base,
                    backgroundColor: 'white',
                    color: '#111827',
                    borderColor: '#d1d5db',
                  }),
                  menu: (base) => ({
                    ...base,
                    backgroundColor: 'white',
                  }),
                  option: (base, state) => ({
                    ...base,
                    backgroundColor: state.isSelected ? '#3b82f6' : state.isFocused ? '#eff6ff' : 'white',
                    color: state.isSelected ? 'white' : '#111827',
                  }),
                  singleValue: (base) => ({
                    ...base,
                    color: '#111827',
                  }),
                  placeholder: (base) => ({
                    ...base,
                    color: '#6b7280',
                  }),
                }}
              />
            </div>
            <button
              type="submit"
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Áp dụng
            </button>
            <button
              type="button"
              onClick={() => {
                setShowAdvanced(false);
                setFromYear('');
                setToYear('');
                setSelectedLanguage(null);
                const params = { ...Object.fromEntries(searchParams) };
                delete params.fromYear;
                delete params.toYear;
                delete params.language;
                setSearchParams(params);
              }}
              className="px-4 py-2 text-sm text-gray-600 hover:text-gray-800"
            >
              Ẩn tìm kiếm nâng cao
            </button>
          </div>
        </form>
      ) : (
        <p
          onClick={handleAdvancedChange}
          className="mb-6 cursor-pointer text-sm text-gray-500 hover:text-gray-700 border-b border-dashed border-gray-400 inline-block"
        >
          Tìm kiếm nâng cao
        </p>
      )}

      {/* Results count */}
      {isLoading ? (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mx-auto"></div>
          <p className="mt-4 text-gray-600">Đang tìm kiếm...</p>
        </div>
      ) : (
        <>
          <p className="text-gray-600 dark:text-gray-400 mb-4">
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
            <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-xl">
              <p className="text-gray-500 dark:text-gray-400 text-lg">
                Không tìm thấy sách phù hợp. Thử từ khóa khác?
              </p>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default Search;
