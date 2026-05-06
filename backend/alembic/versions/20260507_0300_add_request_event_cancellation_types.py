"""Add request event cancellation outcome types.

Revision ID: add_request_event_cancellation_types
Revises: add_practice_item_resources
Create Date: 2026-05-07 03:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_request_event_cancellation_types"
down_revision: str | None = "add_practice_item_resources"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    op.execute("ALTER TYPE requesteventtype ADD VALUE IF NOT EXISTS 'lessonCancellationConfirmed'")
    op.execute("ALTER TYPE requesteventtype ADD VALUE IF NOT EXISTS 'cancellationCreditRefunded'")


def downgrade() -> None:
    # PostgreSQL cannot drop enum values without recreating the type and rewriting data.
    pass
