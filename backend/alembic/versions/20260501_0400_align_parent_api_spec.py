"""Align parent API storage with frontend spec.

Revision ID: align_parent_api_spec
Revises: add_parent_visibility_settings
Create Date: 2026-05-01 04:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "align_parent_api_spec"
down_revision: str | None = "add_parent_visibility_settings"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    is_pg = op.get_context().dialect.name == "postgresql"

    relation_status = sa.Enum("pending", "active", "inactive", name="parentchildrelationstatus")
    invitation_source = sa.Enum("student", "teacher", name="parentinvitationsource")

    if is_pg:
        invitation_source_column = postgresql.ENUM(
            "student",
            "teacher",
            name="parentinvitationsource",
            create_type=False,
        )
        relation_status.create(op.get_bind(), checkfirst=True)
        invitation_source.create(op.get_bind(), checkfirst=True)
    else:
        invitation_source_column = sa.Enum(
            "student", "teacher", name="parentinvitationsource", create_constraint=False,
        )

    op.add_column(
        "parent_child_relations",
        sa.Column("is_primary_guardian", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "parent_child_relations",
        sa.Column("is_billing_target", sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.add_column(
        "parent_child_relations",
        sa.Column("status", relation_status, nullable=False, server_default="active"),
    )
    op.add_column(
        "parent_child_relations",
        sa.Column("unlinked_at", sa.DateTime(timezone=True), nullable=True),
    )

    if is_pg:
        op.alter_column("parent_child_relations", "is_primary_guardian", server_default=None)
        op.alter_column("parent_child_relations", "is_billing_target", server_default=None)
        op.alter_column("parent_child_relations", "status", server_default=None)

    op.create_table(
        "parent_invitations",
        sa.Column("student_id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=True),
        sa.Column("source", invitation_source_column, nullable=False),
        sa.Column("parent_phone", sa.String(length=20), nullable=False),
        sa.Column("parent_email", sa.String(length=255), nullable=True),
        sa.Column("invitation_code", sa.String(length=20), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("is_used", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("uk_parent_invitation_code", "parent_invitations", ["invitation_code"], unique=True)
    op.create_index("idx_parent_invitation_student", "parent_invitations", ["student_id"], unique=False)

    for column in ("lesson_start", "lesson_end", "practice_complete", "streak_achievement", "lesson_note_update"):
        op.execute(sa.text(f"UPDATE parent_notification_settings SET {column} = false"))
        if is_pg:
            op.alter_column("parent_notification_settings", column, server_default=sa.false())


def downgrade() -> None:
    op.drop_index("idx_parent_invitation_student", table_name="parent_invitations")
    op.drop_index("uk_parent_invitation_code", table_name="parent_invitations")
    op.drop_table("parent_invitations")

    op.drop_column("parent_child_relations", "unlinked_at")
    op.drop_column("parent_child_relations", "status")
    op.drop_column("parent_child_relations", "is_billing_target")
    op.drop_column("parent_child_relations", "is_primary_guardian")

    for column in ("lesson_start", "lesson_end", "practice_complete", "streak_achievement", "lesson_note_update"):
        op.alter_column("parent_notification_settings", column, server_default=sa.true())

    if op.get_context().dialect.name == "postgresql":
        sa.Enum(name="parentinvitationsource").drop(op.get_bind(), checkfirst=True)
        sa.Enum(name="parentchildrelationstatus").drop(op.get_bind(), checkfirst=True)
