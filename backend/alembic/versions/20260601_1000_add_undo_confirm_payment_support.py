"""add_undo_confirm_payment_support

#426 입금 확인 24h Undo 지원 컬럼 추가:
- subscriptions.first_lesson_consumed_at: 첫 레슨 차감 시각 (Undo 차단 기준)
- teacher_student_relations.previous_status: 입금 확인 직전 status 백업

Revision ID: undo_confirm_payment_support
Revises: add_membership_travel_time
Create Date: 2026-06-01 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "undo_confirm_payment_support"
down_revision: str | None = "add_membership_travel_time"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def upgrade() -> None:
    if "first_lesson_consumed_at" not in _columns("subscriptions"):
        op.add_column(
            "subscriptions",
            sa.Column("first_lesson_consumed_at", sa.DateTime(timezone=True), nullable=True),
        )

    if "previous_status" not in _columns("teacher_student_relations"):
        # Postgres uses native enum (relationstatus); reuse existing type.
        bind = op.get_bind()
        dialect = bind.dialect.name
        if dialect == "postgresql":
            op.add_column(
                "teacher_student_relations",
                sa.Column(
                    "previous_status",
                    sa.Enum(
                        "pending",
                        "trialBooked",
                        "active",
                        "inactive",
                        "expired",
                        "past",
                        "disconnected",
                        name="relationstatus",
                        create_type=False,
                    ),
                    nullable=True,
                ),
            )
        else:
            op.add_column(
                "teacher_student_relations",
                sa.Column("previous_status", sa.String(length=20), nullable=True),
            )


def downgrade() -> None:
    if "previous_status" in _columns("teacher_student_relations"):
        op.drop_column("teacher_student_relations", "previous_status")

    if "first_lesson_consumed_at" in _columns("subscriptions"):
        op.drop_column("subscriptions", "first_lesson_consumed_at")
