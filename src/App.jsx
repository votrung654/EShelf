import Header from "./components/layout/header/Header.jsx";
import Footer from "./components/layout/footer/Footer.jsx";
import { Outlet } from "react-router-dom";

const App = () => {
  return (
    <div className="flex min-h-screen flex-col bg-slate-50 dark:bg-gray-900 text-gray-900 dark:text-gray-100 transition-colors">
      <Header />
      <Outlet />
      <Footer />
    </div>
  );
};

export default App;
