"""add_user_consent_fields

#430 G1 B2 — 약관 동의 영속 저장.
phone_verification_policy.md §5.2 의 요구사항:
  * terms_accepted_at: 서비스 이용약관 + 개인정보 처리방침 (필수 묶음)
  * marketing_consent_at: 마케팅 정보 수신 (정보통신망법 §50 별도 동의)

기존 사용자는 NULL 상태 (재로그인 시 약관 페이지 노출되어 동의 기록).

Revision ID: user_consent_fields
Revises: alimtalk_vacation_period_id
Create Date: 2026-06-02 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "user_consent_fields"
down_revision: str | None = "alimtalk_vacation_period_id"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def upgrade() -> None:
    existing = _columns("users")
    if "terms_accepted_at" not in existing:
        op.add_column(
            "users",
            sa.Column("terms_accepted_at", sa.DateTime(timezone=True), nullable=True),
        )
    if "marketing_consent_at" not in existing:
        op.add_column(
            "users",
            sa.Column("marketing_consent_at", sa.DateTime(timezone=True), nullable=True),
        )


def downgrade() -> None:
    existing = _columns("users")
    if "marketing_consent_at" in existing:
        op.drop_column("users", "marketing_consent_at")
    if "terms_accepted_at" in existing:
        op.drop_column("users", "terms_accepted_at")
