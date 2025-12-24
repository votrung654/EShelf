# Build Stage
FROM node:20-alpine AS builder

WORKDIR /app

RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
RUN npx prisma generate

# Production Stage
FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache openssl

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=builder /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./
COPY --from=builder /app/prisma ./prisma

USER nodejs

EXPOSE 3002

ENV NODE_ENV=production

CMD ["node", "src/app.js"]