"""add_booking_vacation_period_id

#4 H-001 spec §3.3 — booking ↔ vacation linkage for Recovery.

Revision ID: booking_vacation_period_id
Revises: vacation_per_student_disposition
Create Date: 2026-06-02 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "booking_vacation_period_id"
down_revision: str | None = "vacation_per_student_disposition"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _indexes(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {index["name"] for index in inspector.get_indexes(table_name)}


def upgrade() -> None:
    if "vacation_period_id" not in _columns("lesson_bookings"):
        op.add_column(
            "lesson_bookings",
            sa.Column("vacation_period_id", sa.String(length=36), nullable=True),
        )
    if "idx_booking_vacation_period" not in _indexes("lesson_bookings"):
        op.create_index(
            "idx_booking_vacation_period",
            "lesson_bookings",
            ["vacation_period_id"],
        )


def downgrade() -> None:
    if "idx_booking_vacation_period" in _indexes("lesson_bookings"):
        op.drop_index("idx_booking_vacation_period", table_name="lesson_bookings")
    if "vacation_period_id" in _columns("lesson_bookings"):
        op.drop_column("lesson_bookings", "vacation_period_id")
