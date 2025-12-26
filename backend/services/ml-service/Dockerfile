# Sử dụng Python 3.11 (hoặc version bạn đang dùng)
FROM python:3.11-slim

WORKDIR /app

# Copy requirements và cài đặt
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy toàn bộ code vào
COPY . .

# Set Python path để import từ thư mục src
ENV PYTHONPATH=/app/src

# Mở cổng 8000
EXPOSE 8000
CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]