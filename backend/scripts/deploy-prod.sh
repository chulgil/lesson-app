#!/bin/bash
# ============================================================
# Lessonaza Backend - Production Deploy Script (codenavi server)
# ============================================================
# Usage: ./scripts/deploy-prod.sh
set -e

COMPOSE_FILE="docker-compose.prod.yml"
CONTAINER_NAME="lessonaza-api"

echo "=== Lessonaza Backend Production Deploy ==="

# Pull latest code
echo "[1/5] Pulling latest code..."
git pull

# Build application container
echo "[2/5] Building container..."
docker compose -f $COMPOSE_FILE build --no-cache app

# Start/restart container
echo "[3/5] Starting container..."
docker compose -f $COMPOSE_FILE up -d

# Wait for container to be healthy
echo "[4/5] Waiting for container to start..."
sleep 5

# Run database migrations
echo "[5/5] Running database migrations..."
docker compose -f $COMPOSE_FILE exec app uv run alembic upgrade head

# Health check
echo ""
echo "--- Health Check ---"
if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo "Health check passed!"
elif docker exec $CONTAINER_NAME curl -sf http://localhost:8000/health > /dev/null 2>&1; then
    echo "Health check passed (internal)!"
else
    echo "WARNING: Health check failed. Check logs:"
    echo "  docker compose -f $COMPOSE_FILE logs app --tail 50"
fi

echo ""
echo "=== Deploy complete! ==="
echo "API: https://lesson.chulgil.me"
echo "Logs: docker compose -f $COMPOSE_FILE logs -f app"
