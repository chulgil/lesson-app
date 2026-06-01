"""add_alimtalk_logs

#423 카카오 알림톡 5종 — 발송 audit log 테이블 신규.

Revision ID: alimtalk_logs
Revises: payment_reminder_tracking
Create Date: 2026-06-01 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "alimtalk_logs"
# Merge two parallel heads in main:
#   - payment_reminder_tracking  (#424)
#   - vacation_periods_and_auto_extended_days  (parallel branch)
down_revision: tuple[str, ...] = (
    "payment_reminder_tracking",
    "vacation_periods_and_auto_extended_days",
)
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _has_table(name: str) -> bool:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return name in inspector.get_table_names()


def upgrade() -> None:
    if _has_table("alimtalk_logs"):
        return
    op.create_table(
        "alimtalk_logs",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("template_id", sa.String(length=64), nullable=False),
        sa.Column("proposal_id", sa.String(length=36), nullable=True),
        sa.Column("subscription_id", sa.String(length=36), nullable=True),
        sa.Column("recipient_phone", sa.String(length=32), nullable=False),
        sa.Column("variables", sa.JSON(), nullable=True),
        sa.Column(
            "sent_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("success", sa.Boolean(), nullable=False, server_default=sa.text("0")),
        sa.Column("message_id", sa.String(length=128), nullable=True),
        sa.Column("error", sa.Text(), nullable=True),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("fallback_channel", sa.String(length=32), nullable=True),
    )
    op.create_index("idx_alimtalk_proposal_template", "alimtalk_logs", ["proposal_id", "template_id"])
    op.create_index(
        "idx_alimtalk_subscription_template",
        "alimtalk_logs",
        ["subscription_id", "template_id"],
    )
    op.create_index("idx_alimtalk_sent_at", "alimtalk_logs", ["sent_at"])
    op.create_index("idx_alimtalk_retry", "alimtalk_logs", ["success", "retry_count"])


def downgrade() -> None:
    if not _has_table("alimtalk_logs"):
        return
    op.drop_index("idx_alimtalk_retry", table_name="alimtalk_logs")
    op.drop_index("idx_alimtalk_sent_at", table_name="alimtalk_logs")
    op.drop_index("idx_alimtalk_subscription_template", table_name="alimtalk_logs")
    op.drop_index("idx_alimtalk_proposal_template", table_name="alimtalk_logs")
    op.drop_table("alimtalk_logs")
