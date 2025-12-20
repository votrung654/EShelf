const Contact = () => (
  <div className="container mx-auto px-4 py-8 max-w-2xl">
    <h1 className="text-3xl font-bold mb-6 dark:text-white">Liên hệ</h1>
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 space-y-4">
      <div>
        <h3 className="font-semibold">Email</h3>
        <p className="text-gray-600 dark:text-gray-400">support@eshelf.vn</p>
      </div>
      <div>
        <h3 className="font-semibold">Hotline</h3>
        <p className="text-gray-600 dark:text-gray-400">1900 xxxx</p>
      </div>
      <div>
        <h3 className="font-semibold">Địa chỉ</h3>
        <p className="text-gray-600 dark:text-gray-400">
          123 Đường ABC, TP. Hồ Chí Minh
        </p>
      </div>
    </div>
  </div>
);

export default Contact;
