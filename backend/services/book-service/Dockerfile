# ==========================================
# 1. Build Stage
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# 👇 THÊM DÒNG NÀY: Cài OpenSSL để Prisma Generate chạy được
RUN apk add --no-cache openssl

# 1. Copy file định nghĩa
COPY package*.json ./

# 2. Copy prisma (Từ thư mục hiện tại vào trong Docker)
COPY prisma ./prisma/

# 3. Cài đặt đầy đủ để có CLI
RUN npm ci

# 4. Tạo Prisma Client
RUN npx prisma generate

# ==========================================
# 2. Production Stage
# ==========================================
FROM node:20-alpine

WORKDIR /app

# 👇 THÊM DÒNG NÀY: Cài OpenSSL để App chạy được (Runtime)
RUN apk add --no-cache openssl

# Add non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 5. Copy node_modules từ builder (đã chứa Prisma Client)
COPY --from=builder /app/node_modules ./node_modules

# 6. Copy source code
COPY src ./src
COPY package.json ./

# 7. Copy folder prisma từ builder sang (để tránh lỗi not found)
COPY --from=builder /app/prisma ./prisma

USER nodejs

EXPOSE 3002

ENV NODE_ENV=production

CMD ["node", "src/app.js"]