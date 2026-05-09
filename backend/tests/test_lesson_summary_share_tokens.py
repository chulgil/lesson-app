"""Contract tests for lesson summary share token persistence."""

from __future__ import annotations

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_lesson_summary_share_token_model_declares_secure_token_contract() -> None:
    table = Base.metadata.tables["lesson_summary_share_tokens"]

    assert "token_hash" in table.c
    assert "token" not in table.c
    assert table.c.token_hash.unique is True
    assert table.c.expires_at.nullable is False

    constraint_names = {constraint.name for constraint in table.constraints}
    assert "ck_lesson_summary_share_tokens_access_count_non_negative" in constraint_names

    fk_targets = {
        str(foreign_key.column)
        for column in table.c
        for foreign_key in column.foreign_keys
    }
    assert "lessons.id" in fk_targets
    assert "users.id" in fk_targets


def test_lesson_summary_share_token_migration_is_chained_and_declares_contract() -> None:
    script = _script()
    rev = script.get_revision("add_lesson_summary_share_tokens")
    assert rev is not None
    assert rev.down_revision == "add_app_version_tables"

    source = Path(rev.module.__file__).read_text()
    assert "lesson_summary_share_tokens" in source
    assert "token_hash" in source
    assert "fk_lesson_summary_share_tokens_lesson_id_lessons" in source
    assert "fk_lesson_summary_share_tokens_teacher_id_users" in source
    assert "ck_lesson_summary_share_tokens_access_count_non_negative" in source
