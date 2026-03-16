import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Index, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDMixin


class TipCategory(str, enum.Enum):
    technique = "technique"
    musicality = "musicality"
    practice = "practice"
    mindset = "mindset"
    general = "general"


class TipTemplate(UUIDMixin, Base):
    """Reusable tip template for lesson feedback."""

    __tablename__ = "tip_templates"

    teacher_id: Mapped[str] = mapped_column(String(36), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[TipCategory] = mapped_column(
        Enum(TipCategory, native_enum=True),
        nullable=False,
        default=TipCategory.general,
    )
    instrument: Mapped[str | None] = mapped_column(String(50), nullable=True)
    usage_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    last_used_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    __table_args__ = (
        Index("idx_tip_teacher", "teacher_id"),
    )
