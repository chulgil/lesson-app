"""Practice journal models (#872).

Four tables:
  practice_journal_marks        -- daily practice stamp (short/full)
  practice_journal_seals        -- guardian weekly seal
  practice_journal_endorsements -- teacher or self sign-off
  practice_journal_volumes      -- bound completion volumes

Design decisions:
  - enum columns use String(10) with native_enum=False to avoid PG ADD-VALUE alembic
    landmines (memory: reference_enum_missing_add_value_postgres).
  - child_profile_id maps to students.id (no separate child_profile table).
  - guardian_user_id / author_user_id are users.id (NOT students.id).
  - ledger is computed on read, not stored.
  - WIRE CONTRACT: column names are the FE .g.dart authoritative keys
    (intensity, cheer_note, by, piece_name, bound_date).  Endorsement.date and
    BoundVolume.bound_date are first-class NOT NULL columns the FE deserialises.
"""

from __future__ import annotations

import datetime

from sqlalchemy import Date, ForeignKey, Index, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDMixin


class PracticeMark(UUIDMixin, TimestampMixin, Base):
    """Daily practice stamp for a student.

    Constraints:
      - unique(child_profile_id, date): only one mark per student per day
      - intensity upgrade is monotonic: short -> full only (enforced in service)
    """

    __tablename__ = "practice_journal_marks"

    # FK -> students.id
    child_profile_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    # Values: "short" | "full"  (String, not native enum). FE key: "intensity".
    intensity: Mapped[str] = mapped_column(String(10), nullable=False)

    __table_args__ = (
        UniqueConstraint("child_profile_id", "date", name="uq_practice_marks_student_date"),
        Index("idx_practice_marks_student_date", "child_profile_id", "date"),
    )


class GuardianSeal(UUIDMixin, TimestampMixin, Base):
    """Guardian weekly seal (one per student per week).

    week_start is always normalized to Monday by the service before insert.
    Re-sealing the same week is idempotent (returns existing row).
    """

    __tablename__ = "practice_journal_seals"

    child_profile_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    # FK -> users.id (parent user, NOT student)
    guardian_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    week_start: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    # FE key: "cheer_note".
    cheer_note: Mapped[str | None] = mapped_column(Text, nullable=True)

    __table_args__ = (
        UniqueConstraint("child_profile_id", "week_start", name="uq_guardian_seals_student_week"),
        Index("idx_guardian_seals_student_week", "child_profile_id", "week_start"),
    )


class Endorsement(UUIDMixin, TimestampMixin, Base):
    """Teacher or self endorsement (append-only).

    Rules:
      - by="teacher": assignment_ref is required, author is the teacher user
      - by="self": assignment_ref must be None, author is the student user
    """

    __tablename__ = "practice_journal_endorsements"

    child_profile_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    # FK -> users.id (stamped user -- teacher or student)
    author_user_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    # Values: "self" | "teacher". FE key: "by".
    by: Mapped[str] = mapped_column(String(10), nullable=False)
    # Endorsement date (FE deserialises a "date" key, NOT NULL).
    date: Mapped[datetime.date] = mapped_column(Date, nullable=False)
    # Opaque reference string (FE uses "assign_42" placeholder). Max 64 chars.
    assignment_ref: Mapped[str | None] = mapped_column(String(64), nullable=True)
    # FE deserialises "note" as a required String -> NOT NULL.
    note: Mapped[str] = mapped_column(Text, nullable=False)

    __table_args__ = (
        Index("idx_endorsements_student", "child_profile_id"),
        Index("idx_endorsements_student_date", "child_profile_id", "date"),
    )


class BoundVolume(UUIDMixin, TimestampMixin, Base):
    """Bound completion volume (one per student per piece).

    volume_no is auto-assigned as count+1 and protected by a unique constraint
    on (child_profile_id, piece_id).  IntegrityError on race is caught and
    re-queried to return the existing row.
    """

    __tablename__ = "practice_journal_volumes"

    child_profile_id: Mapped[str] = mapped_column(
        String(36),
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    piece_id: Mapped[str] = mapped_column(String(36), nullable=False)
    # FE key: "piece_name" (NOT NULL -- FE deserialises as required String).
    piece_name: Mapped[str] = mapped_column(String(200), nullable=False)
    volume_no: Mapped[int] = mapped_column(Integer, nullable=False)
    # Bound date (FE key "bound_date", NOT NULL).
    bound_date: Mapped[datetime.date] = mapped_column(Date, nullable=False)

    __table_args__ = (
        UniqueConstraint("child_profile_id", "piece_id", name="uq_volumes_student_piece"),
        Index("idx_volumes_student", "child_profile_id"),
    )
