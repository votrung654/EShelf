import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { Link } from "react-router-dom";

const Login = (props) => {
  const { setAuthProcess } = props;
  const [isPwVisible, SetIsPwVisible] = useState(false);
  const handleEyeClick = () => {
    SetIsPwVisible(!isPwVisible);
  };
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  return (
    <>
      <p className="text-2xl opacity-90">Đăng Nhập</p>
      <input
        type="text"
        className="w-full border border-gray-300 p-2 text-gray-800 focus:outline-none"
        placeholder="Tên tài khoản"
        value={username}
        onChange={(e) => {
          setUsername(e.target.value);
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
      <Link
        className="w-32 text-sm text-gray-600 underline"
        onClick={() => setAuthProcess("forgot-password")}
        to="#"
      >
        Quên mật khẩu?
      </Link>
      <Link className="block w-full" to={username && password ? "/" : "#"}>
        <button className="w-full bg-sky-500 py-1 text-white hover:bg-sky-400">
          Đăng nhập
        </button>
      </Link>
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

export default Login;
