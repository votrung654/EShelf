import { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Plus, Search } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { collectionsAPI, booksAPI } from '../services/api';
import CollectionCard from '../components/collection/CollectionCard';
import CreateCollectionModal from '../components/collection/CreateCollectionModal';

const Collections = () => {
  const navigate = useNavigate();
  const { user, isAuthenticated } = useAuth();
  const [collections, setCollections] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // Redirect if not logged in
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login');
    }
  }, [isAuthenticated, navigate]);

  // Load collections từ backend thay vì localStorage
  useEffect(() => {
    const loadCollections = async () => {
      if (!user?.id || !isAuthenticated) {
        setCollections([]);
        return;
      }

      try {
        const response = await collectionsAPI.getAll();
        if (response.success && response.data) {
          setCollections(response.data);
        }
      } catch (error) {
        console.error('Failed to load collections:', error);
      }
    };

    loadCollections();
  }, [user?.id, isAuthenticated]);

  const handleCreate = async (newCollection) => {
    try {
      const response = await collectionsAPI.create({
        name: newCollection.name,
        description: newCollection.description || '',
        isPublic: false
      });
      
      if (response.success && response.data) {
        setCollections(prev => [...prev, response.data]);
        setShowCreateModal(false);
      }
    } catch (error) {
      console.error('Create collection error:', error);
      alert('Không thể tạo bộ sưu tập. Vui lòng thử lại.');
    }
  };

  const handleDelete = async (id) => {
    if (id === 'favorites') return;
    
    try {
      await collectionsAPI.delete(id);
      setCollections(prev => prev.filter(c => c.id !== id));
    } catch (error) {
      console.error('Delete collection error:', error);
      alert('Không thể xóa bộ sưu tập.');
    }
  };

  const filteredCollections = collections.filter(c =>
    c.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (!isAuthenticated) {
    return null; // Will redirect
  }

  if (isLoading) {
    return (
      <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
        <div className="flex items-center justify-center py-16">
          <div className="animate-spin w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full" />
        </div>
      </main>
    );
  }

  return (
    <main className="flex-1 max-w-7xl mx-auto w-full px-4 py-8">
      {/* Breadcrumb */}
      <nav className="mb-6">
        <ol className="flex items-center space-x-2 text-sm">
          <li>
            <Link to="/" className="text-blue-600 hover:underline">Trang chủ</Link>
          </li>
          <li className="text-gray-400">/</li>
          <li className="text-gray-600">Bộ sưu tập</li>
        </ol>
      </nav>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Bộ sưu tập của tôi</h1>
          <p className="text-gray-500 mt-1">
            {collections.length} bộ sưu tập • {collections.reduce((sum, c) => sum + (c.bookCount || c.books?.length || 0), 0)} sách
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors shadow-md hover:shadow-lg"
        >
          <Plus className="w-5 h-5" />
          Tạo bộ sưu tập
        </button>
      </div>

      {/* Search */}
      <div className="relative mb-6">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Tìm kiếm bộ sưu tập..."
          className="w-full sm:w-80 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-gray-900 placeholder-gray-500"
        />
      </div>

      {/* Collections Grid */}
      {filteredCollections.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {filteredCollections.map((collection) => (
            <CollectionCard
              key={collection.id}
              collection={collection}
              onDelete={handleDelete}
            />
          ))}
        </div>
      ) : (
        <div className="text-center py-16 bg-gray-50 dark:bg-gray-800 rounded-xl">
          <div className="w-20 h-20 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-10 h-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
          </div>
          <h3 className="text-lg font-medium text-gray-800 mb-2">
            {searchTerm ? 'Không tìm thấy bộ sưu tập' : 'Chưa có bộ sưu tập nào'}
          </h3>
          <p className="text-gray-500 mb-4">
            {searchTerm ? 'Thử tìm kiếm với từ khóa khác' : 'Tạo bộ sưu tập đầu tiên của bạn'}
          </p>
          {!searchTerm && (
            <button
              onClick={() => setShowCreateModal(true)}
              className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
            >
              <Plus className="w-5 h-5" />
              Tạo bộ sưu tập
            </button>
          )}
        </div>
      )}

      {/* Create Modal */}
      <CreateCollectionModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onCreate={handleCreate}
      />
    </main>
  );
}

export default Collections;
