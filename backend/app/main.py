"""FastAPI application entry point."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.exceptions import register_exception_handlers
from app.core.i18n import LocaleMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan: startup and shutdown hooks."""
    # Startup: import all models to register with Base.metadata
    import app.models  # noqa: F401

    # Plan C Phase 6a — start APScheduler. Disabled when TESTING flag is set
    # so pytest doesn't spawn a background event loop.
    from app.core.config import settings as _settings
    from app.core.scheduler import shutdown_scheduler, start_scheduler

    scheduler_enabled = not getattr(_settings, "TESTING", False)
    if scheduler_enabled:
        start_scheduler()

    yield

    if scheduler_enabled:
        shutdown_scheduler()
    # Shutdown: dispose engine connection pool
    from app.core.database import engine

    await engine.dispose()


app = FastAPI(
    title="Lessonaza API",
    version="0.1.0",
    description="Lessonaza — Music lesson & practice management API (lessonaza.app)",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Locale middleware (reads Accept-Language header)
app.add_middleware(LocaleMiddleware)

# Custom exception handlers
register_exception_handlers(app)


@app.get("/health")
async def health_check() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}


# Mount API v1 router
from app.api.v1 import api_router  # noqa: E402

app.include_router(api_router, prefix="/api/v1")
