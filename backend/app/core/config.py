from pydantic_settings import BaseSettings

PRODUCTION_LIKE_ENVIRONMENTS = {"production", "beta"}
INSECURE_JWT_SECRETS = {
    "change-me-in-production",
    "dev-only-insecure-jwt-secret-change-before-production",
}


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://lessonaza:lessonaza@localhost:5432/lessonaza"
    DATABASE_ECHO: bool = False

    # JWT
    JWT_SECRET_KEY: str = "dev-only-insecure-jwt-secret-change-before-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # OAuth - Google
    GOOGLE_CLIENT_ID: str = ""
    GOOGLE_CLIENT_SECRET: str = ""

    # OAuth - Kakao
    KAKAO_CLIENT_ID: str = ""
    KAKAO_CLIENT_SECRET: str = ""

    # OAuth - Apple
    APPLE_CLIENT_ID: str = ""
    APPLE_TEAM_ID: str = ""
    APPLE_KEY_ID: str = ""
    APPLE_PRIVATE_KEY_PATH: str = ""

    # Vultr Object Storage
    VULTR_STORAGE_ENDPOINT: str = ""
    VULTR_STORAGE_ACCESS_KEY: str = ""
    VULTR_STORAGE_SECRET_KEY: str = ""
    VULTR_STORAGE_BUCKET: str = "lessonaza-recordings"

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    # i18n
    DEFAULT_LOCALE: str = "ko"
    SUPPORTED_LOCALES: list[str] = ["ko", "en", "ja"]

    # Environment
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    INTERNAL_API_KEY: str = ""
    # Plan C Phase 6a — disable APScheduler in pytest (env: TESTING=1) to keep
    # ASGI lifespan deterministic and avoid leaking background event loops.
    TESTING: bool = False

    # OpenAI (for AI lesson notes)
    OPENAI_API_KEY: str = ""

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


settings = Settings()


def validate_runtime_configuration() -> None:
    """Validate secrets that must be strong before serving production-like traffic."""
    if settings.ENVIRONMENT not in PRODUCTION_LIKE_ENVIRONMENTS:
        return
    if settings.JWT_SECRET_KEY in INSECURE_JWT_SECRETS or len(settings.JWT_SECRET_KEY) < 32:
        raise RuntimeError("JWT_SECRET_KEY must be set to a strong secret in production-like environments")
    if len(settings.INTERNAL_API_KEY) < 32:
        raise RuntimeError("INTERNAL_API_KEY must be set to a strong secret in production-like environments")
