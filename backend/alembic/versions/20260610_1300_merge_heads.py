"""Merge heads — student_payment_request_target + invite_expiring_soon_notif.

PR #653 + #654 가 동시에 별도 head 로 머지되어 발생. 본 merge 는 no-op.

Revision ID: merge_heads_20260610
Revises: student_payment_request_target, invite_expiring_soon_notif
Create Date: 2026-06-10 13:00:00
"""

from __future__ import annotations

revision: str = "merge_heads_20260610"
down_revision: tuple[str, ...] = (
    "student_payment_request_target",
    "invite_expiring_soon_notif",
)
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
