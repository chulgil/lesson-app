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
    WWW_BASE_URL: str = "https://lessonaza.com"

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

    # Alimtalk (#423). Default mock=True so dev + CI never accidentally hit the
    # vendor API. Production must set ALIMTALK_USE_MOCK=false AND populate the
    # vendor credentials below; otherwise sends silently no-op via the mock.
    ALIMTALK_USE_MOCK: bool = True
    ALIMTALK_API_BASE_URL: str = ""
    ALIMTALK_API_KEY: str = ""
    ALIMTALK_SENDER_PROFILE: str = ""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


settings = Settings()


def validate_runtime_configuration() -> None:
    """Validate secrets and runtime knobs that must be safe before serving production-like traffic.

    production / beta 에서는 다음을 거부:
    - 약한 INTERNAL_API_KEY / JWT_SECRET_KEY
    - DEBUG=True (stack trace · debug endpoint 노출)
    - CORS_ORIGINS 가 비어 있거나 wildcard (``*``) — credentials 인증 wildcard 는 CSRF 우회 위험
    - CORS_ORIGINS 에 localhost / 127.0.0.1 / http:// 포함 — production 도메인 외 origin 허용은 사고
    """
    if settings.ENVIRONMENT not in PRODUCTION_LIKE_ENVIRONMENTS:
        return
    if len(settings.INTERNAL_API_KEY) < 32:
        raise RuntimeError("INTERNAL_API_KEY must be set to a strong secret in production-like environments")
    if settings.JWT_SECRET_KEY in INSECURE_JWT_SECRETS or len(settings.JWT_SECRET_KEY) < 32:
        raise RuntimeError("JWT_SECRET_KEY must be set to a strong secret in production-like environments")
    if settings.DEBUG:
        raise RuntimeError("DEBUG must be False in production-like environments (stack trace exposure risk)")
    origins = settings.CORS_ORIGINS or []
    if not origins:
        raise RuntimeError("CORS_ORIGINS must be set explicitly in production-like environments")
    if "*" in origins:
        # allow_credentials=True 와 wildcard 조합은 CORS spec 위반 + CSRF 우회 risk.
        raise RuntimeError("CORS_ORIGINS must not contain '*' wildcard in production-like environments")
    for origin in origins:
        lowered = origin.lower()
        if "localhost" in lowered or "127.0.0.1" in lowered:
            raise RuntimeError(f"CORS_ORIGINS must not include local origin in production-like environments: {origin}")
        if lowered.startswith("http://"):
            raise RuntimeError(f"CORS_ORIGINS must use https:// in production-like environments: {origin}")
