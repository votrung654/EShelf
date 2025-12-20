import { useRouteError } from "react-router-dom";
import Logo from "../components/common/Logo.jsx";

export default function ErrorPage() {
  const error = useRouteError();
  console.error(error);

  return (
    <div id="error-page" className="h-screen bg-red-100 pt-12 text-center">
      <Logo fontSize="text-7xl" />
      <div className="mt-24 text-4xl text-rose-600">
        <h1 className="mb-4 text-5xl">Úi!</h1>
        <p className="mb-4">Bình tĩnh huynh ơi.</p>
        <p>
          Lỗi: <i>{error.statusText || error.message}</i>
        </p>
      </div>
    </div>
  );
}
