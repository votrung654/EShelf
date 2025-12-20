import { useState, useRef, useEffect } from "react";
import { Link } from "react-router-dom";
import {
  Menu,
  X,
  List,
  Star,
  CircleDollarSign,
  MessageSquareWarning,
} from "lucide-react";

const Dropdown = () => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef(null);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };
  const handleClickOutside = (event) => {
    if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
      setIsOpen(false);
    }
  };

  useEffect(() => {
    document.addEventListener("mousedown", handleClickOutside);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={toggleDropdown}
        className={`flex h-10 w-10 items-center justify-center text-black opacity-70 transition-transform duration-300 hover:opacity-100 ${
          isOpen ? "rotate-90" : ""
        }`}
      >
        {isOpen ? <X size={32} /> : <Menu size={32} />}{" "}
      </button>

      {isOpen && (
        <div className="absolute right-0 z-10 mt-2 w-48 rounded-md bg-white text-gray-800 shadow-lg">
          <Link
            onClick={() => setIsOpen(false)}
            to="genres"
            className="block cursor-pointer px-4 py-2 hover:bg-black hover:text-white"
          >
            <List className="mr-3 inline" />
            Thể Loại
          </Link>
          <Link
            onClick={() => setIsOpen(false)}
            to="/"
            className="block cursor-pointer px-4 py-2 hover:bg-black hover:text-white"
          >
            <Star className="mr-3 inline" />
            Review Sách
          </Link>
          <Link
            onClick={() => setIsOpen(false)}
            to="feedback"
            className="block cursor-pointer px-4 py-2 hover:bg-black hover:text-white"
          >
            <MessageSquareWarning className="mr-3 inline" />
            Báo Lỗi
          </Link>
          <Link
            onClick={() => setIsOpen(false)}
            to="donate"
            className="block cursor-pointer px-4 py-2 hover:bg-black hover:text-white"
          >
            <CircleDollarSign className="mr-3 inline" />
            Ủng Hộ
          </Link>
        </div>
      )}
    </div>
  );
};

export default Dropdown;
