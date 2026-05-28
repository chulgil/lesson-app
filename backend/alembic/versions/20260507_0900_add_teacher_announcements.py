"""Add teacher announcement tables and day-off date storage.

Revision ID: add_teacher_announcements
Revises: add_subscription_counter_checks
Create Date: 2026-05-07 09:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "add_teacher_announcements"
down_revision: str | None = "add_subscription_counter_checks"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "teacher_announcements",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("teacher_id", sa.String(length=36), nullable=False),
        sa.Column(
            "type",
            sa.Enum(
                "dayOff",
                "general",
                name="teacherannouncementtype",
                native_enum=True,
            ),
            nullable=False,
        ),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("notified_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("(CURRENT_TIMESTAMP)")
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("(CURRENT_TIMESTAMP)"),
        ),
        sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_teacher_announcements_teacher_created", "teacher_announcements", ["teacher_id", "created_at"])
    op.create_index("idx_teacher_announcements_type", "teacher_announcements", ["teacher_id", "type"])

    op.create_table(
        "teacher_announcement_dates",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("teacher_announcement_id", sa.String(length=36), nullable=False),
        sa.Column("announcement_date", sa.Date(), nullable=False),
        sa.ForeignKeyConstraint(["teacher_announcement_id"], ["teacher_announcements.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "teacher_announcement_id", "announcement_date", name="uq_teacher_announcement_dates_per_announcement_date"
        ),
    )
    op.create_index(
        "idx_teacher_announcement_dates_announcement", "teacher_announcement_dates", ["teacher_announcement_id"]
    )
    op.create_index("idx_teacher_announcement_dates_teacher", "teacher_announcement_dates", ["announcement_date"])


def downgrade() -> None:
    op.drop_index("idx_teacher_announcement_dates_teacher", table_name="teacher_announcement_dates")
    op.drop_index("idx_teacher_announcement_dates_announcement", table_name="teacher_announcement_dates")
    op.drop_table("teacher_announcement_dates")
    op.drop_index("idx_teacher_announcements_type", table_name="teacher_announcements")
    op.drop_index("idx_teacher_announcements_teacher_created", table_name="teacher_announcements")
    op.drop_table("teacher_announcements")

    # PostgreSQL native enum type persists after drop_table; explicit drop required.
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("DROP TYPE IF EXISTS teacherannouncementtype")
