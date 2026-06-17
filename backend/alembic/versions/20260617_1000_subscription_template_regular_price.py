"""SubscriptionTemplate.regular_price 컬럼 추가 (정가/할인가 표기).

2026-06-17 — 수강권 템플릿에 정가(regular_price)를 추가해 카드/시트에서
정가 취소선 + 판매가(amount) + 할인율을 표시한다. nullable 이므로 기존
템플릿은 동작 변화 없음(단일가 유지).

Revision ID: tmpl_regular_price
Revises: ac_m3_student_parent_name
Create Date: 2026-06-17 10:00:00

Note: revision id is kept <= 32 chars because alembic_version.version_num is
varchar(32) by default (a longer id truncates on UPDATE).
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "tmpl_regular_price"
down_revision: str | None = "ac_m3_student_parent_name"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "subscription_templates",
        sa.Column("regular_price", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("subscription_templates", "regular_price")
