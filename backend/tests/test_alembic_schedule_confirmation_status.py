"""Contract tests for schedule confirmation card status enum migrations."""

from pathlib import Path

import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory

from app.models.policy import ConfirmationCardStatus


@pytest.fixture(autouse=True)
def setup_db() -> None:
    """Disable the suite-wide create_all fixture; these tests inspect migration files only."""


def _script() -> ScriptDirectory:
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    return ScriptDirectory.from_config(cfg)


def test_schedule_confirmation_status_migration_chains_after_device_tokens() -> None:
    """The enum alignment migration should follow the current device token head."""
    script = _script()
    rev = script.get_revision("align_schedule_confirmation_status_enum")

    assert rev is not None
    assert rev.down_revision == "add_device_tokens"


def test_schedule_confirmation_status_migration_declares_all_model_values() -> None:
    """PostgreSQL confirmationcardstatus should include every model enum value."""
    script = _script()
    rev = script.get_revision("align_schedule_confirmation_status_enum")

    assert rev is not None

    source = Path(rev.module.__file__).read_text()
    assert "confirmationcardstatus" in source
    assert "ALTER TYPE" in source
    assert "ADD VALUE" in source
    assert "IF NOT EXISTS" in source
    for status in ConfirmationCardStatus:
        assert f"'{status.value}'" in source


def test_schedule_confirmation_status_migration_has_downgrade() -> None:
    """Enum alignment migration should define a downgrade path."""
    script = _script()
    rev = script.get_revision("align_schedule_confirmation_status_enum")

    assert rev is not None

    source = Path(rev.module.__file__).read_text()
    assert "def downgrade" in source
