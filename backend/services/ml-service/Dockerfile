# Sử dụng Python 3.11 (hoặc version bạn đang dùng)
FROM python:3.11-slim

WORKDIR /app

# Copy requirements và cài đặt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ code vào
COPY . .

# 👇 DÒNG QUAN TRỌNG NHẤT (SỬA LỖI CỦA BẠN) 👇
# Nó bảo Python coi thư mục /app/src là thư mục gốc để import
ENV PYTHONPATH=/app/src

# Mở cổng 8000
EXPOSE 8000

# Lệnh chạy (giữ nguyên như cũ của bạn)
# Lưu ý: Nếu lệnh cũ là "uvicorn src.main:app...", thì giữ nguyên
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]