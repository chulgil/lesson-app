"""add_invite_resend_tracking

#5 D-G3 — 초대 재발송 흐름. 재발송 횟수·시각을 추적해서:
  * 10분 쿨다운으로 알림 폭격 방지
  * 운영 메트릭: 재발송 비율, 재발송 후 가입 전환률

Revision ID: invite_resend_tracking
Revises: alimtalk_logs
Create Date: 2026-06-01 13:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "invite_resend_tracking"
down_revision: str | None = "alimtalk_logs"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def upgrade() -> None:
    existing = _columns("invites")
    if "resent_count" not in existing:
        op.add_column(
            "invites",
            sa.Column("resent_count", sa.Integer(), nullable=False, server_default=sa.text("0")),
        )
    if "last_resent_at" not in existing:
        op.add_column(
            "invites",
            sa.Column("last_resent_at", sa.DateTime(timezone=True), nullable=True),
        )


def downgrade() -> None:
    existing = _columns("invites")
    if "last_resent_at" in existing:
        op.drop_column("invites", "last_resent_at")
    if "resent_count" in existing:
        op.drop_column("invites", "resent_count")
