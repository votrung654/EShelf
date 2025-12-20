import { useParams } from "react-router-dom";
import SearchForm from "../components/book/SearchForm";
import SearchResultItem from "../components/book/SearchResultItem";
import Logo from "../components/common/Logo.jsx";
import bookDetails from "../data/book-details.json";

const SearchResult = () => {
  const normalizeText = (input) => {
    if (!input) {
      return "";
    }
    const normalized = input
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/đ/g, "d")
      .replace(/\s+/g, "");
    return normalized;
  };

  const searchByKeyword = (keyword, bookDetail) => {
    return (
      (keyword !== "" &&
        bookDetail &&
        bookDetail.title &&
        normalizeText(bookDetail.title).includes(keyword)) ||
      (bookDetail.author &&
        bookDetail.author.some((au) => normalizeText(au).includes(keyword))) ||
      (bookDetail.author &&
        normalizeText(bookDetail.publisher).includes(keyword))
    );
  };

  const searchByTimes = (times, bookDetail) => {
    return (
      bookDetail &&
      bookDetail.year &&
      times.length > 0 &&
      ((times[0] !== "" && bookDetail.year >= Number(times[0])) ||
        (times[1] !== "" && bookDetail.year <= Number(times[1])))
    );
  };

  const searchByGenres = (searchGenres, bookDetail) => {
    return (
      bookDetail &&
      bookDetail.genres &&
      searchGenres.length > 0 &&
      searchGenres.some((searchGenre) =>
        bookDetail.genres.map((genre) => {
          genre.includes(searchGenre);
        }),
      )
    );
  };

  const { searchvalues } = useParams();

  const searchValues = searchvalues ? searchvalues.split("&") : [];

  const times =
    searchValues.length > 0 && searchValues[1]
      ? searchValues[1].split("-")
      : [];

  const searchGenres =
    searchValues.length > 0 && searchValues[2]
      ? searchValues[2].split("+")
      : [];

  const matchedBookDetails =
    bookDetails && searchValues.length > 0
      ? bookDetails.filter((bookDetail) => {
          return (
            searchByKeyword(searchValues[0], bookDetail) ||
            searchByTimes(times, bookDetail) ||
            searchByGenres(searchGenres, bookDetail)
          );
        })
      : [];

  return (
    <div className="mt-8 md:mt-12 lg:mt-16">
      <Logo fontSize="text-7xl" />
      <SearchForm isSearchResultPage={true} />
      <p
        className={`relative top-[1px] ml-4 mt-10 inline-block border border-b-0 border-gray-400 bg-white px-4 py-1 text-lg text-teal-800 md:ml-24 lg:mx-44 ${matchedBookDetails.length === 0 ? "mb-60 border-b-[1px]" : ""}`}
      >
        Tìm thấy {matchedBookDetails.length} cuốn sách
      </p>
      {matchedBookDetails.length > 0 && (
        <div className="mx-4 mb-6 border border-b-0 border-gray-400 bg-white md:mx-24 lg:mx-44">
          {matchedBookDetails.map((bookDetail) => {
            return (
              <div
                className="border-b border-gray-400"
                key={crypto.randomUUID()}
              >
                <SearchResultItem bookDetail={bookDetail} />
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};

export default SearchResult;
