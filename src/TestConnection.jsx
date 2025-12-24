import { useState } from 'react';
import axios from 'axios';
import { authAPI } from './services/api'; // Import cái api bạn vừa sửa

const TestConnection = () => {
  const [logs, setLogs] = useState([]);

  const addLog = (msg, type = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs(prev => [`[${timestamp}] [${type}] ${msg}`, ...prev]);
  };

  // Test 1: Gọi thẳng vào Gateway bằng Axios trần (Không qua api.js)
  const testDirectGateway = async () => {
    addLog('--- BẮT ĐẦU TEST 1: GỌI TRỰC TIẾP GATEWAY ---');
    try {
      // Gọi thử vào health check của gateway
      const res = await axios.get('http://localhost:3000/health');
      addLog(`Gateway Health: ${JSON.stringify(res.data)}`, 'success');
    } catch (err) {
      addLog(`Gateway Chết hoặc sai URL: ${err.message}`, 'error');
    }
  };

  // Test 2: Test Login Admin bằng api.js
  const testLogin = async () => {
    addLog('--- BẮT ĐẦU TEST 2: LOGIN ADMIN ---');
    try {
      addLog('Đang gọi authAPI.login("admin@eshelf.com", "Admin123!")...');
      const res = await authAPI.login({
        email: "admin@eshelf.com",
        password: "Admin123!"
      });
      
      addLog(`Kết quả trả về: ${JSON.stringify(res)}`, 'success');
      
      if (res.data && res.data.accessToken) {
        addLog('LOGIN THÀNH CÔNG! Token đã nhận được.', 'success');
      } else {
        addLog('Login chạy được nhưng không thấy Token?', 'warning');
      }
    } catch (err) {
      const backendError = err.response?.data;
      addLog(`LOGIN THẤT BẠI: ${JSON.stringify(backendError || err.message)}`, 'error');
      console.error(err);
    }
  };

  return (
    <div style={{ padding: 20, fontFamily: 'monospace', backgroundColor: '#1e1e1e', color: '#fff', minHeight: '100vh' }}>
      <h1>BẢNG ĐIỀU KHIỂN DEBUG</h1>
      
      <div style={{ marginBottom: 20 }}>
        <button 
          onClick={testDirectGateway}
          style={{ padding: '10px 20px', marginRight: 10, background: '#4CAF50', color: 'white', border: 'none', cursor: 'pointer' }}
        >
          1. Test Kết Nối Gateway
        </button>

        <button 
          onClick={testLogin}
          style={{ padding: '10px 20px', background: '#2196F3', color: 'white', border: 'none', cursor: 'pointer' }}
        >
          2. Test Login Admin
        </button>
      </div>

      <div style={{ background: '#000', padding: 10, borderRadius: 5, border: '1px solid #333' }}>
        <h3>Logs:</h3>
        {logs.map((log, index) => (
          <div key={index} style={{ 
            marginBottom: 5, 
            color: log.includes('[error]') ? '#ff5252' : log.includes('[success]') ? '#69f0ae' : '#fff' 
          }}>
            {log}
          </div>
        ))}
      </div>
    </div>
  );
};

export default TestConnection;