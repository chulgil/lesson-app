from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://lessonaza:lessonaza@localhost:5432/lessonaza"
    DATABASE_ECHO: bool = False

    # JWT
    JWT_SECRET_KEY: str = "change-me-in-production"
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

    # Payment Gateway (Toss Payments)
    PG_PROVIDER: str = "toss"
    TOSS_CLIENT_KEY: str = ""
    TOSS_SECRET_KEY: str = ""

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

    # OpenAI (for AI lesson notes)
    OPENAI_API_KEY: str = ""

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


settings = Settings()
