"""Verify parent API alignment migration details."""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_parent_invitation_enum_is_not_created_twice_in_offline_sql() -> None:
    """The table column must reuse the pre-created PostgreSQL enum type."""
    script = _script()
    rev = script.get_revision("align_parent_api_spec")
    assert rev is not None

    source = Path(rev.module.__file__).read_text()
    assert "parentinvitationsource" in source
    assert "create_type=False" in source
