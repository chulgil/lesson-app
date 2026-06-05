import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class UserRole(str, enum.Enum):
    teacher = "teacher"
    student = "student"
    parent = "parent"


class OAuthProvider(str, enum.Enum):
    google = "google"
    kakao = "kakao"
    apple = "apple"


class User(UUIDMixin, TimestampMixin, Base):
    """Core user account for authentication."""

    __tablename__ = "users"

    email: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    role: Mapped[UserRole | None] = mapped_column(
        Enum(UserRole, native_enum=True),
        nullable=True,
        default=None,
    )
    profile_image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    onboarding_completed: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    # #430 G1 B2 — 약관 동의 기록 (phone_verification_policy.md §5.2)
    # 서비스 이용약관 + 개인정보 처리방침은 필수 묶음으로 한 시각에 기록.
    # 마케팅 정보 수신은 정보통신망법 제50조에 따라 별도 동의로 기록.
    terms_accepted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    marketing_consent_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # AC-M2 §7.2: 다중 디바이스 일괄 만료용 epoch.
    # 토글/강제 로그아웃 시 갱신. ``access_token.iat`` 가 본 값보다 이전이면 401.
    # jti 추적 없이도 같은 user 의 모든 활성 토큰을 한 번에 만료시킨다.
    tokens_revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # i18n / localization
    locale: Mapped[str] = mapped_column(String(10), nullable=False, default="ko")
    country: Mapped[str] = mapped_column(String(2), nullable=False, default="KR")
    timezone: Mapped[str] = mapped_column(String(50), nullable=False, default="Asia/Seoul")
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="KRW")

    __table_args__ = (
        Index("uk_users_email", "email", unique=True),
        Index("idx_users_role", "role"),
        Index("idx_users_country", "country"),
    )


class OAuthAccount(UUIDMixin, Base):
    """Social login provider accounts linked to a user."""

    __tablename__ = "oauth_accounts"

    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    provider: Mapped[OAuthProvider] = mapped_column(
        Enum(OAuthProvider, native_enum=True),
        nullable=False,
    )
    provider_user_id: Mapped[str] = mapped_column(String(255), nullable=False)
    provider_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    provider_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    is_private_email: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_oauth_provider_user", "provider", "provider_user_id", unique=True),
        Index("idx_oauth_user_id", "user_id"),
    )


class TokenBlacklist(UUIDMixin, Base):
    """Blacklisted refresh tokens for logout support."""

    __tablename__ = "token_blacklist"

    jti: Mapped[str] = mapped_column(String(255), nullable=False)
    user_id: Mapped[str] = mapped_column(String(36), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("uk_token_jti", "jti", unique=True),
        Index("idx_token_expires", "expires_at"),
    )
