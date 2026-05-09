"""add_teacher_student_relation_fks

Enforce referential integrity for teacher-student relations.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy import inspect

from alembic import op

revision: str = "add_teacher_student_relation_fks"
down_revision: str | None = "add_lesson_source"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _has_constraint(bind: sa.Engine, table_name: str, constraint_name: str) -> bool:
    return any(fk["name"] == constraint_name for fk in inspect(bind).get_foreign_keys(table_name=table_name))


def upgrade() -> None:
    bind = op.get_bind()

    with op.batch_alter_table("teacher_student_relations") as batch_op:
        if not _has_constraint(bind, "teacher_student_relations", "fk_teacher_student_relations_teacher_id_teachers"):
            batch_op.create_foreign_key(
                "fk_teacher_student_relations_teacher_id_teachers",
                "teachers",
                ["teacher_id"],
                ["id"],
                ondelete="RESTRICT",
            )
        if not _has_constraint(bind, "teacher_student_relations", "fk_teacher_student_relations_student_id_students"):
            batch_op.create_foreign_key(
                "fk_teacher_student_relations_student_id_students",
                "students",
                ["student_id"],
                ["id"],
                ondelete="CASCADE",
            )


def downgrade() -> None:
    with op.batch_alter_table("teacher_student_relations") as batch_op:
        batch_op.drop_constraint("fk_teacher_student_relations_student_id_students", type_="foreignkey")
        batch_op.drop_constraint("fk_teacher_student_relations_teacher_id_teachers", type_="foreignkey")
