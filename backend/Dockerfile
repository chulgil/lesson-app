# ============================================================
# Lessonaza Backend - Multi-stage Dockerfile
# ============================================================

# --- Stage 1: Build dependencies ---
FROM python:3.12-slim AS builder

# Install UV package manager
RUN pip install --no-cache-dir uv

WORKDIR /app

# Copy dependency file first for Docker layer caching
COPY pyproject.toml uv.lock ./

# Install production dependencies only
RUN uv sync --no-dev --no-install-project

# --- Stage 2: Runtime ---
FROM python:3.12-slim AS runtime

# Install system dependencies for asyncmy (MySQL client)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Install UV for running commands
RUN pip install --no-cache-dir uv

# Create non-root user
RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/pyproject.toml /app/pyproject.toml

# Copy application code
COPY app/ ./app/
COPY alembic/ ./alembic/
COPY alembic.ini ./
COPY scripts/ ./scripts/

# Set ownership
RUN chown -R appuser:appuser /app

USER appuser

# Expose application port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run with uvicorn
CMD ["uv", "run", "uvicorn", "app.main:app", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--workers", "2", \
     "--log-level", "info", \
     "--access-log"]
