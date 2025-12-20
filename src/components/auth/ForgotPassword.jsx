import { Link } from "react-router-dom";
import { useState } from "react";

const ForgotPassword = ({ setAuthProcess }) => {
  const [isInvalidEmail, setIsInvalidEmail] = useState(true);
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const handleValidateEmail = () => {
    if (email) {
      setIsInvalidEmail(false);
    }
  };

  return (
    <>
      {isInvalidEmail ? (
        <p className="text-xl opacity-90">Nhập email để nhận mã xác thực</p>
      ) : (
        <p className="text-center text-xl opacity-90">
          Vui lòng nhập mã số xác thực mà chúng tôi đã gửi tới email của bạn
        </p>
      )}

      <input
        type={isInvalidEmail ? "email" : "number"}
        className={`w-full border border-gray-300 p-2 text-gray-800 focus:outline-none ${isInvalidEmail ? "" : "[appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none [&::-webkit-outer-spin-button]:appearance-none"}`}
        placeholder={isInvalidEmail ? "Email" : "Mã xác thực"}
        value={isInvalidEmail ? email : code}
        onChange={(e) => {
          if (isInvalidEmail) {
            setEmail(e.target.value);
          } else {
            setCode(e.target.value);
          }
        }}
      />
      {isInvalidEmail ? (
        <button
          className="block bg-sky-500 py-1 text-white hover:bg-sky-400"
          onClick={handleValidateEmail}
        >
          Gửi yêu cầu
        </button>
      ) : (
        <Link className="block w-full" to={code ? "/" : "#"}>
          <button className="w-full bg-sky-500 py-1 text-white hover:bg-sky-400">
            Xác nhận
          </button>
        </Link>
      )}
      <div className="flex gap-2">
        <p className="text-gray-600" href="#">
          Bạn chưa có tài khoản?
        </p>
        <div
          onClick={() => setAuthProcess("register")}
          className="flex flex-grow cursor-pointer justify-center rounded-sm border border-gray-300"
        >
          <p>Đăng Ký</p>
        </div>
      </div>
    </>
  );
};

export default ForgotPassword;
