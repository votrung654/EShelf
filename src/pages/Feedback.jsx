import { useState } from "react";
const Feedback = () => {
  const [errorType, setErrorType] = useState("book");
  const [content, setContent] = useState("");
  return (
    <>
      <div className="mx-20 my-12 flex flex-col justify-center gap-4 rounded border-2 border-sky-400 p-4 text-gray-800">
        <p className="text-center text-3xl font-semibold text-sky-400">
          GỬI PHẢN HỒI CHO CHÚNG TÔI
        </p>
        <div className="flex">
          <label className="w-44 px-4 py-2 text-right">Loại lỗi:</label>
          <select
            value={errorType}
            onChange={(e) => setErrorType(e.target.value)}
            className="mr-4 w-[28rem] rounded-sm p-2"
          >
            <option value="book">Lỗi sách</option>
            <option value="account">Lỗi tài khoản</option>
            <option value="donate">Lỗi donate - ủng hộ</option>
            <option value="other">Khác</option>
          </select>
          {errorType === "book" ? (
            <select className="w-[28rem] p-2">
              <option>Sách không xem được</option>
              <option>Sách sai định dạng</option>
              <option>Không đúng với lời giới thiệu</option>
              <option>Nội dung không phù hợp</option>
              <option>Khác</option>
            </select>
          ) : errorType === "account" ? (
            <select className="w-[28rem] p-2">
              <option>Tài khoản bị khoá</option>
              <option>Mất dữ liệu cá nhân</option>
              <option>Khác</option>
            </select>
          ) : errorType === "donate" ? (
            <select className="w-[28rem] p-2">
              <option>Thanh toán không đúng số tiền</option>
              <option>Chưa được hệ thống công nhận</option>
              <option>Khác</option>
            </select>
          ) : (
            ""
          )}
        </div>
        <div className="flex">
          <label className="w-44 px-4 py-2 text-right">
            <span className="text-red-600">* </span>Nội dung chi tiết:{" "}
          </label>
          <textarea
            type="text"
            className="h-36 w-[56.75rem] rounded-sm border border-gray-400 p-2 focus:outline-none"
            value={content}
            onChange={(e) => setContent(e.target.value)}
          ></textarea>
        </div>
        <button
          className="w-20 self-center rounded bg-teal-500 text-2xl text-white hover:bg-teal-400"
          onClick={() => {
            if (content) {
              let ans = confirm("Bạn có chắc chắn muốn gửi?");
              if (ans) {
                setContent("");
              }
            } else {
              alert("Vui lòng nhập nội dung chi tiết.");
            }
          }}
        >
          Gửi
        </button>
      </div>
      <div className="mx-20 mb-5 leading-8 text-gray-800">
        <p className="text-bold text-xl">Thông tin liên hệ:</p>
        <p>
          <span className="text-gray-500">Địa chỉ:</span> Toà nhà Chọc Trời,
          TP.HCM, Việt Nam
        </p>
        <p>
          <span className="text-gray-500">Số điện thoại:</span> 0123456789
        </p>
        <p className="text-gray-500">
          Email:{" "}
          <span className="cursor-pointer text-sky-400 hover:underline">
            deptrai@gmail.com
          </span>
        </p>
      </div>
    </>
  );
};

export default Feedback;
