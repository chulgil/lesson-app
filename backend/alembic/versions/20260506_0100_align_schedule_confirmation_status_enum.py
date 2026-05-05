"""Align schedule confirmation card status enum.

Revision ID: align_schedule_confirmation_status_enum
Revises: add_device_tokens
Create Date: 2026-05-06 01:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "align_schedule_confirmation_status_enum"
down_revision: str | None = "add_device_tokens"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


ALL_CONFIRMATION_CARD_STATUS_VALUES = (
    'pending',
    'confirmed',
    'changedTime',
    'rejected',
    'dismissed',
    'expired',
)
MISSING_CONFIRMATION_CARD_STATUS_VALUES = ('changedTime', 'dismissed')


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return

    for value in MISSING_CONFIRMATION_CARD_STATUS_VALUES:
        op.execute(f"ALTER TYPE confirmationcardstatus ADD VALUE IF NOT EXISTS '{value}'")


def downgrade() -> None:
    # PostgreSQL cannot drop enum values without rebuilding the type; keep this
    # downgrade data-safe because existing rows may already use the new values.
    pass
