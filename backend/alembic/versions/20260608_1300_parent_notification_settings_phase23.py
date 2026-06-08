"""Phase 23 — ParentNotificationSettings 4개 카테고리 추가.

spec parent_system.md §12.7 — 수강권 잔여 / 만료 임박 / 등록 완료 / 레슨 장소 변경.
모두 default True (spec 권장).

Revision ID: parent_notif_4cat_phase23
Revises: add_lesson_request_location
Create Date: 2026-06-08 13:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "parent_notif_4cat_phase23"
down_revision: str | None = "add_lesson_request_location"
branch_labels: str | None = None
depends_on: str | None = None


_NEW_COLUMNS = (
    "subscription_low_remaining",
    "subscription_expiring_soon",
    "subscription_registered",
    "lesson_location_change",
)


def upgrade() -> None:
    for column in _NEW_COLUMNS:
        op.add_column(
            "parent_notification_settings",
            sa.Column(column, sa.Boolean(), nullable=False, server_default=sa.true()),
        )


def downgrade() -> None:
    for column in _NEW_COLUMNS:
        op.drop_column("parent_notification_settings", column)
