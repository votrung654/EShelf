import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { booksAPI, mlAPI, genresAPI } from "../services/api"; // Import API thật
import SearchForm from "../components/book/SearchForm.jsx";
import SuggestedBooks from "../components/book/SuggestedBooks.jsx";
import Logo from "../components/common/Logo.jsx";
import Quote from "../components/common/Quote.jsx";

const HomePage = () => {
  const { user, isAuthenticated } = useAuth();
  
  // State chứa dữ liệu thật
  const [books, setBooks] = useState([]); 
  const [mlRecommendations, setMlRecommendations] = useState([]);
  const [genres, setGenres] = useState(["all"]);
  
  // State xử lý UI
  const [selectedGenre, setSelectedGenre] = useState("all");
  const [isLoading, setIsLoading] = useState(true);

  // 1. Load tất cả sách từ Backend khi vào trang
  useEffect(() => {
    const fetchInitialData = async () => {
      setIsLoading(true);
      try {
        // Gọi song song: Lấy sách và Lấy danh sách thể loại
        const [booksRes, genresRes] = await Promise.all([
            booksAPI.getAll(1, 50), // Lấy 50 cuốn đầu tiên
            genresAPI.getAll()
        ]);

        if (booksRes.success) {
            setBooks(booksRes.data.books || []);
        }

        if (genresRes.success) {
            const genreNames = genresRes.data.map(g => g.name || g);
            setGenres(["all", ...genreNames]);
        }
      } catch (error) {
        console.error("Lỗi tải trang chủ:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchInitialData();
  }, []);

  // 2. Load ML Recommendations (Chỉ khi đã login)
  useEffect(() => {
    const loadRecommendations = async () => {
      if (!isAuthenticated || !user?.id) return;

      try {
        // Gọi sang ML Service (Port 8000 qua Gateway)
        const result = await mlAPI.getRecommendations(user.id, 10);
        if (result.success && Array.isArray(result.data)) {
          setMlRecommendations(result.data);
        }
      } catch (error) {
        console.error("ML Error:", error);
      }
    };

    loadRecommendations();
  }, [isAuthenticated, user]);

  // 3. Xử lý lọc Client-side (Vì số lượng ít, lọc luôn trên RAM cho nhanh)
  const getFilteredBooks = () => {
    if (selectedGenre === "all") return books;
    return books.filter((book) => {
        // Kiểm tra logic genre tùy vào cấu trúc data backend trả về
        if (!book.genres) return false;
        return book.genres.some(g => (typeof g === 'string' ? g : g.name) === selectedGenre);
    });
  };

  const filteredBooks = getFilteredBooks();

  return (
    <>
      <div className="mt-12 md:mt-20 lg:mt-24">
        <Logo fontSize="text-7xl" />
        <Quote />
      </div>
      <SearchForm />

      <div className="mx-4 mt-16 md:mx-24 lg:mx-44">
        
        {/* Loading State */}
        {isLoading && (
            <div className="text-center py-10">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent"></div>
                <p className="mt-2 text-gray-500">Đang kết nối thư viện...</p>
            </div>
        )}

        {/* ML Recommendations Section */}
        {!isLoading && isAuthenticated && mlRecommendations.length > 0 && (
          <div className="mb-12">
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-gray-800 dark:text-gray-100">
                Gợi ý dành cho bạn (AI)
              </h2>
            </div>
            <SuggestedBooks
              heading=""
              bookDetails={mlRecommendations}
              totalDisplayedBooks={10}
              showHeading={false}
              isML={true} // Truyền prop để BookCard hiện badge
            />
          </div>
        )}

        {/* Main Book List */}
        {!isLoading && (
            <>
                {/* Genre Filter */}
                <div className="mb-6 flex items-center gap-4 flex-wrap">
                <label className="text-gray-700 dark:text-gray-300 font-medium">
                    Lọc theo thể loại:
                </label>
                <select
                    value={selectedGenre}
                    onChange={(e) => setSelectedGenre(e.target.value)}
                    className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-800 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                    {genres.map((genre) => (
                    <option key={genre} value={genre}>
                        {genre === "all" ? "Tất cả thể loại" : genre}
                    </option>
                    ))}
                </select>
                {selectedGenre !== "all" && (
                    <span className="text-sm text-gray-600 dark:text-gray-400">
                    ({filteredBooks.length} cuốn sách)
                    </span>
                )}
                </div>

                {/* Books Grid */}
                {filteredBooks.length > 0 ? (
                    <SuggestedBooks
                    heading="Tủ sách hiện có"
                    bookDetails={filteredBooks}
                    totalDisplayedBooks={50}
                    />
                ) : (
                    <div className="text-center py-10 text-gray-500 bg-gray-50 dark:bg-gray-800 rounded-lg">
                        Không tìm thấy cuốn sách nào thuộc thể loại này.
                    </div>
                )}
            </>
        )}
      </div>
    </>
  );
};

export default HomePage;