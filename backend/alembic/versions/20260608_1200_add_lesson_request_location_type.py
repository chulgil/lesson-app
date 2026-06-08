"""Phase 22 — LessonRequest.preferred_location_type 추가.

spec unified_lesson_request_spec.md §18 — 학생 신청 시 희망 장소.
값: studentHome / academyRoom / teacherStudio / externalPlace / online (String 으로 저장).

Revision ID: add_lesson_request_location
Revises: expand_status_enums_phase21
Create Date: 2026-06-08 12:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "add_lesson_request_location"
down_revision: str | None = "expand_status_enums_phase21"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "lesson_requests",
        sa.Column("preferred_location_type", sa.String(30), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("lesson_requests", "preferred_location_type")
