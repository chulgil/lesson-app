"""Add lesson_id FKs to lesson_pieces / lesson_recordings.

#1250 — both tables had bare lesson_id columns. The only delete path
(lesson_service.delete) cleans them up explicitly, but nothing enforced
integrity at the schema level, so any other write path could strand orphan
rows. Pre-existing orphans are removed before the constraints land.

Revision ID: add_lesson_piece_recording_fks
Revises: add_invite_code_expiry
Create Date: 2026-08-10 12:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "add_lesson_piece_recording_fks"
down_revision: str | None = "add_invite_code_expiry"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Remove orphans first — the new constraints would reject them.
    op.execute("DELETE FROM lesson_pieces WHERE lesson_id NOT IN (SELECT id FROM lessons)")
    op.execute("DELETE FROM lesson_recordings WHERE lesson_id NOT IN (SELECT id FROM lessons)")

    with op.batch_alter_table("lesson_pieces") as batch_op:
        batch_op.create_foreign_key(
            "fk_lesson_pieces_lesson_id_lessons",
            "lessons",
            ["lesson_id"],
            ["id"],
            ondelete="CASCADE",
        )

    with op.batch_alter_table("lesson_recordings") as batch_op:
        batch_op.create_foreign_key(
            "fk_lesson_recordings_lesson_id_lessons",
            "lessons",
            ["lesson_id"],
            ["id"],
            ondelete="CASCADE",
        )


def downgrade() -> None:
    with op.batch_alter_table("lesson_recordings") as batch_op:
        batch_op.drop_constraint("fk_lesson_recordings_lesson_id_lessons", type_="foreignkey")

    with op.batch_alter_table("lesson_pieces") as batch_op:
        batch_op.drop_constraint("fk_lesson_pieces_lesson_id_lessons", type_="foreignkey")
