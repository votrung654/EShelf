import Select from "react-select";
import { useState } from "react";
import genresArray from "../../data/genres.json";

const SearchForm = ({ isSearchResultPage = false, genres = [] }) => {
  const convertText = (input) => {
    if (!input) {
      return "";
    }
    const output = input
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/đ/g, "d")
      .replace(/\s+/g, "")
      .replace(/\+/g, "-");
    return output;
  };

  const convertArrayToString = (array) => {
    if (array.length === 0) {
      return "";
    }
    return array.map(convertText).join("+");
  };

  const [searchValue, setSearchValue] = useState("");

  const [advancedSearch, setAdvancedSearch] = useState(
    genres.length > 0 || isSearchResultPage,
  );

  const [fromYear, setFromYear] = useState("");
  const [toYear, setToYear] = useState("");

  const languageOptions = [
    { value: "Tiếng Anh", label: "Tiếng Anh" },
    { value: "Tiếng Việt", label: "Tiếng Việt" },
  ];
  const [selectedLanguages, setSelectedLanguages] = useState(null);

  const genreOptions = genresArray.map((genre) => {
    return {
      value: genre,
      label: genre,
    };
  });
  const [selectedGenres, setSelectedGenres] = useState(null);
  if (genres.length > 0) {
    setSelectedGenres(genres);
  }

  return (
    <>
      <div className="mx-4 mb-2 mt-8 flex border border-gray-400 hover:outline hover:outline-1 hover:outline-sky-400 md:mx-24 lg:mx-44">
        <input
          type="text"
          value={searchValue}
          onChange={(e) => setSearchValue(e.target.value)}
          placeholder="Tìm kiếm theo tên sách, tên tác giả, nxb..."
          className="w-full px-3 text-gray-800 focus:outline-none"
        />
        <a
          href={`${searchValue || fromYear || toYear || genres.length > 0 ? "/search/" + convertText(searchValue) + "&" + fromYear + "-" + toYear + "&" + convertArrayToString(genres) : ""}`}
        >
          <button className="border-l border-l-gray-400 bg-gray-200 px-6 py-2 text-gray-600 md:px-12">
            Tìm
          </button>
        </a>
      </div>
      {advancedSearch ? (
        <div className="mx-4 flex flex-col text-[0.9rem] md:mx-24 md:flex-row lg:mx-44">
          <div>
            <input
              type="number"
              value={fromYear}
              onChange={(e) => setFromYear(e.target.value)}
              placeholder="Từ năm"
              className="mr-5 w-24 rounded border border-gray-300 px-3 py-[0.42rem] text-gray-800 [appearance:textfield] focus:outline-none [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
            />
            <input
              type="number"
              value={toYear}
              onChange={(e) => setToYear(e.target.value)}
              placeholder="Đến năm"
              className="mr-5 w-24 rounded border border-gray-300 py-[0.42rem] pl-3 pr-2 text-gray-800 [appearance:textfield] focus:outline-none [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"
            />
          </div>

          <Select
            defaultValue={selectedLanguages}
            onChange={setSelectedLanguages}
            options={languageOptions}
            placeholder="Chọn ngôn ngữ"
            className="mr-5 w-52 text-gray-800"
            isMulti
          />
          <Select
            value={selectedGenres}
            onChange={setSelectedGenres}
            options={genreOptions}
            placeholder="Chọn thể loại"
            className="w-60 text-gray-800 placeholder-pink-600"
            isMulti
          />
        </div>
      ) : (
        <p
          onClick={() => {
            setAdvancedSearch(true);
          }}
          className="ml-4 w-[8.4rem] cursor-pointer border-b border-dashed border-gray-400 text-sm text-gray-400 md:ml-24 lg:ml-44"
        >
          Tìm kiếm nâng cao
        </p>
      )}
    </>
  );
};

export default SearchForm;
