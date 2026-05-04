"""Manual teacher records for students tracking offline teachers."""

from sqlalchemy import Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class ManualTeacher(UUIDMixin, TimestampMixin, Base):
    """Teacher profile manually added by a user."""

    __tablename__ = "manual_teachers"

    owner_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    instrument: Mapped[str | None] = mapped_column(String(80), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(40), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    profile_color_value: Mapped[int | None] = mapped_column(Integer, nullable=True)
