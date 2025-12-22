import { useNavigate, useParams } from "react-router-dom";
import bookDetails from "../data/book-details.json";
import SuggestedBooks from "../components/book/SuggestedBooks";
import {
  ArrowLeft,
  Download,
  Heart,
  Bookmark,
  MessageSquareMore,
  Play,
} from "lucide-react";
import { useState, useEffect, useCallback } from "react";
import AddToCollectionModal from "../components/collection/AddToCollectionModal";
import ReadingProgress, { getReadingProgress } from "../components/book/ReadingProgress";
import { useAuth } from "../context/AuthContext";
import { favoritesAPI, historyAPI } from "../services/api";

const STORAGE_KEY = "eshelf_collections";

const BookDetail = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { user, isAuthenticated } = useAuth();
  const book = bookDetails
    ? bookDetails.find((bookDetail) => bookDetail.isbn === id)
    : null;
  const [isHeartClicked, setIsHeartClicked] = useState(false);
  const [isBookmarkClicked, setIsBookmarkClicked] = useState(false);
  const [comments, setComments] = useState([]);
  const [showCollectionModal, setShowCollectionModal] = useState(false);
  const [collections, setCollections] = useState([]);
  const [isBookSaved, setIsBookSaved] = useState(false);
  const [readingProgress, setReadingProgress] = useState(null);
  const [isFavoriteLoading, setIsFavoriteLoading] = useState(false);
  const [isFavoriteReal, setIsFavoriteReal] = useState(false); // Favorite từ backend

  // Load collections cho user hiện tại
  useEffect(() => {
    if (!user?.id) {
      setCollections([]);
      setIsBookSaved(false);
      return;
    }

    const storageKey = `${STORAGE_KEY}_${user.id}`;
    const saved = localStorage.getItem(storageKey);
    
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        setCollections(parsed);

        if (book) {
          const bookId = book.isbn || book.id;
          const isSaved = parsed.some((c) =>
            c.books.some((b) => (b.isbn || b.id) === bookId)
          );
          setIsBookSaved(isSaved);
        }
      } catch (e) {
        console.error("Failed to parse collections:", e);
        setCollections([]);
      }
    } else if (user?.id) {
      const defaultCollections = [{
        id: "favorites",
        name: "Yêu thích",
        description: "Những cuốn sách bạn yêu thích",
        books: [],
        createdAt: new Date().toISOString(),
      }];
      const storageKey = `${STORAGE_KEY}_${user.id}`;
      localStorage.setItem(storageKey, JSON.stringify(defaultCollections));
      setCollections(defaultCollections);
    }
  }, [book, user?.id]);

  // Load reading progress
  useEffect(() => {
    if (book) {
      const progress = getReadingProgress(book.isbn);
      setReadingProgress(progress);
    }
  }, [book]);

  // Load favorite status từ backend khi component mount
  useEffect(() => {
    const checkFavoriteStatus = async () => {
      if (!isAuthenticated || !book) return;
      
      try {
        const result = await favoritesAPI.check(book.isbn);
        setIsFavoriteReal(result.data.isFavorite);
      } catch (error) {
        console.error('Check favorite error:', error);
      }
    };

    checkFavoriteStatus();
  }, [book, isAuthenticated]);

  const saveCollectionsToStorage = (data) => {
    if (!user?.id) return;
    const storageKey = `${STORAGE_KEY}_${user.id}`;
    localStorage.setItem(storageKey, JSON.stringify(data));
  };

  const handleAddToCollection = useCallback(
    (collectionId, bookData) => {
      if (!user?.id) {
        navigate('/login');
        return;
      }
      
      setCollections((prevCollections) => {
        const updated = prevCollections.map((c) => {
          if (c.id === collectionId) {
            const bookId = bookData.isbn || bookData.id;
            const bookExists = c.books.some((b) => (b.isbn || b.id) === bookId);
            if (!bookExists) {
              return { ...c, books: [...c.books, bookData] };
            }
          }
          return c;
        });
        saveCollectionsToStorage(updated);
        setIsBookSaved(true);
        return updated;
      });
      setShowCollectionModal(false);
    },
    [user?.id, navigate]
  );

  const handleCreateNewCollection = useCallback(
    (newCollection) => {
      setCollections((prevCollections) => {
        const updated = [...prevCollections, newCollection];
        localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        setIsBookSaved(true);
        return updated;
      });
      setShowCollectionModal(false);
    },
    [setShowCollectionModal]
  );

  const handleRemoveFromCollection = useCallback((collectionId, bookData) => {
    setCollections((prevCollections) => {
      const updated = prevCollections.map((c) => {
        if (c.id === collectionId) {
          const bookId = bookData.isbn || bookData.id;
          return { ...c, books: c.books.filter((b) => (b.isbn || b.id) !== bookId) };
        }
        return c;
      });
      localStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
      
      // Check if book is still in any collection
      const stillSaved = updated.some(c => 
        c.books.some(b => (b.isbn || b.id) === (bookData.isbn || bookData.id))
      );
      setIsBookSaved(stillSaved);
      
      return updated;
    });
  }, []);

  const openCollectionModal = useCallback(() => {
    setShowCollectionModal(true);
  }, []);

  const closeCollectionModal = useCallback(() => {
    setShowCollectionModal(false);
  }, []);

  // Tạo book object để truyền vào modal
  const currentBookData = book
    ? {
        id: book.id,
        isbn: book.isbn,
        title: book.title,
        author: book.author,
        cover: book.coverUrl || book.cover,
        coverUrl: book.coverUrl || book.cover,
      }
    : null;

  // Toggle favorite với backend
  const handleToggleFavoriteReal = async () => {
    if (!isAuthenticated) {
      navigate('/login');
      return;
    }

    if (!book) return;
    
    setIsFavoriteLoading(true);
    try {
      await favoritesAPI.toggle(book.isbn);
      setIsFavoriteReal(!isFavoriteReal);
      
      // Show toast
      if (!isFavoriteReal) {
        // Có thể thêm toast notification ở đây
        console.log('Added to favorites');
      } else {
        console.log('Removed from favorites');
      }
    } catch (error) {
      console.error('Toggle favorite error:', error);
      alert('Không thể cập nhật yêu thích. Vui lòng thử lại.');
    } finally {
      setIsFavoriteLoading(false);
    }
  };

  if (book) {
    return (
      <div className="px-8 md:px-20 lg:px-24">
        {/* Fix nút Quay lại */}
        <button 
          onClick={() => navigate(-1)}
          className="mb-4 flex cursor-pointer gap-1 text-gray-700 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400"
        >
          <ArrowLeft /> <span className="hover:underline">Quay Lại</span>
        </button>
        
        <div className="mb-20">
          <img
            className="float-left mr-8 h-96 w-64 rounded-sm object-cover drop-shadow-[0_0.2rem_0.2rem_rgba(0,0,0,0.5)]"
            src={book.coverUrl}
            alt=""
          />
          <p className="mb-1 text-2xl text-gray-800 dark:text-gray-100">{book.title}</p>
          <p className="mb-5 cursor-pointer text-sm text-sky-400">
            {book.author.map((au, index) => (
              <span key={index}>
                <a className="underline hover:text-sky-600 dark:text-sky-300 dark:hover:text-sky-200">{au}</a>
                {index !== book.author.length - 1 && ", "}
              </span>
            ))}
          </p>
          <div className="mb-5 flex gap-4">
            <p className="flex cursor-pointer gap-1 text-gray-500 hover:text-gray-600 hover:underline">
              <MessageSquareMore />{" "}
              {`${comments.length} comment${comments.length !== 1 && "s"}`}
            </p>
            {/* Replace Heart button với version mới */}
            <button
              onClick={handleToggleFavoriteReal}
              disabled={isFavoriteLoading || !isAuthenticated}
              className={`cursor-pointer transition-colors ${
                isFavoriteReal
                  ? "text-red-500"
                  : "text-gray-400 hover:text-gray-500"
              } ${isFavoriteLoading ? "opacity-50" : ""}`}
              title={isAuthenticated ? (isFavoriteReal ? "Xóa khỏi yêu thích" : "Thêm vào yêu thích") : "Đăng nhập để thêm yêu thích"}
            >
              <Heart
                className="w-6 h-6"
                fill={isFavoriteReal ? "currentColor" : "none"}
              />
            </button>
            <Bookmark
              onClick={() => setIsBookmarkClicked(!isBookmarkClicked)}
              className={`cursor-pointer ${
                isBookmarkClicked
                  ? "text-amber-400"
                  : "text-gray-400 hover:text-gray-500"
              }`}
              fill={isBookmarkClicked ? "#fbbf24" : "#f9fafb"}
            />
          </div>
          {book.description && (
            <p className="mb-5 text-sm text-gray-700 dark:text-gray-300">
              <span className="text-gray-500">Giới thiệu:</span>{" "}
              {book.description}
            </p>
          )}
          <div className="mb-5 grid grid-cols-2 gap-x-12 gap-y-2 text-sm text-gray-700 dark:text-gray-300">
            {book.genres.length > 0 && (
              <p className="cursor-pointer">
                <span className="text-gray-500 dark:text-gray-400">Thể loại:</span>{" "}
                {book.genres.join(", ")}
              </p>
            )}

            {book.language && (
              <p>
                <span className="text-gray-500 dark:text-gray-400">Ngôn ngữ:</span> {book.language}
              </p>
            )}
            {book.year && (
              <p>
                <span className="text-gray-500 dark:text-gray-400">Năm:</span> {book.year}
              </p>
            )}
            {book.publisher && (
              <p>
                <span className="text-gray-500 dark:text-gray-400">Nhà xuất bản:</span>{" "}
                {book.publisher}
              </p>
            )}

            {book.translator.length > 0 && (
              <p>
                <span className="text-gray-500 dark:text-gray-400">Người dịch:</span>{" "}
                {book.translator.join(", ")}
              </p>
            )}

            {book.isbn && (
              <p>
                <span className="text-gray-500 dark:text-gray-400">Mã:</span> {book.isbn}
              </p>
            )}
            {book.extension && book.size && (
              <p>
                <span className="text-gray-500 dark:text-gray-400">File:</span> {book.extension},{" "}
                {book.size}
              </p>
            )}
          </div>
          {/* Reading Progress - thêm sau book info, trước buttons */}
          <ReadingProgress book={book} progress={readingProgress} />
          <div className="flex gap-2">
            <button
              className="flex gap-1 rounded bg-sky-400 dark:bg-sky-500 px-5 py-2 text-white hover:bg-sky-300 dark:hover:bg-sky-400"
              onClick={() =>
                navigate(`/reading/${book.isbn}`, { state: book.pdfUrl })
              }
            >
              <Play />
              Đọc sách
            </button>

            {/* Nút Tải xuống - yêu cầu đăng nhập */}
            {isAuthenticated ? (
              <a
                href={book.pdfUrl}
                download={`${book.title}.pdf`}
                className="flex gap-1 rounded border border-gray-300 dark:border-gray-600 px-5 py-2 text-gray-600 dark:text-gray-300 hover:border-sky-400 hover:text-sky-500 transition-colors"
                onClick={(e) => {
                  if (!book.pdfUrl) {
                    e.preventDefault();
                    alert('Không tìm thấy file để tải xuống');
                  }
                }}
              >
                <Download />
                Tải xuống
              </a>
            ) : (
              <button
                onClick={() => navigate('/login')}
                className="flex gap-1 rounded border border-gray-300 dark:border-gray-600 px-5 py-2 text-gray-400 dark:text-gray-500 cursor-pointer hover:border-blue-400 hover:text-blue-500 transition-colors"
                title="Đăng nhập để tải xuống"
              >
                <Download />
                <span>Đăng nhập để tải</span>
              </button>
            )}

            <p
              className="cursor-pointer py-2 text-amber-400 underline hover:text-amber-500"
              onClick={() => navigate("/feedback")}
            >
              Báo cáo lỗi?
            </p>

            {/* Nút Lưu sách - chỉ hiện khi đăng nhập */}
            {isAuthenticated ? (
              <button
                onClick={() => setShowCollectionModal(true)}
                className={`flex items-center gap-2 px-4 py-2.5 rounded-lg transition-all shadow-md hover:shadow-lg ${
                  isBookSaved
                    ? "bg-green-500 text-white hover:bg-green-600"
                    : "bg-gradient-to-r from-blue-500 to-blue-600 text-white hover:from-blue-600 hover:to-blue-700"
                }`}
              >
                <svg
                  className="w-5 h-5"
                  fill={isBookSaved ? "currentColor" : "none"}
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                  />
                </svg>
                {isBookSaved ? "Đã lưu" : "Lưu sách"}
              </button>
            ) : (
              <button
                onClick={() => navigate('/login')}
                className="flex items-center gap-2 px-4 py-2.5 bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
                </svg>
                Đăng nhập để lưu
              </button>
            )}

            {/* Modal - thêm prop onRemove */}
            {showCollectionModal && currentBookData && (
              <AddToCollectionModal
                isOpen={showCollectionModal}
                onClose={() => setShowCollectionModal(false)}
                book={currentBookData}
                collections={collections}
                onAdd={handleAddToCollection}
                onCreateNew={handleCreateNewCollection}
                onRemove={handleRemoveFromCollection}
              />
            )}
          </div>
        </div>
        <SuggestedBooks
          heading="Bạn có thể sẽ thích"
          bookDetails={bookDetails}
          totalDisplayedBooks={24}
          chosenBookIsbn={id}
        />
      </div>
    );
  }
};

export default BookDetail;
