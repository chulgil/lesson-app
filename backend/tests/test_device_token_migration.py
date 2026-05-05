"""Contract tests for device token database migration coverage."""

from pathlib import Path

import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.base import Base
from app.models.device_token import DevicePlatform


@pytest.fixture(autouse=True)
def setup_db() -> None:
    """Disable the suite-wide create_all fixture; these tests inspect migration files only."""


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_device_token_model_is_registered_in_metadata() -> None:
    """DeviceToken should be part of Base.metadata used by Alembic autogenerate."""
    table = Base.metadata.tables["device_tokens"]

    assert table.c.user_id.nullable is False
    assert table.c.token.unique is True
    assert table.c.platform.nullable is False


def test_device_token_migration_creates_table_and_indexes() -> None:
    """Migrated databases should have the same device_tokens table as create_all DBs."""
    script = _script()
    rev = script.get_revision("add_device_tokens")

    assert rev is not None
    assert rev.down_revision == "add_practice_pieces"

    source = Path(rev.module.__file__).read_text()
    assert "op.create_table(" in source
    assert "\"device_tokens\"" in source
    assert "\"user_id\"" in source
    assert "\"token\"" in source
    assert "\"platform\"" in source
    assert "idx_device_token_user" in source
    assert "idx_device_token_token" in source
    for platform in DevicePlatform:
        assert f"\"{platform.value}\"" in source


def test_device_token_migration_has_downgrade() -> None:
    """Device token migration should be reversible."""
    script = _script()
    rev = script.get_revision("add_device_tokens")

    assert rev is not None

    source = Path(rev.module.__file__).read_text()
    assert "def downgrade" in source
    assert "op.drop_table(\"device_tokens\")" in source
