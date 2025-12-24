import { useState, useEffect, useMemo } from 'react';
import { Search, Plus, Edit2, Trash2, ChevronLeft, ChevronRight } from 'lucide-react';
import { booksAPI, genresAPI } from '../../services/api';
import AddBookModal from '../components/AddBookModal';
import EditBookModal from '../components/EditBookModal';
import DeleteConfirmModal from '../components/DeleteConfirmModal';
import Toast from '../components/Toast';

const ITEMS_PER_PAGE = 10;

export default function AdminBooks() {
  const [books, setBooks] = useState([]);
  const [allGenres, setAllGenres] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [selectedGenre, setSelectedGenre] = useState('all');
  const [isLoading, setIsLoading] = useState(true);
  
  // Modal states
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedBook, setSelectedBook] = useState(null);
  
  // Toast state
  const [toast, setToast] = useState({ show: false, message: '', type: 'success' });

  // Load books and genres from API
  useEffect(() => {
    const loadData = async () => {
      setIsLoading(true);
      try {
        const [booksRes, genresRes] = await Promise.all([
          booksAPI.getAll(1, 1000), // Get all books for admin
          genresAPI.getAll()
        ]);

        if (booksRes.success && booksRes.data) {
          setBooks(booksRes.data.books || []);
        }

        if (genresRes.success && genresRes.data) {
          setAllGenres(genresRes.data.map(g => g.name || g));
        }
      } catch (error) {
        console.error('Error loading books:', error);
        showToast('Không thể tải danh sách sách', 'error');
      } finally {
        setIsLoading(false);
      }
    };

    loadData();
  }, []);

  // Get unique genres from books (for filtering)
  const genres = useMemo(() => {
    const bookGenres = books.flatMap(book => {
      if (Array.isArray(book.genres)) {
        return book.genres.map(g => typeof g === 'string' ? g : g.name);
      }
      return [];
    });
    return [...new Set(bookGenres)].sort();
  }, [books]);

  // Filtered and paginated books
  const filteredBooks = useMemo(() => {
    return books.filter(book => {
      const authorsStr = Array.isArray(book.authors) ? book.authors.join(', ') : (book.author || '');
      const matchesSearch = 
        book.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        authorsStr.toLowerCase().includes(searchTerm.toLowerCase()) ||
        book.isbn?.includes(searchTerm);
      
      let matchesGenre = true;
      if (selectedGenre !== 'all') {
        if (Array.isArray(book.genres)) {
          matchesGenre = book.genres.some(g => {
            const genreName = typeof g === 'string' ? g : g.name;
            return genreName === selectedGenre;
          });
        } else {
          matchesGenre = false;
        }
      }
      
      return matchesSearch && matchesGenre;
    });
  }, [books, searchTerm, selectedGenre]);

  const totalPages = Math.ceil(filteredBooks.length / ITEMS_PER_PAGE);
  
  const paginatedBooks = useMemo(() => {
    const start = (currentPage - 1) * ITEMS_PER_PAGE;
    return filteredBooks.slice(start, start + ITEMS_PER_PAGE);
  }, [filteredBooks, currentPage]);

  // Reset page when filter changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, selectedGenre]);

  const showToast = (message, type = 'success') => {
    setToast({ show: true, message, type });
    setTimeout(() => setToast({ show: false, message: '', type: 'success' }), 3000);
  };

  const handleAddBook = async (newBook) => {
    try {
      const bookData = {
        title: newBook.title,
        author: Array.isArray(newBook.author) ? newBook.author : [newBook.author],
        authors: Array.isArray(newBook.author) ? newBook.author : [newBook.author],
        isbn: newBook.isbn,
        description: newBook.description,
        publisher: newBook.publisher,
        coverUrl: newBook.coverUrl,
        publishedYear: newBook.year || newBook.publishedYear,
        pageCount: newBook.pages || newBook.pageCount,
        language: newBook.language || 'vi',
        genreIds: newBook.genreIds || []
      };

      const response = await booksAPI.create(bookData);
      if (response.success) {
        // Reload books
        const booksRes = await booksAPI.getAll(1, 1000);
        if (booksRes.success && booksRes.data) {
          setBooks(booksRes.data.books || []);
        }
        setShowAddModal(false);
        showToast('Thêm sách thành công!');
      }
    } catch (error) {
      console.error('Error adding book:', error);
      showToast(error.response?.data?.message || 'Không thể thêm sách', 'error');
    }
  };

  const handleEditBook = async (updatedBook) => {
    try {
      const bookId = updatedBook.id || updatedBook.isbn;
      const bookData = {
        title: updatedBook.title,
        description: updatedBook.description,
        coverUrl: updatedBook.coverUrl
      };

      const response = await booksAPI.update(bookId, bookData);
      if (response.success) {
        // Reload books
        const booksRes = await booksAPI.getAll(1, 1000);
        if (booksRes.success && booksRes.data) {
          setBooks(booksRes.data.books || []);
        }
        setShowEditModal(false);
        setSelectedBook(null);
        showToast('Cập nhật sách thành công!');
      }
    } catch (error) {
      console.error('Error updating book:', error);
      showToast(error.response?.data?.message || 'Không thể cập nhật sách', 'error');
    }
  };

  const handleDeleteBook = async () => {
    try {
      const bookId = selectedBook.id || selectedBook.isbn;
      const response = await booksAPI.delete(bookId);
      if (response.success) {
        // Reload books
        const booksRes = await booksAPI.getAll(1, 1000);
        if (booksRes.success && booksRes.data) {
          setBooks(booksRes.data.books || []);
        }
        setShowDeleteModal(false);
        setSelectedBook(null);
        showToast('Xóa sách thành công!', 'success');
      }
    } catch (error) {
      console.error('Error deleting book:', error);
      showToast(error.response?.data?.message || 'Không thể xóa sách', 'error');
    }
  };

  const openEditModal = (book) => {
    setSelectedBook(book);
    setShowEditModal(true);
  };

  const openDeleteModal = (book) => {
    setSelectedBook(book);
    setShowDeleteModal(true);
  };

  return (
    <div>
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 dark:text-white">Quản lý sách</h1>
          <p className="text-gray-500 dark:text-gray-400">{books.length} sách trong hệ thống</p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <Plus className="w-5 h-5" />
          Thêm sách mới
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-4 mb-6">
        <div className="flex flex-col sm:flex-row gap-4">
          {/* Search */}
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm theo tên sách, tác giả, ISBN..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none"
            />
          </div>

          {/* Genre Filter */}
          <select
            value={selectedGenre}
            onChange={(e) => setSelectedGenre(e.target.value)}
            className="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none"
          >
            <option value="all">Tất cả thể loại</option>
            {genres.map(genre => (
              <option key={genre} value={genre}>{genre}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Loading State */}
      {isLoading ? (
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md p-12 text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-blue-500 border-t-transparent"></div>
          <p className="mt-4 text-gray-500 dark:text-gray-400">Đang tải danh sách sách...</p>
        </div>
      ) : (
        <>
          {/* Table */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 dark:bg-gray-700">
                  <tr>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Sách
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Tác giả
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Thể loại
                    </th>
                    <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Năm
                    </th>
                    <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                      Thao tác
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                  {paginatedBooks.length > 0 ? (
                    paginatedBooks.map((book) => (
                      <tr key={book.id || book.isbn} className="hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                        <td className="px-4 py-4">
                          <div className="flex items-center gap-3">
                            <img
                              src={book.coverUrl || '/images/book-placeholder.svg'}
                              alt={book.title}
                              className="w-12 h-16 object-cover rounded shadow"
                              onError={(e) => { e.target.src = '/images/book-placeholder.svg'; }}
                            />
                            <div className="min-w-0">
                              <p className="font-medium text-gray-800 dark:text-gray-200 truncate max-w-xs">
                                {book.title}
                              </p>
                              <p className="text-xs text-gray-500 dark:text-gray-400">
                                ISBN: {book.isbn || '-'}
                              </p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-4 text-sm text-gray-600 dark:text-gray-300">
                          {Array.isArray(book.authors) ? book.authors.join(', ') : (book.author || '-')}
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex flex-wrap gap-1">
                            {Array.isArray(book.genres) && book.genres.length > 0 ? (
                              book.genres.slice(0, 2).map((genre, idx) => {
                                const genreName = typeof genre === 'string' ? genre : genre.name;
                                return (
                                  <span
                                    key={idx}
                                    className="px-2 py-0.5 text-xs bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded"
                                  >
                                    {genreName}
                                  </span>
                                );
                              })
                            ) : (
                              <span className="text-xs text-gray-400">-</span>
                            )}
                            {Array.isArray(book.genres) && book.genres.length > 2 && (
                              <span className="px-2 py-0.5 text-xs bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded">
                                +{book.genres.length - 2}
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="px-4 py-4 text-sm text-gray-600 dark:text-gray-300">
                          {book.publishedYear || book.year || '-'}
                        </td>
                        <td className="px-4 py-4">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => openEditModal(book)}
                              className="p-2 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded-lg transition-colors"
                              title="Sửa"
                            >
                              <Edit2 className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => openDeleteModal(book)}
                              className="p-2 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded-lg transition-colors"
                              title="Xóa"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={5} className="px-4 py-8 text-center text-gray-500 dark:text-gray-400">
                        Không tìm thấy sách nào
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {/* Pagination */}
            {totalPages > 1 && (
              <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 dark:border-gray-700">
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Hiển thị {(currentPage - 1) * ITEMS_PER_PAGE + 1} - {Math.min(currentPage * ITEMS_PER_PAGE, filteredBooks.length)} / {filteredBooks.length} sách
            </p>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage === 1}
                className="p-2 rounded-lg border border-gray-300 dark:border-gray-600 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              
              {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                let page;
                if (totalPages <= 5) {
                  page = i + 1;
                } else if (currentPage <= 3) {
                  page = i + 1;
                } else if (currentPage >= totalPages - 2) {
                  page = totalPages - 4 + i;
                } else {
                  page = currentPage - 2 + i;
                }
                return (
                  <button
                    key={page}
                    onClick={() => setCurrentPage(page)}
                    className={`w-8 h-8 rounded-lg text-sm font-medium transition-colors ${
                      currentPage === page
                        ? 'bg-blue-600 text-white'
                        : 'hover:bg-gray-100 dark:hover:bg-gray-700 text-gray-600 dark:text-gray-300'
                    }`}
                  >
                    {page}
                  </button>
                );
              })}
              
              <button
                onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                disabled={currentPage === totalPages}
                className="p-2 rounded-lg border border-gray-300 dark:border-gray-600 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
              </div>
              </div>
            )}
          </div>
        </>
      )}

      {/* Modals */}
      <AddBookModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        onAdd={handleAddBook}
      />

      <EditBookModal
        isOpen={showEditModal}
        onClose={() => { setShowEditModal(false); setSelectedBook(null); }}
        onSave={handleEditBook}
        book={selectedBook}
      />

      <DeleteConfirmModal
        isOpen={showDeleteModal}
        onClose={() => { setShowDeleteModal(false); setSelectedBook(null); }}
        onConfirm={handleDeleteBook}
        title={selectedBook?.title}
      />

      {/* Toast */}
      <Toast
        show={toast.show}
        message={toast.message}
        type={toast.type}
        onClose={() => setToast({ show: false, message: '', type: 'success' })}
      />
    </div>
  );
}
