# ==========================================
# 1. Build Stage
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# 👇 QUAN TRỌNG: Cài OpenSSL để Prisma chạy được
RUN apk add --no-cache openssl

# 1. Copy file định nghĩa
COPY package*.json ./

# 2. Copy folder prisma (Chứa schema.prisma)
# Lưu ý: Bạn nhớ copy folder prisma từ database sang thư mục auth-service trước nhé!
COPY prisma ./prisma/

# 3. Cài đặt dependencies (Full để có Prisma CLI)
RUN npm ci

# 4. Sinh code Prisma Client (Kết nối DB)
RUN npx prisma generate

# ==========================================
# 2. Production Stage
# ==========================================
FROM node:20-alpine

WORKDIR /app

# 👇 QUAN TRỌNG: Cài OpenSSL cho môi trường chạy thật
RUN apk add --no-cache openssl

# Tạo user non-root bảo mật
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 5. Copy node_modules từ builder (đã chứa Prisma Client xịn)
COPY --from=builder /app/node_modules ./node_modules

# 6. Copy source code
COPY src ./src
COPY package.json ./

# 7. Copy folder prisma sang để tránh lỗi không tìm thấy schema lúc chạy
COPY --from=builder /app/prisma ./prisma

USER nodejs

EXPOSE 3001

ENV NODE_ENV=production

CMD ["node", "src/app.js"]