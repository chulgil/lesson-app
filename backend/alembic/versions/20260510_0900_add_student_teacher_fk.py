"""add_student_teacher_fk

Bind teacher-owned student profiles to teachers.id while preserving
parent-created child profiles that do not have a teacher yet.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy import inspect

from alembic import op

revision: str = "add_student_teacher_fk"
down_revision: str | None = "add_teacher_student_relation_fks"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _has_constraint(bind: sa.Engine, table_name: str, constraint_name: str) -> bool:
    return any(fk["name"] == constraint_name for fk in inspect(bind).get_foreign_keys(table_name=table_name))


def upgrade() -> None:
    bind = op.get_bind()

    op.execute("UPDATE students SET teacher_id = NULL WHERE teacher_id = ''")
    op.execute(
        """
        UPDATE students
        SET teacher_id = NULL
        WHERE teacher_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1
              FROM teachers
              WHERE teachers.id = students.teacher_id
          )
        """
    )

    with op.batch_alter_table("students") as batch_op:
        batch_op.alter_column("teacher_id", existing_type=sa.String(length=36), nullable=True)
        if not _has_constraint(bind, "students", "fk_students_teacher_id_teachers"):
            batch_op.create_foreign_key(
                "fk_students_teacher_id_teachers",
                "teachers",
                ["teacher_id"],
                ["id"],
                ondelete="RESTRICT",
            )


def downgrade() -> None:
    with op.batch_alter_table("students") as batch_op:
        batch_op.drop_constraint("fk_students_teacher_id_teachers", type_="foreignkey")

    op.execute("UPDATE students SET teacher_id = '' WHERE teacher_id IS NULL")

    with op.batch_alter_table("students") as batch_op:
        batch_op.alter_column("teacher_id", existing_type=sa.String(length=36), nullable=False)
