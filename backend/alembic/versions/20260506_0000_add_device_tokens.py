"""Add device token table for push notifications.

Revision ID: add_device_tokens
Revises: add_practice_pieces
Create Date: 2026-05-06 00:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_device_tokens"
down_revision: str | None = "add_practice_pieces"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "device_tokens",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("user_id", sa.String(length=36), nullable=False),
        sa.Column("token", sa.String(length=255), nullable=False),
        sa.Column(
            "platform",
            sa.Enum("ios", "android", name="deviceplatform"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token"),
    )
    op.create_index("idx_device_token_user", "device_tokens", ["user_id"])
    op.create_index("idx_device_token_token", "device_tokens", ["token"], unique=True)


def downgrade() -> None:
    op.drop_index("idx_device_token_token", table_name="device_tokens")
    op.drop_index("idx_device_token_user", table_name="device_tokens")
    op.drop_table("device_tokens")
