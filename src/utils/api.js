// API utility for frontend to communicate with backend
// This ensures proper separation: frontend only handles UI, backend handles business logic

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000';

// Helper function to handle API responses
async function handleResponse(response) {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'An error occurred' }));
    throw new Error(error.message || `HTTP error! status: ${response.status}`);
  }
  return response.json();
}

// Helper function to get auth headers
function getAuthHeaders() {
  const token = localStorage.getItem('eshelf_token');
  return {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
  };
}

// API methods
export const api = {
  // Auth endpoints
  auth: {
    async login(email, password) {
      const response = await fetch(`${API_BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await handleResponse(response);
      if (data.token) {
        localStorage.setItem('eshelf_token', data.token);
      }
      return data;
    },

    async register(userData) {
      const response = await fetch(`${API_BASE_URL}/api/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(userData),
      });
      return handleResponse(response);
    },

    async logout() {
      localStorage.removeItem('eshelf_token');
      localStorage.removeItem('eshelf_user');
    },

    async getCurrentUser() {
      const response = await fetch(`${API_BASE_URL}/api/auth/me`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async refreshToken() {
      const response = await fetch(`${API_BASE_URL}/api/auth/refresh`, {
        method: 'POST',
        headers: getAuthHeaders(),
      });
      const data = await handleResponse(response);
      if (data.token) {
        localStorage.setItem('eshelf_token', data.token);
      }
      return data;
    },
  },

  // User endpoints
  users: {
    async getProfile(userId) {
      const response = await fetch(`${API_BASE_URL}/api/users/${userId}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async updateProfile(userId, updates) {
      const response = await fetch(`${API_BASE_URL}/api/users/${userId}`, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(updates),
      });
      return handleResponse(response);
    },

    async getReadingHistory(userId) {
      const response = await fetch(`${API_BASE_URL}/api/users/${userId}/reading-history`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },
  },

  // Book endpoints
  books: {
    async getAll(params = {}) {
      const queryString = new URLSearchParams(params).toString();
      const response = await fetch(`${API_BASE_URL}/api/books?${queryString}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async getById(bookId) {
      const response = await fetch(`${API_BASE_URL}/api/books/${bookId}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async search(query, filters = {}) {
      const params = new URLSearchParams({ q: query, ...filters });
      const response = await fetch(`${API_BASE_URL}/api/books/search?${params}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async getGenres() {
      const response = await fetch(`${API_BASE_URL}/api/books/genres`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },
  },

  // Collections endpoints
  collections: {
    async getAll(userId) {
      const response = await fetch(`${API_BASE_URL}/api/collections?userId=${userId}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async getById(collectionId) {
      const response = await fetch(`${API_BASE_URL}/api/collections/${collectionId}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async create(collectionData) {
      const response = await fetch(`${API_BASE_URL}/api/collections`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(collectionData),
      });
      return handleResponse(response);
    },

    async update(collectionId, updates) {
      const response = await fetch(`${API_BASE_URL}/api/collections/${collectionId}`, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(updates),
      });
      return handleResponse(response);
    },

    async delete(collectionId) {
      const response = await fetch(`${API_BASE_URL}/api/collections/${collectionId}`, {
        method: 'DELETE',
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async addBook(collectionId, bookId) {
      const response = await fetch(`${API_BASE_URL}/api/collections/${collectionId}/books`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify({ bookId }),
      });
      return handleResponse(response);
    },

    async removeBook(collectionId, bookId) {
      const response = await fetch(`${API_BASE_URL}/api/collections/${collectionId}/books/${bookId}`, {
        method: 'DELETE',
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },
  },

  // Reading progress endpoints
  readingProgress: {
    async get(bookId, userId) {
      const response = await fetch(`${API_BASE_URL}/api/reading-progress/${bookId}?userId=${userId}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async update(bookId, progress) {
      const response = await fetch(`${API_BASE_URL}/api/reading-progress/${bookId}`, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(progress),
      });
      return handleResponse(response);
    },

    async getHistory(userId) {
      const response = await fetch(`${API_BASE_URL}/api/reading-progress/history?userId=${userId}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },
  },

  // Admin endpoints (only accessible by admin users)
  admin: {
    async getBooks(params = {}) {
      const queryString = new URLSearchParams(params).toString();
      const response = await fetch(`${API_BASE_URL}/api/admin/books?${queryString}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async createBook(bookData) {
      const response = await fetch(`${API_BASE_URL}/api/admin/books`, {
        method: 'POST',
        headers: getAuthHeaders(),
        body: JSON.stringify(bookData),
      });
      return handleResponse(response);
    },

    async updateBook(bookId, updates) {
      const response = await fetch(`${API_BASE_URL}/api/admin/books/${bookId}`, {
        method: 'PUT',
        headers: getAuthHeaders(),
        body: JSON.stringify(updates),
      });
      return handleResponse(response);
    },

    async deleteBook(bookId) {
      const response = await fetch(`${API_BASE_URL}/api/admin/books/${bookId}`, {
        method: 'DELETE',
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async getUsers(params = {}) {
      const queryString = new URLSearchParams(params).toString();
      const response = await fetch(`${API_BASE_URL}/api/admin/users?${queryString}`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },

    async getStats() {
      const response = await fetch(`${API_BASE_URL}/api/admin/stats`, {
        headers: getAuthHeaders(),
      });
      return handleResponse(response);
    },
  },
};

export default api;

