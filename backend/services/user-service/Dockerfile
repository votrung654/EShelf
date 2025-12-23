FROM node:20-alpine

WORKDIR /app

# Cài OpenSSL cho Prisma (cần cho Prisma Client runtime)
RUN apk add --no-cache openssl libc6-compat

# Copy package files (build context là backend/, nên copy từ services/user-service/)
COPY services/user-service/package*.json ./

# Install dependencies (cả dev để có prisma CLI)
RUN npm install && npm cache clean --force

# Copy Prisma schema (build context là backend/, nên copy từ database/prisma)
COPY database/prisma ./prisma

# Generate Prisma client (dùng npx với prisma đã cài)
RUN npx prisma generate

# Copy source code (build context là backend/, nên copy từ services/user-service/src)
COPY services/user-service/src ./src

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

EXPOSE 3003

CMD ["node", "src/app.js"]


