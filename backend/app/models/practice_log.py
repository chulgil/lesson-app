from datetime import date

from sqlalchemy import Date, Index, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class PracticeLog(UUIDMixin, TimestampMixin, Base):
    """Daily practice log per student."""

    __tablename__ = "practice_logs"

    student_id: Mapped[str] = mapped_column(String(36), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    total_minutes: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    tasks: Mapped[dict | list | None] = mapped_column(JSON, nullable=True, default=list)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        Index("uk_practice_log", "student_id", "date", unique=True),
        Index("idx_practice_log_date", "date"),
    )
