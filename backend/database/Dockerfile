FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci
RUN npx prisma generate

# Script để chờ database sẵn sàng và chạy migrations
COPY wait-for-db.sh ./
COPY check-db.js ./
RUN chmod +x wait-for-db.sh

CMD ["./wait-for-db.sh"]

