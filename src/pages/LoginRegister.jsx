import { useState, useEffect } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Eye, EyeOff, Mail, Lock, User, ArrowLeft } from "lucide-react";
import { useAuth } from "../context/AuthContext";
import Logo from "../components/common/Logo.jsx";

const USERS_KEY = "eshelf_users";

const LoginRegister = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { login, isAuthenticated } = useAuth();

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

  // Redirect if already logged in
  useEffect(() => {
    if (isAuthenticated) {
      navigate("/");
    }
  }, [isAuthenticated, navigate]);

  // Get registered users from localStorage
  const getUsers = () => {
    try {
      return JSON.parse(localStorage.getItem(USERS_KEY) || "[]");
    } catch {
      return [];
    }
  };

  // Save users to localStorage
  const saveUsers = (users) => {
    localStorage.setItem(USERS_KEY, JSON.stringify(users));
  };

  const validateEmail = (email) => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  };

  const validatePassword = (password) => {
    const errors = [];
    if (password.length < 8) errors.push("Ít nhất 8 ký tự");
    if (!/[A-Z]/.test(password)) errors.push("Ít nhất 1 chữ hoa");
    if (!/[a-z]/.test(password)) errors.push("Ít nhất 1 chữ thường");
    if (!/[0-9]/.test(password)) errors.push("Ít nhất 1 số");
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
      } else if (form.username.length < 3) {
        newErrors.username = "Tên người dùng ít nhất 3 ký tự";
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
    // Clear error when user types
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: "" }));
    }
  };

  const handleLogin = async () => {
    const users = getUsers();
    const user = users.find((u) => u.email.toLowerCase() === form.email.toLowerCase());

    if (!user) {
      setErrors({ email: "Email không tồn tại trong hệ thống" });
      return;
    }

    if (user.password !== form.password) {
      setErrors({ password: "Mật khẩu không đúng" });
      return;
    }

    // Login successful
    const userData = {
      id: user.id,
      email: user.email,
      username: user.username,
      name: user.name || user.username,
      role: user.role || "user",
      avatar: user.avatar || null,
      bio: user.bio || "",
      createdAt: user.createdAt,
    };

    login(userData);
    navigate("/");
  };

  const handleRegister = async () => {
    const users = getUsers();
    
    // Check if email exists (case insensitive)
    if (users.find((u) => u.email.toLowerCase() === form.email.toLowerCase())) {
      setErrors({ email: "Email đã được sử dụng" });
      return;
    }

    // Check if username exists (case insensitive)
    if (users.find((u) => u.username.toLowerCase() === form.username.toLowerCase())) {
      setErrors({ username: "Tên người dùng đã được sử dụng" });
      return;
    }

    // Create new user
    const newUser = {
      id: `user_${Date.now()}`,
      email: form.email.toLowerCase(),
      username: form.username,
      name: form.username,
      password: form.password,
      role: "user",
      avatar: null,
      bio: "",
      createdAt: new Date().toISOString(),
    };

    users.push(newUser);
    saveUsers(users);

    setSuccessMessage("Đăng ký thành công! Vui lòng đăng nhập.");
    setIsLogin(true);
    setForm((prev) => ({ ...prev, password: "", confirmPassword: "" }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    setIsLoading(true);
    setSuccessMessage("");

    try {
      // Simulate API delay
      await new Promise((resolve) => setTimeout(resolve, 500));

      if (isLogin) {
        await handleLogin();
      } else {
        await handleRegister();
      }
    } catch (error) {
      setErrors({ general: "Có lỗi xảy ra. Vui lòng thử lại." });
    } finally {
      setIsLoading(false);
    }
  };

  const handleForgotPassword = async (e) => {
    e.preventDefault();
    if (!form.email.trim()) {
      setErrors({ email: "Vui lòng nhập email" });
      return;
    }
    if (!validateEmail(form.email)) {
      setErrors({ email: "Email không hợp lệ" });
      return;
    }

    const users = getUsers();
    const user = users.find((u) => u.email === form.email);

    if (!user) {
      setErrors({ email: "Email không tồn tại trong hệ thống" });
      return;
    }

    // In real app, send reset email
    setSuccessMessage(`Hướng dẫn đặt lại mật khẩu đã được gửi đến ${form.email}`);
    setShowForgotPassword(false);
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
                    className={`w-full pl-10 pr-4 py-3 border rounded-lg bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 focus:ring-2 focus:ring-blue-500 focus:outline-none ${
                      errors.email ? "border-red-500" : "border-gray-300 dark:border-gray-600"
                    }`}
                    placeholder="your@email.com"
                  />
                </div>
                {errors.email && (
                  <p className="text-red-500 text-sm mt-1">{errors.email}</p>
                )}
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

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4 py-8">
      <div className="w-full max-w-md">
        <div className="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
          {/* Logo */}
          <div className="text-center mb-8">
            <Link to="/" className="inline-flex items-center gap-2">
              <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-blue-700 rounded-xl flex items-center justify-center">
                <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
              </div>
              <span className="text-2xl font-bold text-gray-800 dark:text-white">eShelf</span>
            </Link>
          </div>

          {/* Tabs */}
          <div className="flex mb-6 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
            <button
              onClick={() => switchMode()}
              className={`flex-1 py-2 text-sm font-medium rounded-md transition-colors ${
                isLogin
                  ? "bg-white dark:bg-gray-600 text-gray-800 dark:text-white shadow"
                  : "text-gray-600 dark:text-gray-400"
              }`}
            >
              Đăng nhập
            </button>
            <button
              onClick={() => switchMode()}
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
            <div className="mb-4 p-3 bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-300 rounded-lg text-sm">
              {errors.general}
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
                  placeholder="your@email.com"
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
              {!isLogin && (
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  Ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số
                </p>
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

            {/* Remember me & Forgot password (Login only) */}
            {isLogin && (
              <div className="flex items-center justify-between">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    name="rememberMe"
                    checked={form.rememberMe}
                    onChange={handleChange}
                    className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-600 dark:text-gray-400">Ghi nhớ đăng nhập</span>
                </label>
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

          {/* Switch mode link */}
          <p className="text-center text-sm text-gray-600 dark:text-gray-400 mt-6">
            {isLogin ? "Chưa có tài khoản?" : "Đã có tài khoản?"}
            <button
              type="button"
              onClick={switchMode}
              className="text-blue-600 hover:text-blue-700 dark:text-blue-400 font-medium ml-1"
            >
              {isLogin ? "Đăng ký ngay" : "Đăng nhập"}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginRegister;
