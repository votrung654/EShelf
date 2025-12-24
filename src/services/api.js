import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 30000, // 30 seconds timeout
});

// Attach token to requests
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

// Handle token expiration and request errors
api.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    const originalRequest = error.config;

    // Handle request aborted/timeout errors
    if (error.code === 'ECONNABORTED' || error.message?.includes('timeout')) {
      console.error('Request timeout or aborted:', error.message);
      return Promise.reject({
        ...error,
        message: 'Kết nối bị gián đoạn. Vui lòng thử lại.',
        isTimeout: true
      });
    }

    // Handle network errors
    if (!error.response && error.request) {
      console.error('Network error:', error.message);
      return Promise.reject({
        ...error,
        message: 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.',
        isNetworkError: true
      });
    }

    // Handle 401 - Token expired
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      
      try {
        const refreshToken = localStorage.getItem('refreshToken');
        if (!refreshToken) {
          // Clear expired tokens
          localStorage.clear();
          window.location.href = '/login';
          throw new Error('No refresh token');
        }

        const res = await axios.post(`${API_BASE_URL}/auth/refresh`, { refreshToken }, {
          timeout: 10000
        });
        
        if (res.data.success) {
            const { accessToken, refreshToken: newRefreshToken } = res.data.data;
            
            localStorage.setItem('accessToken', accessToken);
            localStorage.setItem('refreshToken', newRefreshToken);
            
            originalRequest.headers.Authorization = `Bearer ${accessToken}`;
            return api(originalRequest);
        }
      } catch (refreshError) {
        // Clear all tokens on refresh failure
        localStorage.clear();
        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        }
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
  
  // Admin operations
  create: (data) => api.post('/books', data),
  update: (id, data) => api.put(`/books/${id}`, data),
  delete: (id) => api.delete(`/books/${id}`),
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

export const usersAPI = {
  getAll: (page = 1, limit = 50, search = '') => api.get(`/users?page=${page}&limit=${limit}&search=${search}`),
  getById: (id) => api.get(`/users/${id}`),
  update: (id, data) => api.put(`/users/${id}`, data),
  delete: (id) => api.delete(`/users/${id}`),
};

export default api;