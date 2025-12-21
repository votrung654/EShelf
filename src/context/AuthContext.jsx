import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import api from '../utils/api';

const AuthContext = createContext();

const USER_KEY = 'eshelf_user';

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Load user from backend on mount
  useEffect(() => {
    const loadUser = async () => {
      try {
        const token = localStorage.getItem('eshelf_token');
        if (token) {
          // Try to get current user from backend
          const userData = await api.auth.getCurrentUser();
          setUser(userData);
          localStorage.setItem(USER_KEY, JSON.stringify(userData));
        } else {
          // Fallback to localStorage if no token
          const savedUser = localStorage.getItem(USER_KEY);
          if (savedUser) {
            try {
              setUser(JSON.parse(savedUser));
            } catch (e) {
              console.error('Failed to parse user:', e);
              localStorage.removeItem(USER_KEY);
            }
          }
        }
      } catch (error) {
        console.error('Failed to load user:', error);
        // Clear invalid token
        localStorage.removeItem('eshelf_token');
        localStorage.removeItem(USER_KEY);
      } finally {
        setIsLoading(false);
      }
    };

    loadUser();
  }, []);

  const login = useCallback(async (email, password) => {
    try {
      const response = await api.auth.login(email, password);
      setUser(response.user);
      localStorage.setItem(USER_KEY, JSON.stringify(response.user));
      return { success: true, user: response.user };
    } catch (error) {
      console.error('Login error:', error);
      return { success: false, error: error.message };
    }
  }, []);

  const register = useCallback(async (userData) => {
    try {
      const response = await api.auth.register(userData);
      if (response.token) {
        setUser(response.user);
        localStorage.setItem(USER_KEY, JSON.stringify(response.user));
      }
      return { success: true, user: response.user };
    } catch (error) {
      console.error('Register error:', error);
      return { success: false, error: error.message };
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.auth.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setUser(null);
      localStorage.removeItem(USER_KEY);
    }
  }, []);

  const updateUser = useCallback((updates) => {
    setUser(prev => {
      const updated = { ...prev, ...updates };
      localStorage.setItem(USER_KEY, JSON.stringify(updated));
      return updated;
    });
  }, []);

  const value = {
    user,
    isLoading,
    isAuthenticated: !!user,
    isAdmin: user?.role === 'admin',
    login,
    register,
    logout,
    updateUser,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export default AuthContext;
