"""Contract tests for lesson subscription session number persistence."""

from __future__ import annotations

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_lesson_session_number_column_is_declared_in_model() -> None:
    """Lessons linked to a subscription should be able to persist their session number."""
    table = Base.metadata.tables["lessons"]

    assert "session_number" in table.c
    assert table.c.session_number.nullable is True
    assert "idx_lesson_subscription_session" in {index.name for index in table.indexes}
    constraint_names = {constraint.name for constraint in table.constraints}
    assert "ck_lessons_session_number_positive" in constraint_names
    assert "ck_lessons_duration_positive" in constraint_names


def test_lesson_session_number_migration_is_chained_and_declares_contract() -> None:
    """Alembic migration should add the session number column and integrity helpers."""
    script = _script()
    rev = script.get_revision("add_lesson_session_number")
    assert rev is not None
    assert rev.down_revision == "add_student_teacher_fk"

    source = Path(rev.module.__file__).read_text()
    assert "session_number" in source
    assert "idx_lesson_subscription_session" in source
    assert "ck_lessons_session_number_positive" in source
    assert "ck_lessons_duration_positive" in source
