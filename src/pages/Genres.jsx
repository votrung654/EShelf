import { useState } from "react";
import genres from "../data/genres.json";
import bookDetails from "../data/book-details.json";

const Genres = () => {
  const [searchGenre, setSearchGenre] = useState("");
  const [filteredGenres, setFilteredGenres] = useState(genres);
  const handleTypeSearchGenre = (term) => {
    setSearchGenre(term);
    setFilteredGenres(
      genres.filter((genre) =>
        genre
          .toLowerCase()
          .normalize("NFD")
          .replace(/[\u0300-\u036f]/g, "")
          .replace(/đ/g, "d")
          .includes(term.trim().toLowerCase()),
      ),
    );
  };
  const countBooksByGenre = (genre) => {
    if (!bookDetails) return 0;
    let count = 0;
    bookDetails.forEach((bookDetail) => {
      if (bookDetail.genres && bookDetail.genres.includes(genre)) {
        count++;
      }
    });
    return count;
  };

  return (
    <div className="px-28 py-8">
      <p className="mb-8 cursor-default text-sm text-gray-400">
        <a className="cursor-pointer text-sky-400" href="/">
          Trang Chính
        </a>
        {" > "} <a className="cursor-pointer">Thể Loại</a>
      </p>
      <div className="mb-3 flex flex-wrap justify-between">
        <h1
          className="text-2xl font-bold text-gray-700"
          style={{ fontFamily: "Arial, sans-serif" }}
        >
          Tất Cả Thể Loại
        </h1>
        <input
          type="text"
          value={searchGenre}
          onChange={(e) => handleTypeSearchGenre(e.target.value)}
          className="mt-3 w-64 rounded-sm border border-gray-300 px-3 py-1 text-gray-500 focus:outline-none md:mt-0"
          placeholder="Tìm kiếm thể loại"
        />
      </div>
      <div className="grid grid-cols-1 gap-y-1.5 md:grid-cols-3">
        {filteredGenres &&
          filteredGenres.map((genre) => (
            <a
              href=""
              className="text-gray-600 hover:text-sky-400"
              key={crypto.randomUUID()}
            >
              {genre + " "}
              <span className="text-sm italic text-gray-400">
                ({countBooksByGenre(genre.trim())})
              </span>
            </a>
          ))}
      </div>
    </div>
  );
};

export default Genres;
