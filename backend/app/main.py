"""FastAPI application entry point."""

from contextlib import asynccontextmanager
from collections.abc import AsyncIterator

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

    yield
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
