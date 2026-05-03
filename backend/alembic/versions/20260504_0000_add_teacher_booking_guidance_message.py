"""Add teacher booking guidance message.

Revision ID: add_teacher_booking_guidance_message
Revises: add_lesson_request_preferred_slots
Create Date: 2026-05-04 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_teacher_booking_guidance_message"
down_revision: str | None = "add_lesson_request_preferred_slots"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "teacher_settings",
        sa.Column("booking_guidance_message", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("teacher_settings", "booking_guidance_message")
