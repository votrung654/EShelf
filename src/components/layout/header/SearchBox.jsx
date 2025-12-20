import { useState, useRef, useEffect } from "react";
import { Search } from "lucide-react";

const SearchBox = ({ setIsSearchBoxOpen }) => {
  const convertText = (term) => {
    const output = term
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/đ/g, "d")
      .replace(/\s+/g, "")
      .replace(/\+/g, "-");
    return output;
  };

  const [isEditing, setIsEditing] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const toggleEditing = () => {
    setIsEditing(true);
    setIsSearchBoxOpen(true);
  };
  const searchBoxRef = useRef(null);
  const handleClickOutside = (event) => {
    if (searchBoxRef.current && !searchBoxRef.current.contains(event.target)) {
      setIsEditing(false);
      setIsSearchBoxOpen(false);
      setSearchTerm("");
    }
  };

  useEffect(() => {
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  return (
    <>
      {isEditing ? (
        <div
          className="flex rounded border bg-white px-2 py-1"
          ref={searchBoxRef}
        >
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="mr-2 text-gray-800 focus:outline-none"
            placeholder="Tìm kiếm sách"
          />
          <a
            href={`/search/${convertText(searchTerm)}&-&`}
            className="rounded p-1 hover:bg-gray-300"
          >
            <Search size={20} color="#888" />
          </a>
        </div>
      ) : (
        <button
          className="text-black opacity-70 hover:opacity-100"
          onClick={toggleEditing}
        >
          <Search size={28} />
        </button>
      )}
    </>
  );
};

export default SearchBox;
