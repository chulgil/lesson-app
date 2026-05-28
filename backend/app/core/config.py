from pydantic import field_validator
from pydantic_settings import BaseSettings

PRODUCTION_LIKE_ENVIRONMENTS = {"production", "beta"}
INSECURE_JWT_SECRETS = {
    "change-me-in-production",
    "dev-only-insecure-jwt-secret-change-before-production",
}

# Issue #410 — ENVIRONMENT alias map. Without normalization, a typo such as
# `prod` or `Production` silently bypasses PRODUCTION_LIKE_ENVIRONMENTS guards
# (strong-secret check, IAP default-deny, dev-only endpoints). Aliases are
# folded to canonical names at settings-load time so every downstream check
# sees the same vocabulary.
_ENVIRONMENT_ALIASES = {
    "prod": "production",
    "production": "production",
    "beta": "beta",
    "stg": "staging",
    "stage": "staging",
    "staging": "staging",
    "dev": "development",
    "development": "development",
    "local": "development",
    "test": "test",
    "testing": "test",
}


def normalize_environment(value: str) -> str:
    """Fold an ENVIRONMENT string to its canonical lowercase name.

    Unknown values are lower-cased but otherwise returned as-is so that
    whitelist guards (e.g. PRODUCTION_LIKE_ENVIRONMENTS) fail closed.
    """
    folded = (value or "").strip().lower()
    return _ENVIRONMENT_ALIASES.get(folded, folded)


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

    @field_validator("ENVIRONMENT", mode="before")
    @classmethod
    def _normalize_environment_field(cls, value: object) -> str:
        return normalize_environment(value if isinstance(value, str) else str(value or ""))

    # Plan C Phase 6a — disable APScheduler in pytest (env: TESTING=1) to keep
    # ASGI lifespan deterministic and avoid leaking background event loops.
    TESTING: bool = False

    # OpenAI (for AI lesson notes)
    OPENAI_API_KEY: str = ""

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # In-App Purchase validation (#405). Default-deny: receipts are stored for audit
    # but never upgrade plans unless a real validator is configured. The dev/test
    # flag below is only consulted in non-production environments to keep mocking
    # workflows convenient — production rejects it outright.
    IAP_AUTO_GRANT_ON_PENDING_DEV_ONLY: bool = False

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
