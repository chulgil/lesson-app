"""Add preferred slots to lesson requests.

Revision ID: add_lesson_request_preferred_slots
Revises: add_subscription_alert_days_set
Create Date: 2026-05-03 01:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_lesson_request_preferred_slots"
down_revision: str | None = "add_subscription_alert_days_set"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "lesson_requests",
        sa.Column("preferred_slots", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("lesson_requests", "preferred_slots")
