"""ac_m2_user_tokens_revoked_at

AC-M2 §7.2 — 다중 디바이스 일괄 만료 epoch.

User 모델에 ``tokens_revoked_at`` (nullable datetime) 추가. 토글/강제
로그아웃 시 갱신, ``get_current_user`` 가 ``access_token.iat`` 와 비교해
이전 발급 토큰을 401 처리. jti 추적 없이도 같은 user 의 모든 활성 디바이스
를 한 번에 만료.

Revision ID: ac_m2_user_tokens_revoked_at
Revises: ac_m2_context_denial_log
Create Date: 2026-06-05 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "ac_m2_user_tokens_revoked_at"
down_revision: str | None = "ac_m2_context_denial_log"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("tokens_revoked_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "tokens_revoked_at")
