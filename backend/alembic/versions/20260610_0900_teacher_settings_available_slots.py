"""Issue #606 — TeacherSettings.available_slots 컬럼 추가 (dual-write 역호환).

Revision ID: settings_available_slots
Revises: reschedule_check_bonus
Create Date: 2026-06-10 09:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "settings_available_slots"
down_revision: str | None = "reschedule_check_bonus"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "teacher_settings",
        sa.Column("available_slots", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("teacher_settings", "available_slots")
