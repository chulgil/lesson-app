"""add_user_quest_celebrated_at

§13 퀘스트 시스템 — 11/11 완료 시 축하 카드 1회 표시 보장.

User 모델에 ``quest_celebrated_at`` (nullable datetime) 추가. 11개 퀘스트
모두 완료된 시점에 BE 가 1회 set. 이후 재진입/재설치 시에도 카드 미표시
(FE Hive 로컬 저장은 기기 재설치 시 false-positive 재표시 risk).

Refs:
- .harness/spec/2026-06-08-teacher-quest-system.md §8.2, §12.2
- .harness/decomposition/2026-06-08-teacher-quest-system.md Job 0 Task 0.2

Revision ID: add_user_quest_celebrated_at
Revises: merge_phase14_heads
Create Date: 2026-06-08 15:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_user_quest_celebrated_at"
down_revision: str | None = "merge_phase14_heads"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("quest_celebrated_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "quest_celebrated_at")
