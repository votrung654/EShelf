import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { useNavigate } from "react-router-dom";

const Register = ({ setAuthProcess }) => {
  const navigate = useNavigate();
  const [isPwVisible, SetIsPwVisible] = useState(false);
  const handleEyeClick = () => {
    SetIsPwVisible(!isPwVisible);
  };
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordAgain, setPasswordAgain] = useState("");

  const validateAccount = () => {
    if (!username) {
      alert("> Tên tài khoản không được trống.");
      return false;
    }
    if (!email) {
      alert("> Email không được trống.");
      return false;
    }
    if (!password) {
      alert("> Mật khẩu không được trống.");
      return false;
    }
    let warnings = [];
    if (!/^[a-zA-Z0-9_]{3,15}$/.test(username)) {
      warnings.push(
        "> Tên tài khoản chỉ chứa [A-Z], [a-z], [0-9] và ký tự _. Độ dài phải từ 3-15 ký tự.",
      );
    }
    if (!/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email)) {
      warnings.push("> Định dạng email không hợp lệ.");
    }
    if (
      !/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@.#$!%*?&])[A-Za-z\d@.#$!%*?&]{8,15}$/.test(
        password,
      )
    ) {
      warnings.push(
        "> Mật khẩu phải chứa ít nhất 1 chữ cái viết hoa, 1 chữ cái viết thường, 1 số và 1 ký tự đặc biệt. Độ dài phải từ 8-15 ký tự.",
      );
    }
    if (password !== passwordAgain) {
      warnings.push("> Nhập lại mật khẩu không khớp.");
    }
    if (warnings.length > 0) {
      alert(warnings.join("\n"));
      return false;
    }
    return true;
  };

  return (
    <>
      <p className="text-2xl opacity-90">Đăng Ký</p>
      <input
        type="text"
        className="w-full border border-gray-300 p-2 text-gray-800 focus:outline-none"
        placeholder="Tên tài khoản"
        value={username}
        onChange={(e) => {
          setUsername(e.target.value);
        }}
      />
      <input
        type="email"
        className="w-full border border-gray-300 p-2 text-gray-800 focus:outline-none"
        placeholder="Email"
        value={email}
        onChange={(e) => {
          setEmail(e.target.value);
        }}
      />
      <div className="relative">
        <input
          type={isPwVisible ? "text" : "password"}
          className="w-full border border-gray-300 p-2 pr-9 focus:outline-none"
          placeholder="Mật khẩu"
          value={password}
          onChange={(e) => {
            setPassword(e.target.value);
          }}
        />
        {isPwVisible ? (
          <Eye
            className="absolute right-1 top-1/2 -translate-y-1/2 transform text-gray-800"
            onClick={handleEyeClick}
          />
        ) : (
          <EyeOff
            className="absolute right-1 top-1/2 -translate-y-1/2 transform text-gray-500"
            onClick={handleEyeClick}
          />
        )}
      </div>
      <div className="relative">
        <input
          type={isPwVisible ? "text" : "password"}
          className="w-full border border-gray-300 p-2 pr-9 focus:outline-none"
          placeholder="Nhập lại mật khẩu"
          value={passwordAgain}
          onChange={(e) => {
            setPasswordAgain(e.target.value);
          }}
        />
        {isPwVisible ? (
          <Eye
            className="absolute right-1 top-1/2 -translate-y-1/2 transform text-gray-800"
            onClick={handleEyeClick}
          />
        ) : (
          <EyeOff
            className="absolute right-1 top-1/2 -translate-y-1/2 transform text-gray-500"
            onClick={handleEyeClick}
          />
        )}
      </div>
      <button
        className="block w-full bg-sky-500 py-1 text-white hover:bg-sky-400"
        onClick={() => {
          if (validateAccount()) navigate("/");
        }}
      >
        Đăng ký
      </button>
      <div className="flex gap-2">
        <p className="text-gray-600">Bạn đã có tài khoản?</p>
        <div
          onClick={() => setAuthProcess("login")}
          className="flex flex-grow cursor-pointer justify-center rounded-sm border border-gray-300"
        >
          <p>Đăng Nhập</p>
        </div>
      </div>
    </>
  );
};

export default Register;
