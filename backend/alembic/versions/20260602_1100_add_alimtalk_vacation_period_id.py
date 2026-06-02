"""add_alimtalk_vacation_period_id

#4 H-001 §6.1 — vacation alimtalk fan-out keyed by vacation_period_id +
recipient_phone for idempotency.

Revision ID: alimtalk_vacation_period_id
Revises: booking_vacation_period_id
Create Date: 2026-06-02 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "alimtalk_vacation_period_id"
down_revision: str | None = "booking_vacation_period_id"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _indexes(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {index["name"] for index in inspector.get_indexes(table_name)}


def upgrade() -> None:
    if "vacation_period_id" not in _columns("alimtalk_logs"):
        op.add_column(
            "alimtalk_logs",
            sa.Column("vacation_period_id", sa.String(length=36), nullable=True),
        )
    if "idx_alimtalk_vacation_phone_template" not in _indexes("alimtalk_logs"):
        op.create_index(
            "idx_alimtalk_vacation_phone_template",
            "alimtalk_logs",
            ["vacation_period_id", "recipient_phone", "template_id"],
        )


def downgrade() -> None:
    if "idx_alimtalk_vacation_phone_template" in _indexes("alimtalk_logs"):
        op.drop_index("idx_alimtalk_vacation_phone_template", table_name="alimtalk_logs")
    if "vacation_period_id" in _columns("alimtalk_logs"):
        op.drop_column("alimtalk_logs", "vacation_period_id")
