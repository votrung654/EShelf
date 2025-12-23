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
import { favoritesAPI, historyAPI, collectionsAPI } from "../services/api";

const STORAGE_KEY = "eshelf_collections";

const BookDetail = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { user, isAuthenticated } = useAuth();
  
  // State để lưu book data (có thể từ local JSON hoặc API)
  const [book, setBook] = useState(null);
  const [isLoadingBook, setIsLoadingBook] = useState(true);
  
  const [isHeartClicked, setIsHeartClicked] = useState(false);
  const [isBookmarkClicked, setIsBookmarkClicked] = useState(false);
  const [comments, setComments] = useState([]);
  const [showCollectionModal, setShowCollectionModal] = useState(false);
  const [collections, setCollections] = useState([]);
  const [isBookSaved, setIsBookSaved] = useState(false);
  const [readingProgress, setReadingProgress] = useState(null);
  const [isFavoriteLoading, setIsFavoriteLoading] = useState(false);
  const [isFavoriteReal, setIsFavoriteReal] = useState(false); // Favorite từ backend

  // Load book data - thử local JSON trước, nếu không có thì fetch từ API
  useEffect(() => {
    const loadBook = async () => {
      setIsLoadingBook(true);
      
      // Thử tìm trong local JSON trước (nếu id là ISBN)
      const localBook = bookDetails
        ? bookDetails.find((bookDetail) => bookDetail.isbn === id)
        : null;
      
      if (localBook) {
        setBook(localBook);
        setIsLoadingBook(false);
        return;
      }
      
      // Nếu không tìm thấy trong local JSON, fetch từ API (có thể là UUID hoặc ISBN)
      try {
        const { booksAPI } = await import('../services/api');
        const bookResponse = await booksAPI.getById(id);
        if (bookResponse.success && bookResponse.data) {
          setBook({
            ...bookResponse.data,
            // Đảm bảo có các field cần thiết
            author: bookResponse.data.authors || bookResponse.data.author || [],
            coverUrl: bookResponse.data.coverUrl || bookResponse.data.cover,
            cover: bookResponse.data.coverUrl || bookResponse.data.cover,
          });
        } else {
          setBook(null);
        }
      } catch (error) {
        console.error('Error fetching book from API:', error);
        setBook(null);
      } finally {
        setIsLoadingBook(false);
      }
    };
    
    if (id) {
      loadBook();
    }
  }, [id]);

  // Load collections từ API
  useEffect(() => {
    const loadCollections = async () => {
      if (!user?.id || !isAuthenticated) {
        setCollections([]);
        setIsBookSaved(false);
        return;
      }

      try {
        const response = await collectionsAPI.getAll();
        if (response.success && response.data) {
          setCollections(response.data);

          // Check if book is in any collection
          // Backend trả về books là array của UUIDs, nên cần fetch book từ backend để lấy UUID
          if (book) {
            let bookUUID = book.id;
            // Nếu chưa có UUID, fetch từ backend
            if (!bookUUID && book.isbn) {
              try {
                const { booksAPI } = await import('../services/api');
                const bookResponse = await booksAPI.getById(book.isbn);
                if (bookResponse.success && bookResponse.data) {
                  bookUUID = bookResponse.data.id;
                }
              } catch (fetchError) {
                console.error('Error fetching book UUID:', fetchError);
              }
            }
            
            const isSaved = response.data.some((c) => {
              if (!c.books || !Array.isArray(c.books)) return false;
              return c.books.some(b => {
                if (typeof b === 'string') {
                  // Backend trả về UUID, nên check với bookUUID trước
                  return b === bookUUID || b === book.isbn || b === book.id;
                }
                return (b.id || b.isbn) === bookUUID || (b.id || b.isbn) === book.isbn || (b.id || b.isbn) === book.id;
              });
            });
            setIsBookSaved(isSaved);
          }
        } else {
          setCollections([]);
        }
      } catch (error) {
        console.error("Failed to load collections:", error);
        setCollections([]);
      }
    };

    loadCollections();
  }, [book, user?.id, isAuthenticated]);

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
        const bookId = book.id || book.isbn;
        if (!bookId) return;
        
        const result = await favoritesAPI.check(bookId);
        if (result && result.success) {
          setIsFavoriteReal(result.data.isFavorite);
        }
      } catch (error) {
        console.error('Check favorite error:', error);
        // Không set state nếu có lỗi, để tránh hiển thị sai
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
    async (collectionId, bookData) => {
      if (!user?.id || !isAuthenticated) {
        navigate('/login');
        return;
      }
      
      // Helper function để reload collections và update state
      const reloadCollectionsAndUpdateState = async (bookIdForFallback) => {
        console.log('Reloading collections and updating state...');
        try {
          const reloadResponse = await collectionsAPI.getAll();
          console.log('Reload response:', reloadResponse);
          if (reloadResponse.success && reloadResponse.data) {
            console.log('Collections reloaded:', reloadResponse.data);
            setCollections(reloadResponse.data);
            // Check lại xem book có trong collection không
            // Backend trả về books là array của UUIDs, nên cần dùng book.id (UUID) để check
            // Nếu book.id chưa có (chỉ có isbn), cần fetch book từ backend để lấy UUID
            let bookUUID = book?.id;
            if (!bookUUID && book?.isbn) {
              // Nếu chưa có UUID, fetch từ backend
              try {
                const { booksAPI } = await import('../services/api');
                const bookResponse = await booksAPI.getById(book.isbn);
                if (bookResponse.success && bookResponse.data) {
                  bookUUID = bookResponse.data.id;
                  console.log('Fetched book UUID:', bookUUID, 'from ISBN:', book.isbn);
                }
              } catch (fetchError) {
                console.error('Error fetching book UUID:', fetchError);
              }
            }
            
            const currentBookId = bookUUID || book?.id || book?.isbn;
            const currentIsbn = book?.isbn;
            console.log('Checking if book is saved. bookUUID:', bookUUID, 'currentBookId:', currentBookId, 'currentIsbn:', currentIsbn);
            console.log('Collections to check:', reloadResponse.data.map(c => ({ id: c.id, name: c.name, books: c.books })));
            
            const isSaved = reloadResponse.data.some((c) => {
              if (!c.books || !Array.isArray(c.books)) {
                console.log(`Collection ${c.id} has no books array`);
                return false;
              }
              console.log(`Checking collection ${c.id}, books:`, c.books);
              const found = c.books.some(b => {
                if (typeof b === 'string') {
                  // Backend trả về UUID, nên check với bookUUID trước
                  const match = b === bookUUID || b === currentBookId || b === currentIsbn || b === book?.isbn || b === book?.id;
                  if (match) console.log(`Found match in collection ${c.id}: string bookId "${b}" matches bookUUID "${bookUUID}" or currentBookId "${currentBookId}"`);
                  return match;
                }
                const match = (b.id || b.isbn) === bookUUID || (b.id || b.isbn) === currentBookId || (b.id || b.isbn) === currentIsbn || (b.id || b.isbn) === book?.isbn || (b.id || b.isbn) === book?.id;
                if (match) console.log(`Found match in collection ${c.id}: object book`, b);
                return match;
              });
              if (found) console.log(`Book found in collection ${c.id}`);
              return found;
            });
            console.log('Final isBookSaved:', isSaved);
            setIsBookSaved(isSaved);
            // KHÔNG đóng modal ngay, để user thấy nút đã chuyển thành "Xóa"
            // Modal sẽ tự đóng khi collections state update và re-render
          } else {
            console.log('Reload failed, using fallback');
            // Fallback nếu reload thất bại
            setIsBookSaved(true);
            setShowCollectionModal(false);
          }
        } catch (reloadError) {
          console.error('Error reloading collections:', reloadError);
          // Fallback: update local state
          const updatedCollections = collections.map(c => {
            if (c.id === collectionId) {
              return {
                ...c,
                books: Array.isArray(c.books) ? [...c.books, bookIdForFallback] : [bookIdForFallback],
                bookCount: (c.bookCount || c.books?.length || 0) + 1
              };
            }
            return c;
          });
          setCollections(updatedCollections);
          // Update isBookSaved based on updated collections
          const currentBookId = book?.id || book?.isbn;
          const isSaved = updatedCollections.some((c) => {
            if (!c.books || !Array.isArray(c.books)) return false;
            return c.books.some(b => {
              if (typeof b === 'string') {
                return b === currentBookId || b === book?.isbn || b === book?.id;
              }
              return (b.id || b.isbn) === currentBookId;
            });
          });
          setIsBookSaved(isSaved);
          setShowCollectionModal(false);
        }
      };
      
      try {
        const bookId = bookData.id || bookData.isbn;
        const response = await collectionsAPI.addBook(collectionId, bookId);
        
        if (response.success) {
          // Reload collections từ backend để có data chính xác TRƯỚC KHI đóng modal
          await reloadCollectionsAndUpdateState(bookId);
        }
      } catch (error) {
        console.error('Error adding book to collection:', error);
        console.log('Error response:', error.response?.data);
        // Nếu lỗi 400 và message là "đã có trong bộ sưu tập", xử lý như success
        const errorMessage = error.response?.data?.message || '';
        if (error.response?.status === 400 && (errorMessage.includes('đã có') || errorMessage.includes('Sách đã có'))) {
          // Reload collections và update state
          console.log('Book already in collection, reloading...');
          await reloadCollectionsAndUpdateState(bookData.id || bookData.isbn);
        } else {
          const errorMsg = error.response?.data?.message || error.message || 'Không thể thêm sách vào bộ sưu tập. Vui lòng thử lại.';
          alert(errorMsg);
        }
      }
    },
    [user?.id, isAuthenticated, navigate, collections, book]
  );

  const handleCreateNewCollection = useCallback(
    async (newCollection) => {
      if (!user?.id || !isAuthenticated) {
        navigate('/login');
        return;
      }
      
      try {
        const response = await collectionsAPI.create({
          name: newCollection.name,
          description: newCollection.description || '',
          isPublic: false,
        });
        
        if (response && response.success && response.data) {
          const createdCollection = response.data;
          const bookId = book?.id || book?.isbn;
          
          if (bookId) {
            try {
              await collectionsAPI.addBook(createdCollection.id, bookId);
            } catch (addError) {
              console.error('Error adding book to new collection:', addError);
              // Vẫn tiếp tục dù có lỗi add book
            }
          }
          
          // Reload collections từ backend để có data chính xác
          try {
            const reloadResponse = await collectionsAPI.getAll();
            if (reloadResponse.success && reloadResponse.data) {
              setCollections(reloadResponse.data);
              // Check lại xem book có trong collection không (check cả isbn và id)
              const currentBookId = book?.id || book?.isbn;
              const isSaved = reloadResponse.data.some((c) => {
                if (!c.books || !Array.isArray(c.books)) return false;
                return c.books.some(b => {
                  if (typeof b === 'string') {
                    return b === currentBookId || b === book?.isbn || b === book?.id;
                  }
                  return (b.id || b.isbn) === currentBookId || (b.id || b.isbn) === book?.isbn || (b.id || b.isbn) === book?.id;
                });
              });
              setIsBookSaved(isSaved);
            } else {
              // Fallback
              setCollections(prev => [...prev, createdCollection]);
              setIsBookSaved(true);
            }
          } catch (reloadError) {
            console.error('Error reloading collections:', reloadError);
            // Fallback
            setCollections(prev => [...prev, createdCollection]);
            setIsBookSaved(true);
          }
          
          setShowCollectionModal(false);
        } else {
          console.error('Create collection failed:', response);
          alert(response?.message || 'Không thể tạo bộ sưu tập. Vui lòng thử lại.');
        }
      } catch (error) {
        console.error('Error creating collection:', error);
        const errorMessage = error.response?.data?.message || error.message || 'Không thể tạo bộ sưu tập. Vui lòng thử lại.';
        alert(errorMessage);
      }
    },
    [user?.id, isAuthenticated, navigate, book]
  );

  const handleRemoveFromCollection = useCallback(async (collectionId, bookData) => {
    if (!user?.id || !isAuthenticated) return;
    
    try {
      const bookId = bookData.id || bookData.isbn;
      const response = await collectionsAPI.removeBook(collectionId, bookId);
      
      if (response.success) {
        // Reload collections từ backend để có data chính xác
        try {
          const reloadResponse = await collectionsAPI.getAll();
          if (reloadResponse.success && reloadResponse.data) {
            setCollections(reloadResponse.data);
            // Check lại xem book có còn trong collection không
            const currentBookId = book?.id || book?.isbn;
            const stillSaved = reloadResponse.data.some((c) => {
              if (!c.books || !Array.isArray(c.books)) return false;
              return c.books.some(b => {
                if (typeof b === 'string') {
                  return b === currentBookId || b === book?.isbn || b === book?.id;
                }
                return (b.id || b.isbn) === currentBookId || (b.id || b.isbn) === book?.isbn || (b.id || b.isbn) === book?.id;
              });
            });
            setIsBookSaved(stillSaved);
          } else {
            // Fallback
            const updatedCollections = collections.map(c => {
              if (c.id === collectionId) {
                return {
                  ...c,
                  books: Array.isArray(c.books) ? c.books.filter(b => {
                    if (typeof b === 'string') return b !== bookId;
                    return (b.id || b.isbn) !== bookId;
                  }) : [],
                  bookCount: Math.max(0, (c.bookCount || c.books?.length || 0) - 1)
                };
              }
              return c;
            });
            setCollections(updatedCollections);
            const stillSaved = updatedCollections.some(c => {
              if (Array.isArray(c.books)) {
                return c.books.some(b => {
                  if (typeof b === 'string') return b === bookId;
                  return (b.id || b.isbn) === bookId;
                });
              }
              return false;
            });
            setIsBookSaved(stillSaved);
          }
        } catch (reloadError) {
          console.error('Error reloading collections:', reloadError);
          // Fallback
          const updatedCollections = collections.map(c => {
            if (c.id === collectionId) {
              return {
                ...c,
                books: Array.isArray(c.books) ? c.books.filter(b => {
                  if (typeof b === 'string') return b !== bookId;
                  return (b.id || b.isbn) !== bookId;
                }) : [],
                bookCount: Math.max(0, (c.bookCount || c.books?.length || 0) - 1)
              };
            }
            return c;
          });
          setCollections(updatedCollections);
          const stillSaved = updatedCollections.some(c => {
            if (Array.isArray(c.books)) {
              return c.books.some(b => {
                if (typeof b === 'string') return b === bookId;
                return (b.id || b.isbn) === bookId;
              });
            }
            return false;
          });
          setIsBookSaved(stillSaved);
        }
      }
    } catch (error) {
      console.error('Error removing book from collection:', error);
      alert('Không thể xóa sách khỏi bộ sưu tập. Vui lòng thử lại.');
    }
  }, [user?.id, isAuthenticated, collections, book]);

  const openCollectionModal = useCallback(() => {
    setShowCollectionModal(true);
  }, []);

  const closeCollectionModal = useCallback(() => {
    setShowCollectionModal(false);
  }, []);

  // Tạo currentBookData từ book state (đã được load từ local JSON hoặc API)
  const currentBookData = book
    ? {
        id: book.id,
        isbn: book.isbn,
        title: book.title,
        author: Array.isArray(book.author) ? book.author : (book.authors || []),
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
    
    const bookId = book.id || book.isbn;
    if (!bookId) {
      console.error('Book ID is missing');
      alert('Không thể xác định sách. Vui lòng thử lại.');
      return;
    }
    
    setIsFavoriteLoading(true);
    try {
      if (isFavoriteReal) {
        const response = await favoritesAPI.remove(bookId);
        if (response && response.success) {
          setIsFavoriteReal(false);
        } else {
          throw new Error(response?.message || 'Không thể xóa khỏi yêu thích');
        }
      } else {
        const response = await favoritesAPI.add(bookId);
        if (response && response.success) {
          setIsFavoriteReal(true);
        } else {
          // Nếu sách đã có trong yêu thích (400), coi như thành công
          if (response?.status === 400 || response?.message?.includes('đã có')) {
            setIsFavoriteReal(true);
          } else {
            throw new Error(response?.message || 'Không thể thêm vào yêu thích');
          }
        }
      }
    } catch (error) {
      console.error('Toggle favorite error:', error);
      const errorMessage = error.response?.data?.message || error.message || 'Không thể cập nhật yêu thích. Vui lòng thử lại.';
      alert(errorMessage);
    } finally {
      setIsFavoriteLoading(false);
    }
  };

  // Loading state
  if (isLoadingBook) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  // Not found state
  if (!book) {
    return (
      <div className="px-8 md:px-20 lg:px-24">
        <div className="flex flex-col items-center justify-center min-h-screen">
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">Không tìm thấy sách</h1>
          <button
            onClick={() => navigate(-1)}
            className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600"
          >
            Quay lại
          </button>
        </div>
      </div>
    );
  }

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
            {(Array.isArray(book.author) ? book.author : (book.authors || [])).map((au, index, arr) => (
              <span key={index}>
                <a className="underline hover:text-sky-600 dark:text-sky-300 dark:hover:text-sky-200">{au}</a>
                {index !== arr.length - 1 && ", "}
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
            {book.genres && Array.isArray(book.genres) && book.genres.length > 0 && (
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

            {book.translator && Array.isArray(book.translator) && book.translator.length > 0 && (
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
                key={`modal-${collections.length}-${isBookSaved}-${currentBookData.id || currentBookData.isbn}-${JSON.stringify(collections.map(c => ({ id: c.id, books: c.books })))}`} // Force re-render when collections or isBookSaved change
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
