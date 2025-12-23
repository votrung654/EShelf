import { useState, useEffect } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Eye, EyeOff, Mail, Lock, User, ArrowLeft } from "lucide-react";
import { useAuth } from "../context/AuthContext"; // Import Context xịn
import { authAPI } from "../services/api"; // Import API để xử lý forgot pass

const LoginRegister = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  
  // Lấy hàm login và register từ Context
  const { login, register, isAuthenticated } = useAuth();

  const [isLogin, setIsLogin] = useState(searchParams.get("tab") !== "register");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);

  const [form, setForm] = useState({
    email: "",
    password: "",
    confirmPassword: "",
    username: "",
    rememberMe: false,
  });

  const [errors, setErrors] = useState({});
  const [successMessage, setSuccessMessage] = useState("");

  // Nếu đã login thì đá về trang chủ
  useEffect(() => {
    if (isAuthenticated) {
      navigate("/");
    }
  }, [isAuthenticated, navigate]);

  const validateEmail = (email) => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  };

  const validatePassword = (password) => {
    const errors = [];
    if (password.length < 6) errors.push("Ít nhất 6 ký tự"); // Giảm xuống 6 cho dễ test
    return errors;
  };

  const validate = () => {
    const newErrors = {};

    if (!form.email.trim()) {
      newErrors.email = "Vui lòng nhập email";
    } else if (!validateEmail(form.email)) {
      newErrors.email = "Email không hợp lệ";
    }

    if (!form.password) {
      newErrors.password = "Vui lòng nhập mật khẩu";
    } else if (!isLogin) {
      const passwordErrors = validatePassword(form.password);
      if (passwordErrors.length > 0) {
        newErrors.password = passwordErrors.join(", ");
      }
    }

    if (!isLogin) {
      if (!form.username.trim()) {
        newErrors.username = "Vui lòng nhập tên người dùng";
      }

      if (!form.confirmPassword) {
        newErrors.confirmPassword = "Vui lòng xác nhận mật khẩu";
      } else if (form.password !== form.confirmPassword) {
        newErrors.confirmPassword = "Mật khẩu không khớp";
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setForm((prev) => ({
      ...prev,
      [name]: type === "checkbox" ? checked : value,
    }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: "" }));
    }
  };

  // 👇 XỬ LÝ LOGIN VỚI API THẬT
  const handleLogin = async () => {
    // Gọi hàm login từ AuthContext
    const result = await login(form.email, form.password);

    if (result.success) {
      navigate("/"); // Login thành công -> Về trang chủ
    } else {
      // Login thất bại -> Hiện lỗi từ Backend
      setErrors({ 
        general: result.message || "Email hoặc mật khẩu không đúng",
        password: result.message === "Mật khẩu không đúng" ? "Mật khẩu không đúng" : ""
      });
    }
  };

  // 👇 XỬ LÝ REGISTER VỚI API THẬT
  const handleRegister = async () => {
    // Chuẩn bị dữ liệu gửi lên Backend
    const userData = {
      email: form.email,
      password: form.password,
      username: form.username,
      name: form.username, // Tạm thời lấy name = username
    };

    // Gọi hàm register từ AuthContext
    const result = await register(userData);

    if (result.success) {
      setSuccessMessage("Đăng ký thành công! Vui lòng đăng nhập.");
      setIsLogin(true); // Chuyển sang tab login
      setForm((prev) => ({ ...prev, password: "", confirmPassword: "" }));
    } else {
      // Hiện lỗi từ Backend (ví dụ: Email đã tồn tại)
      setErrors({ 
        general: result.message,
        email: result.message?.includes("Email") ? result.message : "",
        username: result.message?.includes("Tên người dùng") ? result.message : ""
      });
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    setIsLoading(true);
    setSuccessMessage("");
    setErrors({}); // Reset lỗi cũ

    try {
      if (isLogin) {
        await handleLogin();
      } else {
        await handleRegister();
      }
    } catch (error) {
      setErrors({ general: "Lỗi kết nối server. Vui lòng thử lại." });
    } finally {
      setIsLoading(false);
    }
  };

  // Xử lý quên mật khẩu (Gọi API thật)
  const handleForgotPassword = async (e) => {
    e.preventDefault();
    if (!form.email.trim()) {
      setErrors({ email: "Vui lòng nhập email" });
      return;
    }
    
    try {
      await authAPI.forgotPassword(form.email);
      // Luôn báo thành công để bảo mật (tránh check mail)
      setSuccessMessage(`Nếu email tồn tại, hướng dẫn đặt lại mật khẩu sẽ được gửi đến ${form.email}`);
      setTimeout(() => setShowForgotPassword(false), 3000);
    } catch (error) {
      setErrors({ email: "Có lỗi xảy ra khi gửi yêu cầu." });
    }
  };

  const switchMode = () => {
    setIsLogin(!isLogin);
    setErrors({});
    setSuccessMessage("");
    setForm({
      email: form.email,
      password: "",
      confirmPassword: "",
      username: "",
      rememberMe: false,
    });
  };

  // Render Form Quên Mật Khẩu
  if (showForgotPassword) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4">
        <div className="w-full max-w-md">
          <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
            <button
              onClick={() => setShowForgotPassword(false)}
              className="flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-200 mb-6"
            >
              <ArrowLeft className="w-4 h-4" />
              Quay lại
            </button>

            <h2 className="text-2xl font-bold text-gray-800 dark:text-white mb-2">
              Quên mật khẩu
            </h2>
            <p className="text-gray-500 dark:text-gray-400 mb-6">
              Nhập email để nhận hướng dẫn đặt lại mật khẩu
            </p>

            {successMessage && (
              <div className="mb-4 p-3 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-lg text-sm">
                {successMessage}
              </div>
            )}

            <form onSubmit={handleForgotPassword}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Email
                </label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="email"
                    name="email"
                    value={form.email}
                    onChange={handleChange}
                    className="w-full pl-10 pr-4 py-3 border rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none border-gray-300 dark:border-gray-600"
                    placeholder="your@email.com"
                  />
                </div>
              </div>

              <button
                type="submit"
                className="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium"
              >
                Gửi hướng dẫn
              </button>
            </form>
          </div>
        </div>
      </div>
    );
  }

  // Render Form Login/Register Chính
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4 py-8">
      <div className="w-full max-w-md">
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
          {/* Logo */}
          <div className="text-center mb-8">
            <Link to="/" className="inline-flex items-center gap-2">
              <span className="text-2xl font-bold text-gray-800 dark:text-white">eShelf</span>
            </Link>
          </div>

          {/* Tabs */}
          <div className="flex mb-6 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
            <button
              onClick={() => !isLogin && switchMode()}
              className={`flex-1 py-2 text-sm font-medium rounded-md transition-colors ${
                isLogin
                  ? "bg-white dark:bg-gray-600 text-gray-800 dark:text-white shadow"
                  : "text-gray-600 dark:text-gray-400"
              }`}
            >
              Đăng nhập
            </button>
            <button
              onClick={() => isLogin && switchMode()}
              className={`flex-1 py-2 text-sm font-medium rounded-md transition-colors ${
                !isLogin
                  ? "bg-white dark:bg-gray-600 text-gray-800 dark:text-white shadow"
                  : "text-gray-600 dark:text-gray-400"
              }`}
            >
              Đăng ký
            </button>
          </div>

          {/* Messages */}
          {successMessage && (
            <div className="mb-4 p-3 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 rounded-lg text-sm">
              {successMessage}
            </div>
          )}
          {errors.general && (
            <div className="mb-4 p-3 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-lg text-sm animate-fadeIn">
              <div className="flex items-center gap-2">
                <svg className="w-5 h-5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
                <span>{errors.general}</span>
              </div>
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Username (Register only) */}
            {!isLogin && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Tên người dùng
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    name="username"
                    value={form.username}
                    onChange={handleChange}
                    className={`w-full pl-10 pr-4 py-3 border rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none ${
                      errors.username ? "border-red-500" : "border-gray-300 dark:border-gray-600"
                    }`}
                    placeholder="username"
                  />
                </div>
                {errors.username && (
                  <p className="text-red-500 text-sm mt-1">{errors.username}</p>
                )}
              </div>
            )}

            {/* Email */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="email"
                  name="email"
                  value={form.email}
                  onChange={handleChange}
                  className={`w-full pl-10 pr-4 py-3 border rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none ${
                    errors.email ? "border-red-500" : "border-gray-300 dark:border-gray-600"
                  }`}
                  placeholder="admin@eshelf.com"
                />
              </div>
              {errors.email && (
                <p className="text-red-500 text-sm mt-1">{errors.email}</p>
              )}
            </div>

            {/* Password */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Mật khẩu
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type={showPassword ? "text" : "password"}
                  name="password"
                  value={form.password}
                  onChange={handleChange}
                  className={`w-full pl-10 pr-12 py-3 border rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none ${
                    errors.password ? "border-red-500" : "border-gray-300 dark:border-gray-600"
                  }`}
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              {errors.password && (
                <p className="text-red-500 text-sm mt-1">{errors.password}</p>
              )}
            </div>

            {/* Confirm Password (Register only) */}
            {!isLogin && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Xác nhận mật khẩu
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type={showConfirmPassword ? "text" : "password"}
                    name="confirmPassword"
                    value={form.confirmPassword}
                    onChange={handleChange}
                    className={`w-full pl-10 pr-12 py-3 border rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none ${
                      errors.confirmPassword ? "border-red-500" : "border-gray-300 dark:border-gray-600"
                    }`}
                    placeholder="••••••••"
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    {showConfirmPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                  </button>
                </div>
                {errors.confirmPassword && (
                  <p className="text-red-500 text-sm mt-1">{errors.confirmPassword}</p>
                )}
              </div>
            )}

            {/* Forgot Password Link */}
            {isLogin && (
              <div className="flex justify-end">
                <button
                  type="button"
                  onClick={() => setShowForgotPassword(true)}
                  className="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400"
                >
                  Quên mật khẩu?
                </button>
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Đang xử lý...
                </>
              ) : isLogin ? (
                "Đăng nhập"
              ) : (
                "Đăng ký"
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default LoginRegister;