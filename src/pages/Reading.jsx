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

  // Ghi nhận đã đọc sách này - Gọi API thay vì localStorage
  useEffect(() => {
    const saveProgress = async () => {
      if (!id || !isAuthenticated || !user?.id) return;
      
      try {
        // Lưu progress vào backend API
        await historyAPI.saveProgress({
          bookId: id,
          currentPage: 1,
          totalPages: 1, // Không track được với iframe
        });
      } catch (error) {
        console.error('Error saving reading progress:', error);
        // Không hiển thị lỗi để không làm gián đoạn việc đọc
      }
    };

    saveProgress();
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
