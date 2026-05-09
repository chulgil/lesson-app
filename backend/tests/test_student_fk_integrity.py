"""Contract tests for student ownership foreign key integrity."""

from __future__ import annotations

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_student_teacher_fk_target_is_declared_in_model() -> None:
    """Teacher-owned student profiles should be FK-bound to teachers.id."""
    table = Base.metadata.tables["students"]
    teacher_fk_targets = {fk.target_fullname: fk.ondelete for fk in table.c.teacher_id.foreign_keys}

    assert teacher_fk_targets["teachers.id"] == "RESTRICT"
    assert table.c.teacher_id.nullable is True


def test_student_teacher_fk_migration_is_chained_and_declares_constraint() -> None:
    """Alembic migration should explicitly add the nullable student teacher FK."""
    script = _script()
    rev = script.get_revision("add_student_teacher_fk")
    assert rev is not None
    assert rev.down_revision == "add_teacher_student_relation_fks"

    source = Path(rev.module.__file__).read_text()
    assert "fk_students_teacher_id_teachers" in source
    assert "nullable=True" in source
