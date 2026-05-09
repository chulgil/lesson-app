"""add_parent_user_fk

Bind parent profiles to their auth account.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy import inspect

from alembic import op

revision: str = "add_parent_user_fk"
down_revision: str | None = "add_student_user_fk"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _has_constraint(bind: sa.Engine, table_name: str, constraint_name: str) -> bool:
    return any(fk["name"] == constraint_name for fk in inspect(bind).get_foreign_keys(table_name=table_name))


def upgrade() -> None:
    bind = op.get_bind()

    op.execute(
        """
        DELETE FROM parents
        WHERE user_id IS NULL
           OR user_id = ''
           OR NOT EXISTS (
               SELECT 1
               FROM users
               WHERE users.id = parents.user_id
           )
        """
    )

    with op.batch_alter_table("parents") as batch_op:
        if not _has_constraint(bind, "parents", "fk_parents_user_id_users"):
            batch_op.create_foreign_key(
                "fk_parents_user_id_users",
                "users",
                ["user_id"],
                ["id"],
                ondelete="CASCADE",
            )


def downgrade() -> None:
    with op.batch_alter_table("parents") as batch_op:
        batch_op.drop_constraint("fk_parents_user_id_users", type_="foreignkey")
