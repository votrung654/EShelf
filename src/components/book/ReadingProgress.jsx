import { Link } from 'react-router-dom';
import api from '../../utils/api';

// Get reading progress from backend API
export async function getReadingProgress(bookIsbn, userId) {
  if (!userId || !bookIsbn) return null;
  
  try {
    const progress = await api.readingProgress.get(bookIsbn, userId);
    return progress;
  } catch (e) {
    console.error('Failed to get reading progress:', e);
    return null;
  }
}

// Save reading progress to backend API
export async function saveReadingProgress(bookIsbn, userId, data) {
  if (!userId || !bookIsbn) return;
  
  try {
    await api.readingProgress.update(bookIsbn, {
      page: data.currentPage || data.page,
      percentage: data.percentage,
      lastReadAt: new Date().toISOString(),
    });
  } catch (e) {
    console.error('Failed to save reading progress:', e);
  }
}

export function getAllReadingProgress() {
  try {
    const saved = localStorage.getItem(PROGRESS_BASE_KEY);
    return saved ? JSON.parse(saved) : {};
  } catch (e) {
    console.error('Failed to get all reading progress:', e);
    return {};
  }
}

export function formatTimeAgo(dateString) {
  if (!dateString) return 'Chưa đọc';
  const date = new Date(dateString);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return 'Vừa xong';
  if (diffMins < 60) return `${diffMins} phút trước`;
  if (diffHours < 24) return `${diffHours} giờ trước`;
  if (diffDays < 7) return `${diffDays} ngày trước`;
  return date.toLocaleDateString('vi-VN');
}

export default function ReadingProgress({ book, progress }) {
  if (!progress) return null;

  return (
    <div className="mt-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
          </svg>
          <span className="text-sm font-medium text-blue-800">Đang đọc</span>
        </div>
        <span className="text-xs text-blue-600">
          Đọc lần cuối: {formatTimeAgo(progress.lastReadAt)}
        </span>
      </div>

      <Link
        to={`/reading/${book.isbn}`}
        state={book.pdfUrl}
        className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        Tiếp tục đọc
      </Link>
    </div>
  );
}
