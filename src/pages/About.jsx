const About = () => (
  <div className="container mx-auto px-4 py-8 max-w-4xl">
    <h1 className="text-3xl font-bold mb-6 dark:text-white">Về eShelf</h1>
    <div className="prose dark:prose-invert max-w-none">
      <p className="text-lg mb-4">eShelf là nền tảng đọc sách trực tuyến hàng đầu tại Việt Nam.</p>
      <h2 className="text-2xl font-semibold mt-6 mb-4">Sứ mệnh</h2>
      <p>Đem tri thức đến gần hơn với mọi người thông qua công nghệ hiện đại.</p>
      <h2 className="text-2xl font-semibold mt-6 mb-4">Tính năng</h2>
      <ul className="list-disc pl-6 space-y-2">
        <li>Thư viện 10,000+ đầu sách</li>
        <li>Đọc trực tuyến mọi lúc mọi nơi</li>
        <li>Theo dõi tiến độ đọc tự động</li>
        <li>Bộ sưu tập cá nhân hóa</li>
      </ul>
    </div>
  </div>
);

export default About;
