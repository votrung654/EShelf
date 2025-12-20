# 🔧 Hướng Dẫn Khắc Phục Lỗi Tìm Kiếm

## 📋 Danh Sách Issues

### Issue #1: Tên sách hiển thị sai
**Triệu chứng:** Tên sách trong search results không khớp với tên gốc trong book-details.json

**Nguyên nhân có thể:**
- Sử dụng sai property name (e.g., `book.name` thay vì `book.title`)
- Hardcoded text trong component
- Mapping data không đúng

**Cách fix:**
```jsx
// File: src/pages/Search.jsx hoặc src/components/SearchResults.jsx

// ❌ SAI
<h3>{book.name}</h3>  // Property không tồn tại
<h3>Sample Book Title</h3>  // Hardcoded

// ✅ ĐÚNG
<h3>{book.title}</h3>
<p>{book.author}</p>
<p>{book.description}</p>
```

---

### Issue #2: Mở tab mới khi click sách
**Triệu chứng:** Click vào sách trong search results mở tab mới thay vì navigate

**Nguyên nhân:**
- Sử dụng `<a>` tag với `target="_blank"`
- Hoặc sử dụng `window.open()` trong onClick

**Cách fix:**
```jsx
// File: src/components/BookCard.jsx

// ❌ SAI
<a href={`/book/${book.id}`} target="_blank">
  <img src={book.coverUrl} />
</a>

// Hoặc
<div onClick={() => window.open(`/book/${book.id}`, '_blank')}>

// ✅ ĐÚNG - Sử dụng React Router Link
import { Link } from 'react-router-dom';

<Link to={`/book/${book.id}`} className="block">
  <img src={book.coverUrl} alt={book.title} />
</Link>

// Hoặc nếu phải dùng onClick
<div onClick={() => navigate(`/book/${book.id}`)}>
```

---

### Issue #3: Nút yêu thích/collections chưa hoạt động
**Triệu chứng:** Có nút nhưng click không làm gì, hoặc có quá nhiều nút trùng lặp

**Nguyên nhân:**
- Component chưa kết nối với localStorage logic
- Duplicate buttons trong các components khác nhau
- Event handlers chưa implement

**Cách fix:**
```jsx
// File: src/components/BookCard.jsx

import { useFavorites } from '../hooks/useFavorites';

const BookCard = ({ book }) => {
  const { favorites, addFavorite, removeFavorite } = useFavorites();
  const isFavorite = favorites.some(fav => fav.id === book.id);

  const handleToggleFavorite = (e) => {
    e.preventDefault(); // Prevent navigation
    e.stopPropagation();
    
    if (isFavorite) {
      removeFavorite(book.id);
    } else {
      addFavorite(book);
    }
  };

  return (
    <div className="book-card">
      {/* ...existing code... */}
      <button 
        onClick={handleToggleFavorite}
        className={isFavorite ? 'text-red-500' : 'text-gray-400'}
      >
        ❤️ {isFavorite ? 'Đã yêu thích' : 'Yêu thích'}
      </button>
    </div>
  );
};
```

**Option 2: Tạm ẩn nếu chưa sẵn sàng**
```jsx
// File: src/components/BookCard.jsx

const FEATURES_ENABLED = {
  favorites: true,  // Đã có localStorage logic
  collections: false,  // Chưa implement backend
  share: false  // Feature tương lai
};

return (
  <div className="book-card">
    {/* ...existing code... */}
    
    {FEATURES_ENABLED.favorites && (
      <button onClick={handleToggleFavorite}>❤️</button>
    )}
    
    {FEATURES_ENABLED.collections && (
      <button onClick={handleAddToCollection}>📚</button>
    )}
  </div>
);
```

---

### Issue #4: Menu links bị mất
**Triệu chứng:** Các link như Feedback, About, Contact không còn trong Header/Footer

**Nguyên nhân:**
- Code bị xóa nhầm khi refactor
- Conditional rendering không đúng
- Component không import đúng routes

**Cách fix:**
```jsx
// File: src/components/Header.jsx

import { Link } from 'react-router-dom';

const Header = () => {
  return (
    <header className="header">
      <nav>
        <Link to="/">Trang chủ</Link>
        <Link to="/search">Tìm kiếm</Link>
        <Link to="/collections">Bộ sưu tập</Link>
        <Link to="/feedback">Phản hồi</Link>
        <Link to="/about">Giới thiệu</Link>
      </nav>
    </header>
  );
};

// File: src/components/Footer.jsx

const Footer = () => {
  return (
    <footer className="footer">
      <div className="footer-links">
        <Link to="/about">Về chúng tôi</Link>
        <Link to="/contact">Liên hệ</Link>
        <Link to="/terms">Điều khoản</Link>
        <Link to="/privacy">Chính sách</Link>
        <Link to="/feedback">Góp ý</Link>
      </div>
    </footer>
  );
};
```

**Đảm bảo routes trong main.jsx:**
```jsx
// File: src/main.jsx

import Feedback from './pages/Feedback';
import About from './pages/About';
import Contact from './pages/Contact';
import Terms from './pages/Terms';

const router = createBrowserRouter([
  // ...existing routes...
  { path: '/feedback', element: <Feedback /> },
  { path: '/about', element: <About /> },
  { path: '/contact', element: <Contact /> },
  { path: '/terms', element: <Terms /> },
]);
```

---

## 🔍 Checklist Kiểm Tra

### Search Results Page
- [ ] Tên sách hiển thị chính xác từ `book.title`
- [ ] Author hiển thị đúng từ `book.author`
- [ ] Cover image load đúng từ `book.coverUrl`
- [ ] Click vào card navigate với `<Link>`, không mở tab mới
- [ ] Search query persist trong URL (?q=keyword)

### Action Buttons
- [ ] Favorite button có state (đã/chưa yêu thích)
- [ ] Click favorite cập nhật localStorage
- [ ] Icon đổi màu khi toggle
- [ ] Không có duplicate buttons
- [ ] Buttons disabled nếu chưa có logic

### Navigation
- [ ] Header có đủ các links chính
- [ ] Footer có đủ các links phụ
- [ ] Tất cả routes đã define trong router
- [ ] Không có 404 errors khi click links

### Performance
- [ ] Không có console errors (F12)
- [ ] Không có console warnings
- [ ] Search response < 500ms
- [ ] Images lazy load

---

## 🧪 Test Script

```bash
# Test tự động (optional - có thể viết sau)
npm run test:search

# Test thủ công
npm run dev

# 1. Test search
open http://localhost:5173
# → Gõ "Harry Potter" → Enter
# → Kết quả đúng, click 1 sách
# → Giữ nguyên tab, URL: /book/1

# 2. Test favorites
# → Click ❤️ trên book card
# → Icon đổi màu
# → Refresh page → state persist
# → localStorage có key "eshelf_favorites"

# 3. Test navigation
# → Click "Feedback" trong header
# → Trang /feedback mở
# → Click "About" trong footer
# → Trang /about mở

# 4. Test console
# F12 → Console tab
# → Không có errors màu đỏ
# → Có thể có warnings (không critical)
```

---

## 📚 Tài Liệu Tham Khảo

- [React Router - Link Component](https://reactrouter.com/en/main/components/link)
- [localStorage API](https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage)
- [React Event Handlers](https://react.dev/learn/responding-to-events)

---

*Cập nhật: Tháng 1/2025*