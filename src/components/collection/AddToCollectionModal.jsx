import { useState, useCallback, memo } from 'react';

function AddToCollectionModal({ isOpen, onClose, book, collections, onAdd, onCreateNew, onRemove }) {
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState('');

  const handleAdd = useCallback((collectionId) => {
    if (book) {
      onAdd(collectionId, book);
    }
  }, [book, onAdd]);

  const handleRemove = useCallback((collectionId) => {
    if (book && onRemove) {
      onRemove(collectionId, book);
    }
  }, [book, onRemove]);

  const handleCreateAndAdd = useCallback(() => {
    if (!newName.trim() || !book) return;
    
    const newCollection = {
      id: `collection-${Date.now()}`,
      name: newName.trim(),
      description: '',
      books: [book],
      createdAt: new Date().toISOString(),
    };
    
    onCreateNew(newCollection);
    setNewName('');
    setShowCreate(false);
  }, [newName, book, onCreateNew]);

  const isBookInCollection = useCallback((collection) => {
    const bookId = book?.isbn || book?.id;
    if (!bookId) return false;
    
    if (Array.isArray(collection.books)) {
      return collection.books.some(b => {
        if (typeof b === 'string') {
          return b === bookId;
        }
        return (b.isbn || b.id) === bookId;
      });
    }
    return false;
  }, [book]);

  const handleClose = useCallback(() => {
    setShowCreate(false);
    setNewName('');
    onClose();
  }, [onClose]);

  if (!isOpen || !book) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={handleClose} />

      <div className="relative bg-white dark:bg-gray-800 rounded-xl shadow-2xl w-full max-w-sm mx-4 overflow-hidden">
        <div className="p-4 border-b border-gray-100 dark:border-gray-700">
          <button
            type="button"
            onClick={handleClose}
            className="absolute top-3 right-3 p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
          <h3 className="font-semibold text-gray-800 dark:text-gray-100">Lưu vào bộ sưu tập</h3>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-1 truncate">{book.title}</p>
        </div>

        <div className="max-h-64 overflow-y-auto">
          {collections.map((collection) => {
            const isAdded = isBookInCollection(collection);
            return (
              <div
                key={collection.id}
                className={`w-full px-4 py-3 flex items-center gap-3 border-b border-gray-50 dark:border-gray-700 ${
                  isAdded ? 'bg-green-50 dark:bg-green-900/20' : 'hover:bg-gray-50 dark:hover:bg-gray-700'
                }`}
              >
                {collection.id === 'favorites' ? (
                  <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 text-red-500" fill="currentColor" viewBox="0 0 24 24">
                      <path d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                    </svg>
                  </div>
                ) : (
                  <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                    <svg className="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                    </svg>
                  </div>
                )}
                <div className="flex-1 text-left min-w-0">
                  <p className="font-medium text-gray-800 dark:text-gray-100 truncate">{collection.name}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    {collection.bookCount || (Array.isArray(collection.books) ? collection.books.length : 0)} sách
                  </p>
                </div>
                
                {/* Nút Thêm hoặc Xóa */}
                {isAdded ? (
                  <button
                    type="button"
                    onClick={() => handleRemove(collection.id)}
                    className="flex items-center gap-1 px-3 py-1.5 bg-red-100 text-red-600 rounded-lg text-sm hover:bg-red-200 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    Xóa
                  </button>
                ) : (
                  <button
                    type="button"
                    onClick={() => handleAdd(collection.id)}
                    className="flex items-center gap-1 px-3 py-1.5 bg-blue-100 text-blue-600 rounded-lg text-sm hover:bg-blue-200 transition-colors"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
                    </svg>
                    Thêm
                  </button>
                )}
              </div>
            );
          })}
        </div>

        <div className="p-4 border-t border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-900">
          {showCreate ? (
            <div className="flex gap-2">
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Tên bộ sưu tập mới..."
                className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none dark:placeholder-gray-500"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleCreateAndAdd();
                  }
                  if (e.key === 'Escape') {
                    setShowCreate(false);
                    setNewName('');
                  }
                }}
              />
              <button
                type="button"
                onClick={handleCreateAndAdd}
                disabled={!newName.trim()}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Tạo
              </button>
            </div>
          ) : (
            <button
              type="button"
              onClick={() => setShowCreate(true)}
              className="w-full py-2 text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium text-sm flex items-center justify-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Tạo bộ sưu tập mới
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

export default memo(AddToCollectionModal);
