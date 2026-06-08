"""Phase 21 — spec compliance enum 확장 (subscription / relation).

spec subscription_master.md §2.3 + invite_lifecycle_spec.md §4.1 의 enum 갱신을 DB 에 반영.

추가 enum 값:
- ``subscription_status``: ``pending``, ``exhausted``, ``suspended``, ``cancelled``
- ``relation_status``: ``invitePending``

PostgreSQL 은 ``ALTER TYPE ... ADD VALUE`` 로 추가. SQLite (tests) 는 enum 이 TEXT 라 자동.

NOTE: 기존 row 의 status 값은 변경 없음 — 새 값 추가만. 기존 데이터 호환성 유지.

Revision ID: expand_status_enums_phase21
Revises: add_user_quest_celebrated_at
Create Date: 2026-06-08 11:00:00
"""

from __future__ import annotations

from alembic import op

revision: str = "expand_status_enums_phase21"
down_revision: str | None = "add_user_quest_celebrated_at"
branch_labels: str | None = None
depends_on: str | None = None


_SUBSCRIPTION_STATUS_NEW = ("pending", "exhausted", "suspended", "cancelled")
_RELATION_STATUS_NEW = ("invitePending",)


def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        # SQLite / 기타: enum 이 TEXT 로 저장되어 자동 — 노옵.
        return

    # spec 명시 새 enum 값 추가. 이미 존재 시 IF NOT EXISTS 로 멱등.
    for value in _SUBSCRIPTION_STATUS_NEW:
        op.execute(f"ALTER TYPE subscriptionstatus ADD VALUE IF NOT EXISTS '{value}'")
    for value in _RELATION_STATUS_NEW:
        op.execute(f"ALTER TYPE relationstatus ADD VALUE IF NOT EXISTS '{value}'")


def downgrade() -> None:
    # PG enum 값 제거는 위험 (제약·인덱스 영향). 명시적 noop — 정책 결정 후 별도 작업.
    pass
