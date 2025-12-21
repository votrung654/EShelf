import { useEffect } from "react";
import { useLocation, useParams } from "react-router-dom";
import { saveReadingProgress } from "../components/book/ReadingProgress";
import { useAuth } from "../context/AuthContext";

const Reading = () => {
  const { id } = useParams();
  const location = useLocation();
  const { state } = location;
  const { user } = useAuth();

  // Handle cả 2 dạng state: string (pdfUrl) hoặc object { pdfUrl, startPage }
  const pdfUrl =
    typeof state === "string"
      ? state
      : state?.pdfUrl || state || "/pdfs/lorem-ipsum.pdf";

  // Ghi nhận đã đọc sách này
  useEffect(() => {
    if (id && user?.id) {
      saveReadingProgress(id, user.id, {
        currentPage: 1,
        totalPages: 1, // Không track được với iframe
        status: "reading",
      });
    }
  }, [id, user?.id]);

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
