import { createContext, useContext, useState, useEffect } from 'react';
import { authAPI } from '../services/api';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // Khởi động: Kiểm tra xem có token trong localStorage không
  useEffect(() => {
    const initAuth = async () => {
      const token = localStorage.getItem('accessToken');
      const storedUser = localStorage.getItem('user');

      if (token && storedUser) {
        try {
          // Try to get current user to validate token
          const res = await authAPI.getCurrentUser();
          if (res.success) {
            setUser(res.data);
          } else {
            // Token invalid, clear storage
            localStorage.clear();
          }
        } catch (err) {
          console.error("Token invalid or expired:", err);
          // Clear expired/invalid tokens
          localStorage.clear();
        }
      }
      setIsLoading(false);
    };

    initAuth();
  }, []);

  // Hàm Login gọi API thật
  const login = async (email, password) => {
    try {
      const response = await authAPI.login({ email, password });
      
      if (response.success) {
        const { user, accessToken, refreshToken } = response.data;

        // Lưu vào Storage
        localStorage.setItem('accessToken', accessToken);
        localStorage.setItem('refreshToken', refreshToken);
        localStorage.setItem('user', JSON.stringify(user));

        // Cập nhật State
        setUser(user);
        return { success: true };
      }
    } catch (error) {
      console.error('Login failed:', error);
      
      // Handle timeout/network errors
      if (error.isTimeout || error.isNetworkError) {
        return {
          success: false,
          message: error.message || 'Kết nối bị gián đoạn. Vui lòng thử lại.'
        };
      }
      
      // Handle other errors
      return { 
        success: false, 
        message: error.response?.data?.message || error.message || 'Đăng nhập thất bại' 
      };
    }
  };

  // Hàm Register gọi API thật
  const register = async (userData) => {
    try {
      const response = await authAPI.register(userData);
      return { success: true, message: response.message };
    } catch (error) {
      return { 
        success: false, 
        message: error.response?.data?.message || 'Đăng ký thất bại' 
      };
    }
  };

  const logout = () => {
    const refreshToken = localStorage.getItem('refreshToken');
    if (refreshToken) {
        authAPI.logout(refreshToken).catch(console.error); // Gọi API logout ngầm
    }
    
    // Xóa sạch storage và state
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    localStorage.removeItem('user');
    setUser(null);
    
    window.location.href = '/login';
  };

  const value = {
    user,
    isLoading,
    isAuthenticated: !!user,
    isAdmin: user?.role === 'ADMIN',
    login,
    register,
    logout,
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