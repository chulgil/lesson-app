"""add_vacation_per_student_disposition

#4 H-001 spec §4.2 — per-student disposition override JSON.

Revision ID: vacation_per_student_disposition
Revises: invite_resend_tracking
Create Date: 2026-06-02 09:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "vacation_per_student_disposition"
down_revision: str | None = "invite_resend_tracking"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def upgrade() -> None:
    if "per_student_disposition" not in _columns("vacation_periods"):
        op.add_column(
            "vacation_periods",
            sa.Column("per_student_disposition", sa.JSON(), nullable=True),
        )


def downgrade() -> None:
    if "per_student_disposition" in _columns("vacation_periods"):
        op.drop_column("vacation_periods", "per_student_disposition")
