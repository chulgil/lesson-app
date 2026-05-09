"""Contract tests for teacher-student relationship foreign key integrity."""

from __future__ import annotations

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_teacher_student_relation_fk_targets_are_declared_in_model() -> None:
    """Teacher-student mapping should be FK-bound for both participant IDs."""
    table = Base.metadata.tables["teacher_student_relations"]
    teacher_fk_targets = {fk.target_fullname: fk.ondelete for fk in table.c.teacher_id.foreign_keys}
    student_fk_targets = {fk.target_fullname: fk.ondelete for fk in table.c.student_id.foreign_keys}

    assert teacher_fk_targets["teachers.id"] == "RESTRICT"
    assert student_fk_targets["students.id"] == "CASCADE"


def test_teacher_student_relation_fk_migration_is_chained_and_declares_constraints() -> None:
    """Alembic migration should be discoverable and explicitly declare the new FK constraints."""
    script = _script()
    rev = script.get_revision("add_teacher_student_relation_fks")
    assert rev is not None
    assert rev.down_revision == "add_lesson_source"

    source = Path(rev.module.__file__).read_text()
    assert "fk_teacher_student_relations_teacher_id_teachers" in source
    assert "fk_teacher_student_relations_student_id_students" in source
