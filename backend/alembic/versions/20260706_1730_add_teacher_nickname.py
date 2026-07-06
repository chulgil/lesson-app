"""Issue #1145 — teachers.nickname 컬럼 추가.

선생님이 학생에게 보여줄 표시 이름(호칭/닉네임)을 저장하는 컬럼.
null 이면 클라이언트가 User.name 으로 폴백한다. additive nullable = 무손실.

Revision ID: add_teacher_nickname
Revises: drop_practice_streaks
Create Date: 2026-07-06 17:30:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "add_teacher_nickname"
down_revision: str | None = "drop_practice_streaks"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "teachers",
        sa.Column("nickname", sa.String(length=100), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("teachers", "nickname")
