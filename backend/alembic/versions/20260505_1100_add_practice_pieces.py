"""Add practice piece library tables.

Revision ID: add_practice_pieces
Revises: add_subscription_fk_constraints
Create Date: 2026-05-05 11:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_practice_pieces"
down_revision: str | None = "add_subscription_fk_constraints"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "practice_pieces",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("owner_teacher_id", sa.String(length=36), nullable=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("composer", sa.String(length=200), nullable=True),
        sa.Column("opus", sa.String(length=100), nullable=True),
        sa.Column("movement", sa.String(length=100), nullable=True),
        sa.Column("difficulty", sa.String(length=50), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["owner_teacher_id"], ["teachers.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_practice_piece_owner", "practice_pieces", ["owner_teacher_id"])
    op.create_index("idx_practice_piece_title", "practice_pieces", ["title"])

    op.create_table(
        "student_practice_pieces",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("student_id", sa.String(length=36), nullable=False),
        sa.Column("piece_id", sa.String(length=36), nullable=False),
        sa.Column(
            "progress",
            sa.Enum("notStarted", "inProgress", "polishing", "completed", name="pieceprogress"),
            nullable=False,
        ),
        sa.Column("progress_percentage", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["piece_id"], ["practice_pieces.id"]),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("uk_student_piece", "student_practice_pieces", ["student_id", "piece_id"], unique=True)
    op.create_index("idx_student_piece_student", "student_practice_pieces", ["student_id"])
    op.create_index("idx_student_piece_piece", "student_practice_pieces", ["piece_id"])


def downgrade() -> None:
    op.drop_index("idx_student_piece_piece", table_name="student_practice_pieces")
    op.drop_index("idx_student_piece_student", table_name="student_practice_pieces")
    op.drop_index("uk_student_piece", table_name="student_practice_pieces")
    op.drop_table("student_practice_pieces")
    op.drop_index("idx_practice_piece_title", table_name="practice_pieces")
    op.drop_index("idx_practice_piece_owner", table_name="practice_pieces")
    op.drop_table("practice_pieces")
