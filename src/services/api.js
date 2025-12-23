import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

// Tạo instance axios
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor 1: Tự động gắn Token vào mọi request
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor 2: Xử lý lỗi (Token hết hạn 401)
api.interceptors.response.use(
  (response) => response.data, // Trả về data trực tiếp cho gọn
  async (error) => {
    const originalRequest = error.config;

    // Nếu lỗi 401 và chưa retry lần nào -> Token hết hạn
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        // Gọi refresh token
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) throw new Error('No refresh token');

        // Gọi thẳng axios gốc để tránh loop
        const res = await axios.post(`${API_BASE_URL}/auth/refresh`, { refreshToken });
        
        if (res.data.success) {
            const { accessToken, refreshToken: newRefreshToken } = res.data.data;
            
            // Lưu token mới
            localStorage.setItem('accessToken', accessToken);
            localStorage.setItem('refreshToken', newRefreshToken);
            
            // Gắn lại header và gọi lại request cũ
            originalRequest.headers.Authorization = `Bearer ${accessToken}`;
            return api(originalRequest);
        }
      } catch (refreshError) {
        // Nếu refresh lỗi -> Logout luôn
        localStorage.clear();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }
    return Promise.reject(error);
  }
);

// --- CÁC API SERVICE ---

export const authAPI = {
  register: (userData) => api.post('/auth/register', userData),
  login: (credentials) => api.post('/auth/login', credentials),
  logout: (refreshToken) => api.post('/auth/logout', { refreshToken }),
  getCurrentUser: () => api.get('/auth/me'),
};

export const booksAPI = {
  getAll: (page = 1, limit = 20) => api.get(`/books?page=${page}&limit=${limit}`),
  search: (params = {}) => {
    const searchParams = new URLSearchParams();
    if (params.q) searchParams.append('q', params.q);
    if (params.genre && params.genre !== 'all') searchParams.append('genre', params.genre);
    if (params.year) searchParams.append('year', params.year);
    if (params.fromYear) searchParams.append('fromYear', params.fromYear);
    if (params.toYear) searchParams.append('toYear', params.toYear);
    if (params.language) searchParams.append('language', params.language);
    if (params.page) searchParams.append('page', params.page);
    if (params.limit) searchParams.append('limit', params.limit);
    return api.get(`/books/search?${searchParams.toString()}`);
  },
  getById: (id) => api.get(`/books/${id}`),
  getFeatured: (limit = 10) => api.get(`/books/featured?limit=${limit}`),
  getPopular: (limit = 10) => api.get(`/books/popular?limit=${limit}`),
  
  // Reviews
  getReviews: (bookId) => api.get(`/books/${bookId}/reviews`),
  addReview: (bookId, data) => api.post(`/books/${bookId}/reviews`, data),
};

export const genresAPI = {
  getAll: () => api.get('/genres'),
  getBooks: (slug) => api.get(`/genres/${slug}/books`),
};

export const profileAPI = {
  get: () => api.get('/users/profile'), // Gateway map sang user-service
  update: (data) => api.put('/users/profile', data),
};

export const favoritesAPI = {
  // Lấy danh sách (trả về mảng ID sách)
  getAll: () => api.get('/favorites'),
  
  // Thêm: POST /favorites/:bookId (bookId trong URL)
  add: (bookId) => api.post(`/favorites/${bookId}`),
  
  // Xóa: DELETE /favorites/:bookId
  remove: (bookId) => api.delete(`/favorites/${bookId}`),
  
  // Kiểm tra: GET /favorites/check/:bookId
  check: (bookId) => api.get(`/favorites/check/${bookId}`),
};

export const historyAPI = {
  getAll: () => api.get('/reading-history'),
  saveProgress: (data) => api.post('/reading-history', data), // { bookId, currentPage, totalPages }
  getBookProgress: (bookId) => api.get(`/reading-history/${bookId}`),
  deleteBook: (bookId) => api.delete(`/reading-history/${bookId}`),
};

export const collectionsAPI = {
  getAll: () => api.get('/collections'),
  create: (data) => api.post('/collections', data), // { name, description, isPublic }
  getById: (id) => api.get(`/collections/${id}`),
  update: (id, data) => api.put(`/collections/${id}`, data),
  delete: (id) => api.delete(`/collections/${id}`),
  addBook: (collectionId, bookId) => api.post(`/collections/${collectionId}/books/${bookId}`),
  removeBook: (collectionId, bookId) => api.delete(`/collections/${collectionId}/books/${bookId}`),
};

export const mlAPI = {
  getRecommendations: (userId, nItems = 10) => api.post('/ml/recommendations', { user_id: userId, n_items: nItems }),
  getSimilarBooks: (bookId, nItems = 6) => api.post('/ml/similar', { book_id: bookId, n_items: nItems }),
  estimateReadingTime: (pages, genre) => api.post('/ml/estimate-time', { pages, genre }),
};

export default api;