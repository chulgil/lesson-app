#!/bin/bash
# ============================================================
# Lesson App Backend - Docker Deploy Script
# ============================================================
set -e

echo "=== Lesson App Backend Deploy ==="

# Pull latest code
echo "[1/4] Pulling latest code..."
git pull

# Build and restart application container (no cache for fresh build)
echo "[2/4] Building and restarting containers..."
docker compose build --no-cache app
docker compose up -d

# Run database migrations
echo "[3/4] Running database migrations..."
docker compose exec app uv run alembic upgrade head

# Health check
echo "[4/4] Running health check..."
sleep 3
if curl -sf http://localhost:8000/health > /dev/null; then
    echo "Health check passed!"
else
    echo "WARNING: Health check failed. Check logs with: docker compose logs app"
fi

echo "=== Deploy complete! ==="
