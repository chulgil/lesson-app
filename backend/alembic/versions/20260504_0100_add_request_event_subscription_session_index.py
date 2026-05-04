"""Add request event subscription session index.

Revision ID: add_request_event_subscription_session_index
Revises: add_teacher_booking_guidance_message
Create Date: 2026-05-04 01:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_request_event_subscription_session_index"
down_revision: str | None = "add_teacher_booking_guidance_message"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_index(
        "idx_request_events_subscription_session_created",
        "request_events",
        ["subscription_id", "session_number", "created_at"],
    )


def downgrade() -> None:
    op.drop_index(
        "idx_request_events_subscription_session_created",
        table_name="request_events",
    )
