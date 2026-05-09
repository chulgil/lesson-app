"""Verify alembic upgrade head works on a clean SQLite database.

All PostgreSQL-specific DDL (ALTER TYPE, Enum.create/drop, ALTER COLUMN...TYPE)
must be wrapped with dialect guards so that the migration chain completes on
SQLite for local dev/testing.

Refs #310.
"""

import tempfile
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine


def _make_sqlite_config(db_path: str) -> Config:
    """Create an Alembic config pointing to a temporary SQLite database."""
    backend_root = Path(__file__).resolve().parent.parent
    cfg = Config(str(backend_root / "alembic.ini"))
    cfg.set_main_option("sqlalchemy.url", f"sqlite:///{db_path}")
    cfg.set_main_option("script_location", str(backend_root / "alembic"))
    return cfg


def test_sqlite_upgrade_head_succeeds() -> None:
    """Clean SQLite DB에서 alembic upgrade head가 에러 없이 완료돼야 한다."""
    with tempfile.TemporaryDirectory() as tmpdir:
        db_path = Path(tmpdir) / "test_chain.db"
        cfg = _make_sqlite_config(str(db_path))

        # Override env.py: use ALEMBIC_DATABASE_URL env var to force SQLite
        import os
        os.environ["ALEMBIC_DATABASE_URL"] = f"sqlite:///{db_path}"

        try:
            command.upgrade(cfg, "head")
        finally:
            os.environ.pop("ALEMBIC_DATABASE_URL", None)

        assert db_path.exists(), "SQLite database file should be created"
