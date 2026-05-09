"""Contract tests for parent profile foreign key integrity."""

from __future__ import annotations

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_parent_user_fk_target_is_declared_in_model() -> None:
    """Parent profiles should be FK-bound to their auth account."""
    table = Base.metadata.tables["parents"]
    user_fk_targets = {fk.target_fullname: fk.ondelete for fk in table.c.user_id.foreign_keys}

    assert user_fk_targets["users.id"] == "CASCADE"
    assert table.c.user_id.nullable is False


def test_parent_user_fk_migration_is_chained_and_declares_constraint() -> None:
    """Alembic migration should explicitly add the parent user FK."""
    script = _script()
    rev = script.get_revision("add_parent_user_fk")
    assert rev is not None
    assert rev.down_revision == "add_student_user_fk"

    source = Path(rev.module.__file__).read_text()
    assert "fk_parents_user_id_users" in source
    assert 'ondelete="CASCADE"' in source
