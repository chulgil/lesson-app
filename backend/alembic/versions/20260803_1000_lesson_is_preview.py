"""lessons 에 is_preview 컬럼 추가 (레슨 추가 인텐트 §2.6.2)

Revision ID: lesson_is_preview
Revises: group_booking_reminder_sent_at
Create Date: 2026-08-03 12:00:00.000000

왜 컬럼인가
-----------
잔여 0 수강권에서 "갱신 제안 보내기" 를 선택하면 레슨을 미리보기(preview)로
캘린더에 걸어두고, 갱신 입금 확인 시 정식 회차로 전환한다
(subscription_required_spec §2.6.2, overflow_mode=renewal_pending).

FE 계약은 이미 존재한다 — `Lesson.isPreview` 가 `json['is_preview'] ?? false`
로 파싱 중이며(lesson.g.dart), BE 가 컬럼을 갖지 않아 원격 레슨은 항상
false 였다. 이 컬럼이 그 계약을 완성한다.

  (A) BOOLEAN NOT NULL server_default false — 기존 행 전부 "정식 레슨"
      의미 그대로. 추가 백필 불필요. ← 채택
  (B) 상태(enum) 확장으로 preview 표현 — LessonStatus 는 PG native enum 이라
      ADD VALUE 마이그레이션 + 상태기계 전이표 갱신이 필요하고, preview 는
      라이프사이클 상태가 아니라 회계 속성이다. → 거절.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "lesson_is_preview"
down_revision: str | None = "group_booking_reminder_sent_at"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "lessons",
        sa.Column("is_preview", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("lessons", "is_preview")
