"""Phase 24 — Subscription 5 필드 추가 (수강권 수정 spec §6.1 / §7.1).

bonus_reschedule_count           — 수강권별 추가 변경권.
override_cancel_deadline_hours  — 수강권별 개별 취소 기준시간 (null = 기본 정책).
lesson_location_type            — 수강권별 레슨 장소 유형.
lesson_location_id              — 수강권별 레슨 장소 id.
travel_time_minutes             — 수강권별 이동시간(분).

Revision ID: subscription_edit_phase24
Revises: parent_notif_4cat_phase23
Create Date: 2026-06-08 14:00:00
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

revision: str = "subscription_edit_phase24"
down_revision: str | None = "parent_notif_4cat_phase23"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.add_column(
        "subscriptions",
        sa.Column("bonus_reschedule_count", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "subscriptions",
        sa.Column("override_cancel_deadline_hours", sa.Integer(), nullable=True),
    )
    op.add_column(
        "subscriptions",
        sa.Column("lesson_location_type", sa.String(length=40), nullable=True),
    )
    op.add_column(
        "subscriptions",
        sa.Column("lesson_location_id", sa.String(length=36), nullable=True),
    )
    op.add_column(
        "subscriptions",
        sa.Column("travel_time_minutes", sa.Integer(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("subscriptions", "travel_time_minutes")
    op.drop_column("subscriptions", "lesson_location_id")
    op.drop_column("subscriptions", "lesson_location_type")
    op.drop_column("subscriptions", "override_cancel_deadline_hours")
    op.drop_column("subscriptions", "bonus_reschedule_count")
