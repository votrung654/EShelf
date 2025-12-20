const Quote = () => {
  const quotes = [
    {
      quote: "Đọc sách mang đến cho chúng ta những người bạn không quen biết.",
      author: "Honoré de Balzac",
    },
    {
      quote:
        "Sách là một linh hồn, còn người đọc là những người sáng tạo nên cuộc sống.",
      author: "Carl Sagan",
    },
    {
      quote: "Đọc muôn quyển sách, đi muôn dặm đường.",
      author: "Thành ngữ",
    },
    {
      quote: "Một ngôi nhà không có sách như một người không có tâm hồn.",
      author: "Tullius Cicero",
    },
    {
      quote: "Sách là phép màu độc nhất và diệu kỳ trong đời thực.",
      author: "Stephen King",
    },
    {
      quote:
        "Sách phá vỡ xiềng xích của thời gian và là minh chứng rõ ràng cho việc con người có thể tạo ra điều kỳ diệu.",
      author: "Carl Sagan",
    },
    {
      quote:
        "Đọc sách là điều cần thiết cho những ai muốn vươn lên tầm thường.",
      author: "Jim Rohn",
    },
    {
      quote:
        "Đọc sách là liều thuốc kích thích sự phát triển của trái tim và tâm hồn hơn bất kỳ phương pháp chữa lành nào khác.",
      author: "Catherynne M. Valente",
    },
  ];
  let index = Math.floor(Math.random() * quotes.length);

  return (
    <div className="mx-auto mt-4 w-4/5 text-center text-sm italic text-gray-600 md:w-2/5">
      <p>“{quotes[index].quote}”</p>
      <p className="text-right">&#65123;{quotes[index].author}</p>
    </div>
  );
};

export default Quote;
