"""Add invite_code_expires_at to teacher_student_relations.

#1250 — relation invite codes had no expiry at all (unlike InviteService's
Invite, which enforces expires_at + use limits), so a shared code stayed a
live backdoor into the relation forever. New invites get a 7-day expiry;
existing outstanding codes are backfilled with a 7-day grace window from
deploy instead of dying instantly.

Revision ID: add_invite_code_expiry
Revises: lesson_is_preview
Create Date: 2026-08-10 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_invite_code_expiry"
down_revision: str | None = "lesson_is_preview"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "teacher_student_relations",
        sa.Column("invite_code_expires_at", sa.DateTime(timezone=True), nullable=True),
    )

    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute(
            "UPDATE teacher_student_relations "
            "SET invite_code_expires_at = now() + interval '7 days' "
            "WHERE invite_code IS NOT NULL AND invite_code_expires_at IS NULL"
        )


def downgrade() -> None:
    op.drop_column("teacher_student_relations", "invite_code_expires_at")
