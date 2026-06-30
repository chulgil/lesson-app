"""drop practice_streaks counter table (G3 PR-D)

Revision ID: drop_practice_streaks
Revises: add_practice_journal
Create Date: 20260630 00:00:00.000000

The practice streak is recomputed from ``practice_logs`` on every read
(``compute_streak``, docs/specs/practice/streak_ssot.md §1/§2). The legacy
``practice_streaks`` counter table is no longer read or written by any code
path (PR-A revoked all reads; PR-D rewires the two write endpoints to the
SSOT), so the table is dropped.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "drop_practice_streaks"
down_revision: str | None = "add_practice_journal"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.drop_table("practice_streaks")


def downgrade() -> None:
    op.create_table(
        "practice_streaks",
        sa.Column("student_id", sa.String(length=36), nullable=False),
        sa.Column("current_streak", sa.Integer(), nullable=False),
        sa.Column("longest_streak", sa.Integer(), nullable=False),
        sa.Column("last_practice_date", sa.Date(), nullable=True),
        sa.Column("total_practice_days", sa.Integer(), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("(CURRENT_TIMESTAMP)"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("uk_streak_student", "practice_streaks", ["student_id"], unique=True)
