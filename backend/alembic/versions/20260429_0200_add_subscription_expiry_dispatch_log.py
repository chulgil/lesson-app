"""Add subscription_expiry_dispatch_log (Plan C Phase 6a)

Revision ID: add_sub_expiry_dispatch_log
Revises: unify_no_show_policy
Create Date: 2026-04-29 02:00:00.000000

#240 결정 게이트 (2026-04-29) Plan C §7.1: APScheduler in-process + PG advisory lock + dedup table.
- D-14/D-7/D-1/D-0 알림 dedup table
- UNIQUE(subscription_id, milestone, sent_date, recipient_user_id) — 인스턴스/재시도 중복 차단
- INSERT ON CONFLICT DO NOTHING 패턴으로 idempotent dispatch
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_sub_expiry_dispatch_log"
down_revision: str | None = "unify_no_show_policy"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "subscription_expiry_dispatch_log",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("subscription_id", sa.String(length=36), nullable=False),
        sa.Column("milestone", sa.Integer(), nullable=False),
        sa.Column("recipient_user_id", sa.String(length=36), nullable=False),
        sa.Column("recipient_role", sa.String(length=20), nullable=False),
        sa.Column("sent_date", sa.Date(), nullable=False),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint(
            "subscription_id",
            "milestone",
            "sent_date",
            "recipient_user_id",
            name="uq_sub_expiry_dispatch",
        ),
    )
    op.create_index(
        "idx_sub_expiry_dispatch_sub",
        "subscription_expiry_dispatch_log",
        ["subscription_id"],
    )
    op.create_index(
        "idx_sub_expiry_dispatch_sent_date",
        "subscription_expiry_dispatch_log",
        ["sent_date"],
    )


def downgrade() -> None:
    op.drop_index(
        "idx_sub_expiry_dispatch_sent_date",
        table_name="subscription_expiry_dispatch_log",
    )
    op.drop_index(
        "idx_sub_expiry_dispatch_sub",
        table_name="subscription_expiry_dispatch_log",
    )
    op.drop_table("subscription_expiry_dispatch_log")
