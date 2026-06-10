"""Phase 43 — PracticeRecording.title + shared_at 컬럼 추가.

2026-06-10 audit P1 #3 #4 — FE 가 녹음 제목 + 공유 시각 표시 가능하도록.

Revision ID: recording_title_shared_at
Revises: merge_heads_20260610
Create Date: 2026-06-10 14:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "recording_title_shared_at"
down_revision: str | None = "merge_heads_20260610"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "practice_recordings",
        sa.Column("title", sa.String(length=200), nullable=True),
    )
    op.add_column(
        "practice_recordings",
        sa.Column("shared_at", sa.DateTime(timezone=True), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("practice_recordings", "shared_at")
    op.drop_column("practice_recordings", "title")
