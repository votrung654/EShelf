#!/bin/sh

set -e

echo "Waiting for PostgreSQL to be ready..."

MAX_ATTEMPTS=30
ATTEMPT=0

# Chờ database sẵn sàng bằng cách thử kết nối với Prisma Client
until node check-db.js > /dev/null 2>&1; do
  ATTEMPT=$((ATTEMPT + 1))
  if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
    echo "PostgreSQL connection timeout after $MAX_ATTEMPTS attempts"
    exit 1
  fi
  echo "PostgreSQL is unavailable - sleeping (attempt $ATTEMPT/$MAX_ATTEMPTS)"
  sleep 2
done

echo "PostgreSQL is ready! Running migrations..."

# Chạy migrations
npx prisma migrate deploy

echo "Migrations completed successfully!"

# Chạy seed nếu có
if [ -f "prisma/seed.js" ]; then
  echo ""
  echo "Running seed script..."
  echo "Note: Seed script will preserve existing data and only add missing books."
  npm run db:seed || echo "Warning: Seed script encountered an error (this may be normal if data already exists)"
fi

echo ""
echo "=========================================="
echo "Database setup complete!"
echo "=========================================="

