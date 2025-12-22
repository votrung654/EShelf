import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { booksAPI, mlAPI } from "../services/api";
import SearchForm from "../components/book/SearchForm.jsx";
import SuggestedBooks from "../components/book/SuggestedBooks.jsx";
import Logo from "../components/common/Logo.jsx";
import Quote from "../components/common/Quote.jsx";
import bookDetails from "../data/book-details.json";

const HomePage = () => {
  const { user, isAuthenticated } = useAuth();
  const [mlRecommendations, setMlRecommendations] = useState([]);
  const [selectedGenre, setSelectedGenre] = useState("all");
  const [filteredBooks, setFilteredBooks] = useState(bookDetails);
  const [isLoadingRecs, setIsLoadingRecs] = useState(false);

  // Load ML recommendations nếu user đã login
  useEffect(() => {
    const loadRecommendations = async () => {
      if (!isAuthenticated || !user?.id) return;

      setIsLoadingRecs(true);
      try {
        const result = await mlAPI.getRecommendations(user.id, 10);
        if (result.success && result.data) {
          setMlRecommendations(result.data);
        }
      } catch (error) {
        console.error("Load recommendations error:", error);
      } finally {
        setIsLoadingRecs(false);
      }
    };

    loadRecommendations();
  }, [isAuthenticated, user]);

  // Filter books by genre
  useEffect(() => {
    if (selectedGenre === "all") {
      setFilteredBooks(bookDetails);
    } else {
      const filtered = bookDetails.filter((book) =>
        book.genres && book.genres.includes(selectedGenre)
      );
      setFilteredBooks(filtered);
    }
  }, [selectedGenre]);

  // Get unique genres
  const genres = [
    "all",
    ...new Set(bookDetails.flatMap((book) => book.genres || [])),
  ];

  return (
    <>
      <div className="mt-12 md:mt-20 lg:mt-24">
        <Logo fontSize="text-7xl" />
        <Quote />
      </div>
      <SearchForm />

      <div className="mx-4 mt-16 md:mx-24 lg:mx-44">
        {/* ML Recommendations Section - chỉ hiển thị khi đã login */}
        {isAuthenticated && mlRecommendations.length > 0 && (
          <div className="mb-12">
            <div className="flex items-center gap-3 mb-6">
              <span className="text-3xl">✨</span>
              <h2 className="text-2xl font-bold text-gray-800 dark:text-gray-100">
                Gợi ý dành cho bạn (AI)
              </h2>
            </div>
            <SuggestedBooks
              heading=""
              bookDetails={mlRecommendations}
              totalDisplayedBooks={10}
              showHeading={false}
            />
          </div>
        )}

        {/* Genre Filter */}
        <div className="mb-6 flex items-center gap-4">
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
        <SuggestedBooks
          heading="Tủ sách gợi ý"
          bookDetails={filteredBooks}
          totalDisplayedBooks={180}
        />
      </div>
    </>
  );
};

export default HomePage;
