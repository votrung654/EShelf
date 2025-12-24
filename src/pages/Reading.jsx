import { useEffect } from "react";
import { useLocation, useParams } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import { historyAPI } from "../services/api";

const Reading = () => {
  const { id } = useParams();
  const location = useLocation();
  const { state } = location;
  const { isAuthenticated, user } = useAuth();

  // Handle cả 2 dạng state: string (pdfUrl) hoặc object { pdfUrl, startPage }
  const pdfUrl =
    typeof state === "string"
      ? state
      : state?.pdfUrl || state || "/pdfs/lorem-ipsum.pdf";

  // Ghi nhận đã đọc sách này - Chỉ lưu 1 lần khi component mount
  useEffect(() => {
    let isMounted = true;
    let saved = false; // Flag để prevent duplicate saves

    const saveProgress = async () => {
      if (!id || !isAuthenticated || !user?.id || saved) return;
      
      saved = true; // Đánh dấu đã save
      
      try {
        // Lưu progress vào backend API (upsert sẽ tự động update nếu đã có)
        await historyAPI.saveProgress({
          bookId: id,
          currentPage: 1,
          totalPages: 1,
        });
      } catch (error) {
        console.error('Error saving reading progress:', error);
        saved = false;
      }
    };

    if (isMounted) {
      saveProgress();
    }

    return () => {
      isMounted = false;
    };
  }, [id, isAuthenticated, user?.id]);

  return (
    <iframe
      src={pdfUrl}
      frameBorder="0"
      className="h-screen w-screen"
      title="PDF Reader"
    />
  );
};

export default Reading;
