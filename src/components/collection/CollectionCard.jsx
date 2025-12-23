import { Link } from 'react-router-dom';
import { Trash2, BookOpen } from 'lucide-react';

const CollectionCard = ({ collection, onDelete }) => {
  const bookCount = collection.bookCount || collection.books?.length || 0;
  const firstBooks = Array.isArray(collection.books) ? collection.books.slice(0, 4) : [];

  const handleDelete = (e) => {
    e.preventDefault();
    e.stopPropagation();
    
    if (collection.id === 'favorites') {
      alert('Không thể xóa bộ sưu tập Yêu thích');
      return;
    }

    if (window.confirm(`Bạn có chắc muốn xóa bộ sưu tập "${collection.name}"?`)) {
      onDelete(collection.id);
    }
  };

  return (
    <Link 
      to={`/collections/${collection.id}`}
      className="block bg-white dark:bg-gray-800 rounded-xl shadow-md hover:shadow-xl transition-all duration-300 overflow-hidden group"
    >
      {/* Cover Grid */}
      <div className="aspect-video bg-gradient-to-br from-blue-50 to-purple-50 dark:from-gray-700 dark:to-gray-600 p-2">
        {firstBooks.length > 0 ? (
          <div className="grid grid-cols-2 gap-1 h-full">
            {firstBooks.map((book, idx) => (
              <div key={idx} className="relative rounded overflow-hidden">
                <img 
                  src={book.coverUrl || book.cover || 'https://placehold.co/200x300?text=Book'}
                  alt=""
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
              </div>
            ))}
          </div>
        ) : (
          <div className="flex items-center justify-center h-full">
            <BookOpen className="w-12 h-12 text-gray-300 dark:text-gray-500" />
          </div>
        )}
      </div>

      {/* Info */}
      <div className="p-4">
        <div className="flex items-start justify-between mb-2">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white line-clamp-1 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
            {collection.name}
          </h3>
          {collection.id !== 'favorites' && (
            <button
              onClick={handleDelete}
              className="p-1 text-gray-400 hover:text-red-500 transition-colors"
              title="Xóa bộ sưu tập"
            >
              <Trash2 className="w-4 h-4" />
            </button>
          )}
        </div>

        {collection.description && (
          <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2 mb-3">
            {collection.description}
          </p>
        )}

        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-500 dark:text-gray-400">
            {bookCount} cuốn sách
          </span>
          {collection.updatedAt && (
            <span className="text-xs text-gray-400 dark:text-gray-500">
              {new Date(collection.updatedAt).toLocaleDateString('vi-VN')}
            </span>
          )}
        </div>
      </div>
    </Link>
  );
};

export default CollectionCard;
