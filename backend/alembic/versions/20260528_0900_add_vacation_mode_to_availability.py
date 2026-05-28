"""Add vacation_mode fields to TeacherAvailability.

Revision ID: add_vacation_mode_to_availability
Revises: add_app_version_tables
Create Date: 2026-05-28 09:00:00.000000

Spec: docs/specs/schedule/teacher_availability_spec.md §3.5
- vacation_mode: bool - vacation mode active flag
- vacation_start_date: date - vacation period start (inclusive)
- vacation_end_date: date - vacation period end (inclusive)
- vacation_reason: str - optional reason (e.g. "여름방학", "시험기간")

Note: Separate from ScheduleException(type=vacation). Both can be active;
either blocks bookable slots.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_vacation_mode_to_availability"
down_revision: str | None = "add_app_version_tables"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "teacher_availabilities",
        sa.Column("vacation_mode", sa.Boolean(), nullable=False, server_default=sa.false()),
    )
    op.add_column(
        "teacher_availabilities",
        sa.Column("vacation_start_date", sa.Date(), nullable=True),
    )
    op.add_column(
        "teacher_availabilities",
        sa.Column("vacation_end_date", sa.Date(), nullable=True),
    )
    op.add_column(
        "teacher_availabilities",
        sa.Column("vacation_reason", sa.String(length=100), nullable=True),
    )

    # Add check constraints
    op.create_check_constraint(
        "ck_vacation_dates_required_when_active",
        "teacher_availabilities",
        "vacation_mode = false OR (vacation_start_date IS NOT NULL AND vacation_end_date IS NOT NULL)",
    )
    op.create_check_constraint(
        "ck_vacation_end_after_start",
        "teacher_availabilities",
        "vacation_end_date IS NULL OR vacation_start_date IS NULL OR vacation_end_date >= vacation_start_date",
    )


def downgrade() -> None:
    op.drop_constraint(
        "ck_vacation_end_after_start",
        "teacher_availabilities",
        type_="check",
    )
    op.drop_constraint(
        "ck_vacation_dates_required_when_active",
        "teacher_availabilities",
        type_="check",
    )
    op.drop_column("teacher_availabilities", "vacation_reason")
    op.drop_column("teacher_availabilities", "vacation_end_date")
    op.drop_column("teacher_availabilities", "vacation_start_date")
    op.drop_column("teacher_availabilities", "vacation_mode")
