"""add practice_journal tables (#872)

Revision ID: add_practice_journal
Revises: merge_0619_heads
Create Date: 2026-06-25 12:47:00.000000

Four append-only tables for the practice-journal domain.

Design decisions:
  - native_enum=False: all enum-like columns use String(10) to avoid
    ALTER TYPE ADD VALUE landmines on Postgres (see project memory).
  - UniqueConstraints match the service-layer idempotency checks.
  - No stored ledger: ledger is computed on read from the four tables.
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "add_practice_journal"
down_revision: str | None = "merge_0619_heads"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # -----------------------------------------------------------------------
    # practice_journal_marks
    # -----------------------------------------------------------------------
    op.create_table(
        "practice_journal_marks",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("child_profile_id", sa.String(36), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("intensity", sa.String(10), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["child_profile_id"],
            ["students.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_practice_journal_marks")),
        sa.UniqueConstraint(
            "child_profile_id",
            "date",
            name="uq_practice_marks_student_date",
        ),
    )
    op.create_index(
        op.f("ix_practice_journal_marks_child_profile_id"),
        "practice_journal_marks",
        ["child_profile_id"],
    )

    # -----------------------------------------------------------------------
    # practice_journal_seals
    # -----------------------------------------------------------------------
    op.create_table(
        "practice_journal_seals",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("child_profile_id", sa.String(36), nullable=False),
        sa.Column("guardian_user_id", sa.String(36), nullable=False),
        sa.Column("week_start", sa.Date(), nullable=False),
        sa.Column("cheer_note", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["child_profile_id"],
            ["students.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["guardian_user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_practice_journal_seals")),
        sa.UniqueConstraint(
            "child_profile_id",
            "week_start",
            name="uq_guardian_seals_student_week",
        ),
    )
    op.create_index(
        op.f("ix_practice_journal_seals_child_profile_id"),
        "practice_journal_seals",
        ["child_profile_id"],
    )

    # -----------------------------------------------------------------------
    # practice_journal_endorsements
    # -----------------------------------------------------------------------
    op.create_table(
        "practice_journal_endorsements",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("child_profile_id", sa.String(36), nullable=False),
        sa.Column("author_user_id", sa.String(36), nullable=False),
        sa.Column("by", sa.String(10), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("assignment_ref", sa.String(64), nullable=True),
        sa.Column("note", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["child_profile_id"],
            ["students.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["author_user_id"],
            ["users.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_practice_journal_endorsements")),
    )
    op.create_index(
        op.f("ix_practice_journal_endorsements_child_profile_id"),
        "practice_journal_endorsements",
        ["child_profile_id"],
    )

    # -----------------------------------------------------------------------
    # practice_journal_volumes
    # -----------------------------------------------------------------------
    op.create_table(
        "practice_journal_volumes",
        sa.Column("id", sa.String(36), nullable=False),
        sa.Column("child_profile_id", sa.String(36), nullable=False),
        sa.Column("piece_id", sa.String(36), nullable=False),
        sa.Column("piece_name", sa.String(200), nullable=False),
        sa.Column("volume_no", sa.Integer(), nullable=False),
        sa.Column("bound_date", sa.Date(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["child_profile_id"],
            ["students.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_practice_journal_volumes")),
        sa.UniqueConstraint(
            "child_profile_id",
            "piece_id",
            name="uq_volumes_student_piece",
        ),
    )
    op.create_index(
        op.f("ix_practice_journal_volumes_child_profile_id"),
        "practice_journal_volumes",
        ["child_profile_id"],
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_practice_journal_volumes_child_profile_id"),
        table_name="practice_journal_volumes",
    )
    op.drop_table("practice_journal_volumes")

    op.drop_index(
        op.f("ix_practice_journal_endorsements_child_profile_id"),
        table_name="practice_journal_endorsements",
    )
    op.drop_table("practice_journal_endorsements")

    op.drop_index(
        op.f("ix_practice_journal_seals_child_profile_id"),
        table_name="practice_journal_seals",
    )
    op.drop_table("practice_journal_seals")

    op.drop_index(
        op.f("ix_practice_journal_marks_child_profile_id"),
        table_name="practice_journal_marks",
    )
    op.drop_table("practice_journal_marks")
