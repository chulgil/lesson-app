"""Issue #1178 — cancellation_defaults 테이블 추가 (취소정책 4필드 BE 영속화).

비학원 교사의 지각취소 보상 정책(활성화/문구 병기/커스텀 문구/원장 알림)이
FE 로컬(Hive)에만 저장되어 서버 알림 발송에 반영되지 못하던 #1167 스펙 §4
한계를 해소한다. teacher_id 는 teachers.id 를 저장한다 (형제 settings 테이블의
user id 관행과 다름 — Lesson.teacher_id 와 직접 조인하기 위함).
새 테이블만 추가하는 additive 마이그레이션 — 기존 데이터/스키마 무변경, 무손실.

Revision ID: add_cancellation_defaults
Revises: add_idempotency_keys
Create Date: 2026-07-11 15:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "add_cancellation_defaults"
down_revision: str | None = "add_idempotency_keys"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "cancellation_defaults",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column("cancellation_deadline_hours", sa.Integer(), nullable=False, server_default="12"),
        sa.Column(
            "student_compensation_extra_minutes_enabled",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
        sa.Column(
            "include_extra_minutes_text_on_late_cancel",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
        sa.Column("student_compensation_extra_minutes_message", sa.Text(), nullable=True),
        sa.Column("notify_owner_on_late_cancel", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id", name="pk_cancellation_defaults"),
    )
    op.create_index(
        "uk_cancellation_defaults_teacher",
        "cancellation_defaults",
        ["teacher_id"],
        unique=True,
    )


def downgrade() -> None:
    op.drop_index("uk_cancellation_defaults_teacher", table_name="cancellation_defaults")
    op.drop_table("cancellation_defaults")
