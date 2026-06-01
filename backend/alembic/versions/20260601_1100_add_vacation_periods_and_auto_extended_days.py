"""Add VacationPeriod table and subscriptions.auto_extended_days.

#431 G3 휴가 모드 — 1차 BE 모델:
- vacation_periods 테이블 신규 (다중 기간 휴가, 3-option default disposition)
- subscriptions.auto_extended_days INTEGER NOT NULL DEFAULT 0
  (휴가 자동 연장 누적 일수, expiresAt 계산용)

Spec:
- docs/specs/schedule/teacher_vacation_mode.md §3
- docs/specs/subscription/subscription_master.md §2.2.3

Note: TeacherAvailability 의 기존 단일 vacation_* 필드는 본 마이그레이션에서
건드리지 않는다. 별도 deprecate 마이그레이션은 후속 PR.

Revision ID: vacation_periods_and_auto_extended_days
Revises: makeup_credits_and_scheduled_lessons (rebased — 자매 #432 가 먼저 머지)
Create Date: 2026-06-01 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "vacation_periods_and_auto_extended_days"
down_revision: str | None = "makeup_credits_and_scheduled_lessons"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # 1) vacation_periods 테이블 신규
    op.create_table(
        "vacation_periods",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("reason", sa.String(length=200), nullable=True),
        sa.Column(
            "default_disposition",
            sa.Enum(
                "makeupCredit",
                "freeCancel",
                "rollForward",
                name="vacationdisposition",
                native_enum=True,
            ),
            nullable=False,
            server_default="rollForward",
        ),
        sa.Column("cancelled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.CheckConstraint("end_date >= start_date", name="ck_vacation_period_end_after_start"),
    )
    op.create_index("idx_vacation_teacher", "vacation_periods", ["teacher_id"])
    op.create_index("idx_vacation_dates", "vacation_periods", ["start_date", "end_date"])

    # 2) subscriptions.auto_extended_days
    op.add_column(
        "subscriptions",
        sa.Column(
            "auto_extended_days",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
    )


def downgrade() -> None:
    op.drop_column("subscriptions", "auto_extended_days")
    op.drop_index("idx_vacation_dates", table_name="vacation_periods")
    op.drop_index("idx_vacation_teacher", table_name="vacation_periods")
    op.drop_table("vacation_periods")
    # Drop enum type (PostgreSQL only — SQLite tolerates absence)
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        sa.Enum(name="vacationdisposition").drop(bind, checkfirst=True)
