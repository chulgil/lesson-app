"""Add schedule-change snapshot fields to request events.

Revision ID: add_request_event_schedule_change_snapshots
Revises: add_membership_lesson_location
Create Date: 2026-05-05 09:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = "add_request_event_schedule_change_snapshots"
down_revision: str | None = "add_membership_lesson_location"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("request_events", sa.Column("change_credit_used", sa.Integer(), nullable=True))
    op.add_column("request_events", sa.Column("change_credit_remaining_after", sa.Integer(), nullable=True))
    op.add_column("request_events", sa.Column("keeps_session_number", sa.Boolean(), nullable=True))


def downgrade() -> None:
    op.drop_column("request_events", "keeps_session_number")
    op.drop_column("request_events", "change_credit_remaining_after")
    op.drop_column("request_events", "change_credit_used")
