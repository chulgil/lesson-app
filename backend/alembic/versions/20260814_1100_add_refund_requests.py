"""Add refund_requests table + subscriptionstatus 'refunded' value.

Issue #1271 — subscription refund request flow. ``status`` is a plain
String(20) column (not a native PG enum) — see the model docstring for why.
``subscriptions.status`` *is* a native enum, so completing a refund request
(transition to "refunded") needs an ``ALTER TYPE ... ADD VALUE`` here, same
pattern as ``20260608_1100_expand_status_enums_phase21.py``.

Revision ID: add_refund_requests
Revises: add_invite_target_role
Create Date: 2026-08-14 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_refund_requests"
down_revision: str | None = "add_parent_to_inviteuserrole"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "refund_requests",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("subscription_id", sa.String(36), nullable=False),
        sa.Column("student_id", sa.String(36), nullable=False),
        sa.Column("teacher_id", sa.String(36), nullable=False),
        sa.Column("bank_name", sa.String(50), nullable=False),
        sa.Column("account_number", sa.String(50), nullable=False),
        sa.Column("account_holder", sa.String(50), nullable=False),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="requested"),
        sa.Column("processed_amount", sa.Integer(), nullable=True),
        sa.Column("reject_reason", sa.Text(), nullable=True),
        sa.Column("requested_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("processed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["subscription_id"], ["subscriptions.id"]),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"]),
        sa.PrimaryKeyConstraint("id", name="pk_refund_requests"),
        sa.CheckConstraint(
            "status IN ('requested', 'completed', 'rejected')",
            name="ck_refund_requests_status",
        ),
    )
    op.create_index("idx_refund_requests_subscription", "refund_requests", ["subscription_id"])
    op.create_index("idx_refund_requests_student", "refund_requests", ["student_id"])
    op.create_index("idx_refund_requests_teacher", "refund_requests", ["teacher_id"])
    op.create_index("idx_refund_requests_status", "refund_requests", ["status"])

    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("ALTER TYPE subscriptionstatus ADD VALUE IF NOT EXISTS 'refunded'")


def downgrade() -> None:
    op.drop_index("idx_refund_requests_status", table_name="refund_requests")
    op.drop_index("idx_refund_requests_teacher", table_name="refund_requests")
    op.drop_index("idx_refund_requests_student", table_name="refund_requests")
    op.drop_index("idx_refund_requests_subscription", table_name="refund_requests")
    op.drop_table("refund_requests")
    # PG enum 값 제거는 위험(타입 재생성 필요) — 다른 subscriptionstatus 확장
    # 마이그레이션과 동일하게 noop.
