import { Link } from "react-router-dom";
import { useMemo } from "react";

const SuggestedBooks = ({
  heading,
  totalDisplayedBooks = 6,
  bookDetails = [],
  chosenBookIsbn = null,
}) => {
  const { relatedBooks, suggestedBooks } = useMemo(() => {
    if (!bookDetails || bookDetails.length === 0) {
      return { relatedBooks: [], suggestedBooks: [] };
    }

    // Filter out the chosen book
    const filteredBooks = chosenBookIsbn
      ? bookDetails.filter(
          (book) => book.isbn?.trim() !== chosenBookIsbn?.trim()
        )
      : [...bookDetails];

    const chosenBook = chosenBookIsbn
      ? bookDetails.find(
          (book) => book.isbn?.trim() === chosenBookIsbn?.trim()
        )
      : null;

    const related = [];
    const suggested = [];
    const usedIsbns = new Set(); // Track used ISBNs to avoid duplicates

    for (const book of filteredBooks) {
      if (usedIsbns.has(book.isbn)) continue; // Skip duplicates

      if (related.length + suggested.length >= totalDisplayedBooks) break;

      if (
        chosenBook &&
        chosenBook.genres &&
        book.genres &&
        chosenBook.genres.some((genre) => book.genres.includes(genre))
      ) {
        related.push(book);
      } else {
        suggested.push(book);
      }
      usedIsbns.add(book.isbn);
    }

    // Shuffle suggested books
    const shuffled = [...suggested].sort(() => Math.random() - 0.5);

    return { relatedBooks: related, suggestedBooks: shuffled };
  }, [bookDetails, chosenBookIsbn, totalDisplayedBooks]);

  // Combine and ensure unique keys
  const allBooks = useMemo(() => {
    const combined = [...relatedBooks, ...suggestedBooks];
    const seen = new Set();
    return combined.filter((book) => {
      if (seen.has(book.isbn)) return false;
      seen.add(book.isbn);
      return true;
    });
  }, [relatedBooks, suggestedBooks]);

  if (allBooks.length === 0) return null;

  return (
    <>
      <p className="mb-5 border-b-2 border-b-sky-400 pb-2 text-xl text-sky-400 dark:text-sky-300 dark:border-b-sky-500">
        {heading}
      </p>
      <div className="mb-10 flex flex-wrap justify-around gap-y-3 md:justify-between">
        {allBooks.map((book, index) => (
          <Link
            to={`/book/${book.isbn}`}
            key={`${book.isbn}-${index}`}
            state={{ book }}
          >
            <img
              src={book.coverUrl}
              className="aspect-[5/7] w-48 rounded-sm object-cover drop-shadow-[0_0.2rem_0.2rem_rgba(0,0,0,0.5)] 2xl:w-52 hover:scale-105 transition-transform"
              title={book.title}
              alt={"Bìa " + book.title}
              onError={(e) => {
                e.target.src = '/images/book-placeholder.svg';
              }}
            />
          </Link>
        ))}
      </div>
    </>
  );
};

export default SuggestedBooks;
