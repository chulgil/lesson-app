"""add_payment_reminder_tracking

#424 입금 추적 대시보드 — D+1/D+3/D+7 자동 리마인드 멱등성 + 쿨다운 컬럼 추가:
- subscription_proposals.reminder_d1_sent_at
- subscription_proposals.reminder_d3_sent_at
- subscription_proposals.reminder_d7_sent_at
- subscription_proposals.last_reminder_sent_at  (manual resend cooldown)

Revision ID: payment_reminder_tracking
Revises: vacation_periods_and_auto_extended_days (rebased — chain 직렬화)
Create Date: 2026-06-01 11:00:00.000000

Chain note: 원래 `undo_confirm_payment_support` 를 base 로 분기되었으나,
같은 base 의 자매 마이그레이션 (`makeup_credits_and_scheduled_lessons` →
`vacation_periods_and_auto_extended_days`) 가 먼저 머지되어 multi-head 발생.
본 머지에서 chain 을 직렬화하여 `vacation_periods_and_auto_extended_days`
다음에 적용되도록 변경. 다른 컬럼/테이블을 다루므로 의존성 없음.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "payment_reminder_tracking"
down_revision: str | None = "vacation_periods_and_auto_extended_days"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


_NEW_COLS = (
    "reminder_d1_sent_at",
    "reminder_d3_sent_at",
    "reminder_d7_sent_at",
    "last_reminder_sent_at",
)


def upgrade() -> None:
    existing = _columns("subscription_proposals")
    for col in _NEW_COLS:
        if col not in existing:
            op.add_column(
                "subscription_proposals",
                sa.Column(col, sa.DateTime(timezone=True), nullable=True),
            )


def downgrade() -> None:
    existing = _columns("subscription_proposals")
    for col in reversed(_NEW_COLS):
        if col in existing:
            op.drop_column("subscription_proposals", col)
