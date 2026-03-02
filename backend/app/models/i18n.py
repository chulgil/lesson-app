from datetime import datetime

from sqlalchemy import Boolean, DateTime, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class I18nTranslation(UUIDMixin, Base):
    """Server-side translation strings for notifications, emails, system messages."""

    __tablename__ = "i18n_translations"

    key: Mapped[str] = mapped_column(String(200), nullable=False)
    locale: Mapped[str] = mapped_column(String(10), nullable=False)
    value: Mapped[str] = mapped_column(Text, nullable=False)
    context: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        Index("uk_translation_key_locale", "key", "locale", unique=True),
        Index("idx_translation_context", "context"),
    )


class SupportedLocale(Base):
    """Supported locale configuration."""

    __tablename__ = "supported_locales"

    locale: Mapped[str] = mapped_column(String(10), primary_key=True)
    language_name: Mapped[str] = mapped_column(String(50), nullable=False)
    native_name: Mapped[str] = mapped_column(String(50), nullable=False)
    default_country: Mapped[str] = mapped_column(String(2), nullable=False)
    default_timezone: Mapped[str] = mapped_column(String(50), nullable=False)
    default_currency: Mapped[str] = mapped_column(String(3), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
