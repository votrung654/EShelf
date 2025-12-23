import { useState, useEffect } from 'react';
import { Link, useParams, useNavigate } from 'react-router-dom';
import { collectionsAPI, booksAPI } from '../services/api';

export default function CollectionDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [collection, setCollection] = useState(null);
  const [isEditing, setIsEditing] = useState(false);
  const [editName, setEditName] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const loadCollection = async () => {
      setIsLoading(true);
      try {
        const response = await collectionsAPI.getById(id);
        if (response.success && response.data) {
          const collectionData = response.data;
          
          // Backend chỉ trả về bookId array, cần fetch book details
          if (collectionData.books && collectionData.books.length > 0) {
            const bookDetails = await Promise.all(
              collectionData.books.map(async (bookId) => {
                try {
                  const bookResponse = await booksAPI.getById(bookId);
                  if (bookResponse.success && bookResponse.data) {
                    return bookResponse.data;
                  }
                  return null;
                } catch (error) {
                  console.error('Error fetching book:', error);
                  return null;
                }
              })
            );
            
            // Filter out null values và update collection với book objects
            collectionData.books = bookDetails.filter(Boolean);
          }
          
          setCollection(collectionData);
          setEditName(collectionData.name);
        } else {
          navigate('/collections');
        }
      } catch (error) {
        console.error('Error loading collection:', error);
        navigate('/collections');
      } finally {
        setIsLoading(false);
      }
    };

    if (id) {
      loadCollection();
    }
  }, [id, navigate]);

  const handleRemoveBook = async (bookIdentifier) => {
    if (!collection) return;
    
    try {
      const response = await collectionsAPI.removeBook(collection.id, bookIdentifier);
      if (response.success) {
        // Reload collection
        const reloadResponse = await collectionsAPI.getById(id);
        if (reloadResponse.success && reloadResponse.data) {
          setCollection(reloadResponse.data);
        }
      }
    } catch (error) {
      console.error('Error removing book:', error);
      alert('Không thể xóa sách khỏi bộ sưu tập. Vui lòng thử lại.');
    }
  };

  const handleRename = async () => {
    if (!editName.trim() || !collection) return;
    
    try {
      const response = await collectionsAPI.update(collection.id, {
        name: editName.trim(),
        description: collection.description,
        isPublic: collection.isPublic,
      });
      
      if (response.success) {
        // Reload collection
        const reloadResponse = await collectionsAPI.getById(id);
        if (reloadResponse.success && reloadResponse.data) {
          setCollection(reloadResponse.data);
          setEditName(reloadResponse.data.name);
        }
        setIsEditing(false);
      }
    } catch (error) {
      console.error('Error renaming collection:', error);
      alert('Không thể đổi tên bộ sưu tập. Vui lòng thử lại.');
    }
  };

  if (isLoading || !collection) {
    return (
      <main className="flex-1 flex items-center justify-center">
        <div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full" />
      </main>
    );
  }

  return (
    <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
      {/* Breadcrumb */}
      <nav className="mb-6">
        <ol className="flex items-center space-x-2 text-sm">
          <li>
            <Link to="/" className="text-blue-600 dark:text-blue-400 hover:underline">Trang chủ</Link>
          </li>
          <li className="text-gray-400 dark:text-gray-500">/</li>
          <li>
            <Link to="/collections" className="text-blue-600 dark:text-blue-400 hover:underline">Bộ sưu tập</Link>
          </li>
          <li className="text-gray-400 dark:text-gray-500">/</li>
          <li className="text-gray-600 dark:text-gray-400">{collection.name}</li>
        </ol>
      </nav>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
        <div className="flex items-center gap-3">
          {collection.id === 'favorites' ? (
            <div className="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center">
              <svg className="w-6 h-6 text-red-500" fill="currentColor" viewBox="0 0 24 24">
                <path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
            </div>
          ) : (
            <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
              <svg className="w-6 h-6 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
              </svg>
            </div>
          )}
          <div>
            {isEditing && collection.id !== 'favorites' ? (
              <div className="flex items-center gap-2">
                <input
                  type="text"
                  value={editName}
                  onChange={(e) => setEditName(e.target.value)}
                  className="px-3 py-1 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-gray-700 dark:text-gray-100"
                  autoFocus
                  onKeyDown={(e) => e.key === 'Enter' && handleRename()}
                />
                <button onClick={handleRename} className="p-2 text-green-600 dark:text-green-400 hover:bg-green-50 dark:hover:bg-green-900/20 rounded-lg">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </button>
                <button onClick={() => setIsEditing(false)} className="p-2 text-gray-400 dark:text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg">
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            ) : (
              <div className="flex items-center gap-2">
                <h1 className="text-2xl font-bold text-gray-800 dark:text-gray-100">{collection.name}</h1>
                {collection.id !== 'favorites' && (
                  <button
                    onClick={() => setIsEditing(true)}
                    className="p-2 text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                    </svg>
                  </button>
                )}
              </div>
            )}
            <p className="text-gray-500 dark:text-gray-400">{collection.books.length} sách</p>
          </div>
        </div>
      </div>

      {/* Books Grid */}
      {collection.books.length > 0 ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-6">
          {collection.books.map((book, index) => (
            <div key={book.id || book.isbn || index} className="group relative">
              <Link to={`/book/${book.id || book.isbn}`} className="block">
                <div className="aspect-[2/3] rounded-lg overflow-hidden shadow-md group-hover:shadow-xl transition-shadow">
                  <img
                    src={book.cover || book.coverUrl || '/images/book-covers/default.jpg'}
                    alt={book.title}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    onError={(e) => {
                      e.target.src = '/images/book-placeholder.svg';
                    }}
                  />
                </div>
                <h3 className="mt-2 font-medium text-gray-800 dark:text-gray-100 text-sm line-clamp-2 group-hover:text-blue-600 dark:group-hover:text-blue-400">
                  {book.title}
                </h3>
                <p className="text-xs text-gray-500 dark:text-gray-400">{book.author}</p>
              </Link>
              
              {/* Remove button */}
              <button
                onClick={() => handleRemoveBook(book.id || book.isbn)}
                className="absolute top-2 right-2 p-2 bg-white/90 dark:bg-gray-800/90 hover:bg-red-500 hover:text-white rounded-full shadow-md opacity-0 group-hover:opacity-100 transition-all"
                title="Xóa khỏi bộ sưu tập"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          ))}
        </div>
      ) : (
        <div className="text-center py-16 bg-gray-50 dark:bg-gray-800 rounded-xl">
          <div className="w-20 h-20 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-10 h-10 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-800 dark:text-gray-100 mb-2">Chưa có sách nào</h3>
          <p className="text-gray-500 dark:text-gray-400 mb-4">Thêm sách vào bộ sưu tập từ trang chi tiết sách</p>
          <Link
            to="/"
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Khám phá sách
          </Link>
        </div>
      )}
    </main>
  );
}
