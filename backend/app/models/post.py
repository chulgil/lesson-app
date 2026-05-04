"""Teacher and academy posts for follow feeds."""

from enum import StrEnum

from sqlalchemy import Enum, Index, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class PostType(StrEnum):
    performance = "performance"
    event = "event"
    notice = "notice"


class TeacherPost(UUIDMixin, TimestampMixin, Base):
    """Announcement or feed post published by a teacher or academy."""

    __tablename__ = "teacher_posts"

    author_id: Mapped[str] = mapped_column(String(36), nullable=False)
    author_name: Mapped[str] = mapped_column(String(120), nullable=False, default="")
    post_type: Mapped[PostType] = mapped_column(
        Enum(PostType, native_enum=True),
        nullable=False,
        default=PostType.notice,
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)

    __table_args__ = (
        Index("idx_teacher_posts_author", "author_id"),
        Index("idx_teacher_posts_created", "created_at"),
    )
