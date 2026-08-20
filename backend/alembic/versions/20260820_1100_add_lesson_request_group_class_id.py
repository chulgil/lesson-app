"""Add lesson_requests.group_class_id — cohort enrollment request (J15b).

Nullable column only: the chat-approval flow reuses the existing
lesson_request entities end-to-end, and new RequestEventType/request_type
values are forbidden by the deployed-FE $enumDecode contract.

Revision ID: add_lesson_request_group_class_id
Revises: add_group_class_members
Create Date: 2026-08-20 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_lesson_request_group_class_id"
down_revision: str | None = "add_group_class_members"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("lesson_requests", sa.Column("group_class_id", sa.String(36), nullable=True))


def downgrade() -> None:
    op.drop_column("lesson_requests", "group_class_id")
