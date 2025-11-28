#!/usr/bin/env bash
set -e

# Install clients if missing (CI runners may be minimal)
if ! command -v pg_isready &>/dev/null; then
  echo "📦 Installing postgres-client & redis-tools..."
  sudo apt-get update -qq && sudo apt-get install -y postgresql-client redis-tools
fi

echo "⏳ Waiting for PostgreSQL..."
until pg_isready -h localhost -p 5432 -U test; do sleep 1; done

echo "⏳ Waiting for Redis..."
until [ "$(redis-cli -h localhost -p 6379 ping)" = "PONG" ]; do sleep 1; done

echo "🚀 Initializing DB schema..."
# Only if prisma exists
if command -v npx &>/dev/null && [ -f "packages/backend/prisma/schema.prisma" ]; then
  npx prisma db push --schema=packages/backend/prisma/schema.prisma --accept-data-loss
else
  echo "⚠️ Prisma schema not found, skipping DB init"
fi

echo "✅ Services ready!"
