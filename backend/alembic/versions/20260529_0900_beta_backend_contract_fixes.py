"""Align beta backend contract with frontend remote repositories.

Revision ID: beta_backend_contract_fixes
Revises: f2e8c3d9b1a2
Create Date: 2026-05-29 09:00:00.000000
"""

import hashlib
from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "beta_backend_contract_fixes"
down_revision: str | None = "f2e8c3d9b1a2"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _columns(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {column["name"] for column in inspector.get_columns(table_name)}


def _indexes(table_name: str) -> set[str]:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    return {index["name"] for index in inspector.get_indexes(table_name)}


def upgrade() -> None:
    lesson_columns = _columns("lessons")
    with op.batch_alter_table("lessons") as batch_op:
        if "is_archived" not in lesson_columns:
            batch_op.add_column(sa.Column("is_archived", sa.Boolean(), server_default=sa.false(), nullable=False))
        if "archived_at" not in lesson_columns:
            batch_op.add_column(sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True))
    if "idx_lesson_archived" not in _indexes("lessons"):
        op.create_index("idx_lesson_archived", "lessons", ["is_archived"])

    share_columns = _columns("share_tokens")
    if "token_hash" in share_columns:
        return

    with op.batch_alter_table("share_tokens") as batch_op:
        batch_op.add_column(sa.Column("token_hash", sa.String(length=128), nullable=True))
        batch_op.add_column(sa.Column("lesson_id", sa.String(length=36), nullable=True))
        batch_op.add_column(sa.Column("teacher_id", sa.String(length=36), nullable=True))
        batch_op.add_column(sa.Column("student_id", sa.String(length=36), nullable=True))
        batch_op.add_column(sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column("last_accessed_at", sa.DateTime(timezone=True), nullable=True))
        batch_op.add_column(sa.Column("access_count", sa.Integer(), server_default="0", nullable=False))

    bind = op.get_bind()
    rows = bind.execute(sa.text("SELECT id, token FROM share_tokens")).mappings().all()
    for row in rows:
        bind.execute(
            sa.text("UPDATE share_tokens SET token_hash = :token_hash WHERE id = :id"),
            {"id": row["id"], "token_hash": hashlib.sha256(row["token"].encode("utf-8")).hexdigest()},
        )

    bind.execute(sa.text("UPDATE share_tokens SET lesson_id = target_id WHERE lesson_id IS NULL"))
    bind.execute(
        sa.text(
            """
            UPDATE share_tokens
            SET teacher_id = COALESCE(
                created_by_user_id,
                (SELECT teacher_id FROM lessons WHERE lessons.id = share_tokens.lesson_id)
            )
            WHERE teacher_id IS NULL
            """
        )
    )
    bind.execute(
        sa.text(
            """
            UPDATE share_tokens
            SET student_id = (SELECT student_id FROM lessons WHERE lessons.id = share_tokens.lesson_id)
            WHERE student_id IS NULL
            """
        )
    )
    bind.execute(
        sa.text(
            """
            DELETE FROM share_tokens
            WHERE token_hash IS NULL OR lesson_id IS NULL OR teacher_id IS NULL
            """
        )
    )

    for index_name in ("idx_share_token_scope_target", "idx_share_token_token"):
        if index_name in _indexes("share_tokens"):
            op.drop_index(index_name, table_name="share_tokens")

    with op.batch_alter_table("share_tokens") as batch_op:
        batch_op.alter_column("token_hash", existing_type=sa.String(length=128), nullable=False)
        batch_op.alter_column("lesson_id", existing_type=sa.String(length=36), nullable=False)
        batch_op.alter_column("teacher_id", existing_type=sa.String(length=36), nullable=False)
        batch_op.drop_column("token")
        batch_op.drop_column("scope")
        batch_op.drop_column("target_id")
        batch_op.drop_column("created_by_user_id")
        batch_op.create_check_constraint(
            "ck_share_tokens_access_count_non_negative",
            "access_count >= 0",
        )
        batch_op.create_foreign_key(
            "fk_share_tokens_lesson_id_lessons",
            "lessons",
            ["lesson_id"],
            ["id"],
            ondelete="CASCADE",
        )
        batch_op.create_foreign_key(
            "fk_share_tokens_teacher_id_users",
            "users",
            ["teacher_id"],
            ["id"],
            ondelete="CASCADE",
        )
        batch_op.create_foreign_key(
            "fk_share_tokens_student_id_students",
            "students",
            ["student_id"],
            ["id"],
            ondelete="SET NULL",
        )

    op.create_index("idx_share_token_hash", "share_tokens", ["token_hash"], unique=True)
    op.create_index("idx_share_token_lesson", "share_tokens", ["lesson_id"])
    op.create_index("idx_share_token_teacher", "share_tokens", ["teacher_id"])


def downgrade() -> None:
    for constraint_name in (
        "fk_share_tokens_student_id_students",
        "fk_share_tokens_teacher_id_users",
        "fk_share_tokens_lesson_id_lessons",
        "ck_share_tokens_access_count_non_negative",
    ):
        constraint_type = "foreignkey" if constraint_name.startswith("fk_") else "check"
        op.drop_constraint(constraint_name, "share_tokens", type_=constraint_type)

    for index_name in ("idx_share_token_teacher", "idx_share_token_lesson", "idx_share_token_hash"):
        if index_name in _indexes("share_tokens"):
            op.drop_index(index_name, table_name="share_tokens")

    with op.batch_alter_table("share_tokens") as batch_op:
        batch_op.add_column(sa.Column("token", sa.String(length=64), nullable=True))
        batch_op.add_column(sa.Column("scope", sa.String(length=50), nullable=True))
        batch_op.add_column(sa.Column("target_id", sa.String(length=36), nullable=True))
        batch_op.add_column(sa.Column("created_by_user_id", sa.String(length=36), nullable=True))
        batch_op.drop_column("access_count")
        batch_op.drop_column("last_accessed_at")
        batch_op.drop_column("revoked_at")
        batch_op.drop_column("student_id")
        batch_op.drop_column("teacher_id")
        batch_op.drop_column("lesson_id")
        batch_op.drop_column("token_hash")

    op.drop_index("idx_lesson_archived", table_name="lessons")
    with op.batch_alter_table("lessons") as batch_op:
        batch_op.drop_column("archived_at")
        batch_op.drop_column("is_archived")
