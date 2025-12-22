// API Service for eShelf Frontend

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

// Token management
let accessToken = null;

export const setAccessToken = (token) => {
  accessToken = token;
  if (token) {
    localStorage.setItem('eshelf_token', token);
  } else {
    localStorage.removeItem('eshelf_token');
  }
};

export const getAccessToken = () => {
  if (!accessToken) {
    accessToken = localStorage.getItem('eshelf_token');
  }
  return accessToken;
};

// API request helper
const request = async (endpoint, options = {}) => {
  const url = `${API_BASE_URL}${endpoint}`;
  
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers,
  };

  const token = getAccessToken();
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  try {
    const response = await fetch(url, {
      ...options,
      headers,
    });

    const data = await response.json();

    if (!response.ok) {
      // Handle token expiration
      if (response.status === 401 && data.code === 'TOKEN_EXPIRED') {
        // Try to refresh token
        const refreshed = await refreshToken();
        if (refreshed) {
          // Retry original request
          return request(endpoint, options);
        }
      }
      throw new Error(data.message || 'API Error');
    }

    return data;
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
};

// Refresh token
const refreshToken = async () => {
  const refreshToken = localStorage.getItem('eshelf_refresh_token');
  if (!refreshToken) return false;

  try {
    const response = await fetch(`${API_BASE_URL}/api/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });

    if (response.ok) {
      const data = await response.json();
      setAccessToken(data.data.accessToken);
      localStorage.setItem('eshelf_refresh_token', data.data.refreshToken);
      return true;
    }
  } catch (error) {
    console.error('Refresh token error:', error);
  }

  // Clear tokens on failure
  setAccessToken(null);
  localStorage.removeItem('eshelf_refresh_token');
  return false;
};

// Auth API
export const authAPI = {
  register: (userData) => request('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify(userData),
  }),

  login: async (credentials) => {
    const data = await request('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
    if (data.success) {
      setAccessToken(data.data.accessToken);
      localStorage.setItem('eshelf_refresh_token', data.data.refreshToken);
    }
    return data;
  },

  logout: async () => {
    try {
      await request('/api/auth/logout', { method: 'POST' });
    } finally {
      setAccessToken(null);
      localStorage.removeItem('eshelf_refresh_token');
    }
  },

  getCurrentUser: () => request('/api/auth/me'),

  forgotPassword: (email) => request('/api/auth/forgot-password', {
    method: 'POST',
    body: JSON.stringify({ email }),
  }),
};

// Books API
export const booksAPI = {
  getAll: (params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/api/books${query ? `?${query}` : ''}`);
  },

  search: (params) => {
    const query = new URLSearchParams(params).toString();
    return request(`/api/books/search?${query}`);
  },

  getById: (id) => request(`/api/books/${id}`),

  getFeatured: (limit = 10) => request(`/api/books/featured?limit=${limit}`),

  getPopular: (limit = 10) => request(`/api/books/popular?limit=${limit}`),

  getReviews: (bookId) => request(`/api/books/${bookId}/reviews`),

  addReview: (bookId, reviewData) => request(`/api/books/${bookId}/reviews`, {
    method: 'POST',
    body: JSON.stringify(reviewData),
  }),

  // Admin operations
  create: (bookData) => request('/api/books', {
    method: 'POST',
    body: JSON.stringify(bookData),
  }),

  update: (id, bookData) => request(`/api/books/${id}`, {
    method: 'PUT',
    body: JSON.stringify(bookData),
  }),

  delete: (id) => request(`/api/books/${id}`, { method: 'DELETE' }),
};

// Genres API
export const genresAPI = {
  getAll: () => request('/api/genres'),
  getBySlug: (slug) => request(`/api/genres/${slug}`),
  getBooks: (slug, params = {}) => {
    const query = new URLSearchParams(params).toString();
    return request(`/api/genres/${slug}/books${query ? `?${query}` : ''}`);
  },
};

// User Profile API
export const profileAPI = {
  get: () => request('/api/profile'),
  update: (data) => request('/api/profile', {
    method: 'PUT',
    body: JSON.stringify(data),
  }),
  updateAvatar: (avatarUrl) => request('/api/profile/avatar', {
    method: 'PUT',
    body: JSON.stringify({ avatar: avatarUrl }),
  }),
  getStats: () => request('/api/profile/stats'),
};

// Favorites API
export const favoritesAPI = {
  getAll: () => request('/api/favorites'),
  add: (bookId) => request(`/api/favorites/${bookId}`, { method: 'POST' }),
  remove: (bookId) => request(`/api/favorites/${bookId}`, { method: 'DELETE' }),
  check: (bookId) => request(`/api/favorites/check/${bookId}`),
};

// Collections API
export const collectionsAPI = {
  getAll: () => request('/api/collections'),
  create: (data) => request('/api/collections', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  getById: (id) => request(`/api/collections/${id}`),
  update: (id, data) => request(`/api/collections/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  }),
  delete: (id) => request(`/api/collections/${id}`, { method: 'DELETE' }),
  addBook: (collectionId, bookId) => request(`/api/collections/${collectionId}/books/${bookId}`, {
    method: 'POST',
  }),
  removeBook: (collectionId, bookId) => request(`/api/collections/${collectionId}/books/${bookId}`, {
    method: 'DELETE',
  }),
};

// Reading History API
export const historyAPI = {
  getAll: () => request('/api/reading-history'),
  saveProgress: (data) => request('/api/reading-history', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  getBookProgress: (bookId) => request(`/api/reading-history/${bookId}`),
  deleteBook: (bookId) => request(`/api/reading-history/${bookId}`, { method: 'DELETE' }),
};

// ML API
export const mlAPI = {
  getRecommendations: (userId, nItems = 10) => request('/api/ml/recommendations', {
    method: 'POST',
    body: JSON.stringify({ user_id: userId, n_items: nItems }),
  }),
  getSimilarBooks: (bookId, nItems = 6) => request('/api/ml/similar', {
    method: 'POST',
    body: JSON.stringify({ book_id: bookId, n_items: nItems }),
  }),
  estimateReadingTime: (pages, genre = null) => request('/api/ml/estimate-time', {
    method: 'POST',
    body: JSON.stringify({ pages, genre }),
  }),
};

export default {
  auth: authAPI,
  books: booksAPI,
  genres: genresAPI,
  profile: profileAPI,
  favorites: favoritesAPI,
  collections: collectionsAPI,
  history: historyAPI,
  ml: mlAPI,
};


