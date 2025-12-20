import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App.jsx";
import "./styles/global.css";
import { createBrowserRouter, RouterProvider } from "react-router-dom";
import ErrorPage from "./pages/ErrorPage.jsx";
import Genres from "./pages/Genres.jsx";
import Feedback from "./pages/Feedback.jsx";
import Donate from "./pages/Donate.jsx";
import LoginRegister from "./pages/LoginRegister.jsx";
import BookDetail from "./pages/BookDetail.jsx";
import HomePage from "./pages/HomePage.jsx";
import SearchResult from "./pages/SearchResult.jsx";
import Reading from "./pages/Reading.jsx";
import UserProfile from "./pages/UserProfile.jsx";
import Collections from "./pages/Collections.jsx";
import CollectionDetail from "./pages/CollectionDetail.jsx";
import ReadingHistory from "./pages/ReadingHistory.jsx";
import { ThemeProvider } from "./context/ThemeContext";
import { AuthProvider } from './context/AuthContext';
import AdminLayout from './admin/layouts/AdminLayout';
import Dashboard from './admin/pages/Dashboard';
import AdminBooks from './admin/pages/AdminBooks';
import AdminUsers from './admin/pages/AdminUsers';
import AdminGenres from './admin/pages/AdminGenres';
import AdminFeedback from './admin/pages/AdminFeedback';
import AdminSettings from './admin/pages/AdminSettings';
import ProtectedRoute from './admin/components/ProtectedRoute';
import About from './pages/About';
import Contact from './pages/Contact';
import Terms from './pages/Terms';
import Privacy from './pages/Privacy';

const router = createBrowserRouter([
  {
    path: "/",
    errorElement: <ErrorPage />,
    element: <App />,
    children: [
      {
        index: true,
        element: <HomePage />,
      },
      {
        path: "genres",
        element: <Genres />,
      },
      {
        path: "search/:searchvalues",
        element: <SearchResult />,
      },
      {
        path: "feedback",
        element: <Feedback />,
      },
      {
        path: "donate",
        element: <Donate />,
      },
      {
        path: "/book/:id",
        element: <BookDetail />,
      },
      {
        path: "/feedback",
        element: <Feedback />,
      },
      {
        path: "/profile",
        element: <UserProfile />,
      },
      {
        path: "/collections",
        element: <Collections />,
      },
      {
        path: "/collections/:id",
        element: <CollectionDetail />,
      },
      {
        path: "/reading-history",
        element: <ReadingHistory />,
      },
    ],
  },
  {
    path: "auth",
    element: <LoginRegister />,
  },
  {
    path: "reading/:id",
    element: <Reading />,
  },
  {
    path: "/admin",
    element: (
      <ProtectedRoute>
        <AdminLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Dashboard /> },
      { path: "books", element: <AdminBooks /> },
      { path: "users", element: <AdminUsers /> },
      { path: "genres", element: <AdminGenres /> },
      { path: "feedback", element: <AdminFeedback /> },
      { path: "settings", element: <AdminSettings /> },
    ],
  },
  {
    path: "/login",
    element: <LoginRegister />,
  },
  {
    path: '/about',
    element: <About />
  },
  {
    path: '/contact',
    element: <Contact />
  },
  {
    path: '/terms',
    element: <Terms />
  },
  {
    path: '/privacy',
    element: <Privacy />
  },
]);

createRoot(document.getElementById("root")).render(
  <StrictMode>
    <ThemeProvider>
      <AuthProvider>
        <RouterProvider router={router} />
      </AuthProvider>
    </ThemeProvider>
  </StrictMode>,
);
