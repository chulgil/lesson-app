import uuid
from datetime import UTC, datetime

from sqlalchemy import DateTime, MetaData, String, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

# 표준 SQLAlchemy naming convention — SQLite batch_alter_table 가 constraint 를 정확히 재생성하려면
# 모든 constraint 가 결정적인 이름을 가져야 한다. PostgreSQL 은 자동 이름이 있지만, batch 모드에서
# 테이블을 dropped/recreated 할 때 SQLite 가 "Constraint must have a name" 으로 실패하던 P0 해결.
NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy ORM models."""

    metadata = MetaData(naming_convention=NAMING_CONVENTION)


class UUIDMixin:
    """Mixin providing a UUID primary key as CHAR(36)."""

    id: Mapped[str] = mapped_column(
        String(36),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )


class TimestampMixin:
    """Mixin providing created_at and updated_at timestamp columns."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
        server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(UTC),
        server_default=func.now(),
        onupdate=lambda: datetime.now(UTC),
    )
