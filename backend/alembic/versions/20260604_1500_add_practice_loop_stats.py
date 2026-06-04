"""add_practice_loop_stats

#512 — 선생님 측 학생별 반복 통계 (Practice Loop Stats).

선생님이 학생별 영상 구간 반복 진척도를 확인할 수 있도록
(student_id, section_id) 키의 누적 집계 테이블을 신규로 만든다.

Spec: docs/specs/practice/youtube_loop_practice_spec.md §4/§5 (선생님 통계 + 동기화)

Revision ID: practice_loop_stats
Revises: ac_m1_group_c_billing
Create Date: 2026-06-04 15:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "practice_loop_stats"
down_revision: str | None = "ac_m1_group_c_billing"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _has_table(table_name: str) -> bool:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return inspector.has_table(table_name)


def upgrade() -> None:
    if _has_table("practice_loop_stats"):
        return

    op.create_table(
        "practice_loop_stats",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column(
            "student_id",
            sa.String(length=36),
            sa.ForeignKey("students.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "teacher_id",
            sa.String(length=36),
            sa.ForeignKey("teachers.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "section_id",
            sa.String(length=36),
            sa.ForeignKey("practice_sections.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("repeat_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "last_played_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
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
    )
    op.create_index(
        "uk_loop_stats_student_section",
        "practice_loop_stats",
        ["student_id", "section_id"],
        unique=True,
    )
    op.create_index(
        "idx_loop_stats_teacher",
        "practice_loop_stats",
        ["teacher_id"],
    )
    op.create_index(
        "idx_loop_stats_last_played",
        "practice_loop_stats",
        ["last_played_at"],
    )


def downgrade() -> None:
    if not _has_table("practice_loop_stats"):
        return
    op.drop_index("idx_loop_stats_last_played", table_name="practice_loop_stats")
    op.drop_index("idx_loop_stats_teacher", table_name="practice_loop_stats")
    op.drop_index("uk_loop_stats_student_section", table_name="practice_loop_stats")
    op.drop_table("practice_loop_stats")
