import SearchForm from "../components/book/SearchForm.jsx";
import SuggestedBooks from "../components/book/SuggestedBooks.jsx";
import Logo from "../components/common/Logo.jsx";
import Quote from "../components/common/Quote.jsx";
import bookDetails from "../data/book-details.json";

const HomePage = () => {
  return (
    <>
      <div className="mt-12 md:mt-20 lg:mt-24">
        <Logo fontSize="text-7xl" />
        <Quote />
      </div>
      <SearchForm />
      <div className="mx-4 mt-16 md:mx-24 lg:mx-44">
        <SuggestedBooks
          heading="Tủ sách gợi ý"
          bookDetails={bookDetails}
          totalDisplayedBooks={180}
        />
      </div>
      {/* Example card with dark mode classes */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-md dark:shadow-gray-900/50 p-6 transition-colors">
        <h2 className="text-xl font-bold text-gray-800 dark:text-gray-100">
          Example Book Title
        </h2>
        <p className="text-gray-600 dark:text-gray-400">
          This is a description of the book that is being suggested. It provides
          insight into the content and encourages users to read more.
        </p>
      </div>
      {/* Example button with dark mode classes */}
      <button className="bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white">
        Read More
      </button>
      {/* Example link with dark mode classes */}
      <a className="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300">
        View Details
      </a>
    </>
  );
};

export default HomePage;
