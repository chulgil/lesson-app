"""Alembic async migration environment for Lessonaza backend."""

import asyncio
import os
import sys
from logging.config import fileConfig
from pathlib import Path

# Ensure the backend root is on sys.path so `app` package is importable
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

# Import all models so Base.metadata is fully populated
import app.models  # noqa: F401
from alembic import context
from app.core.config import settings
from app.models.base import Base

# Alembic Config object (provides access to alembic.ini values)
config = context.config

# Override sqlalchemy.url from app settings (or env override for local dev)
db_url = os.environ.get("ALEMBIC_DATABASE_URL") or settings.DATABASE_URL
config.set_main_option("sqlalchemy.url", db_url)

# Set up Python logging from alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# SQLAlchemy MetaData for autogenerate support
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    Configures the context with just a URL and not an Engine.
    Calls to context.execute() emit the given string to the script output.
    """
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Execute migrations within a database connection context.

    SQLite 는 ALTER TABLE 지원이 제한적이라 ``render_as_batch=True`` 로 batch 모드 활성화 —
    alembic 이 새 테이블 생성·데이터 복사·rename 패턴으로 자동 변환한다.
    naming_convention (Base.metadata) 과 결합해 모든 constraint 이름이 결정적이어야 batch 가 성공.
    """
    dialect_name = connection.dialect.name

    # Alembic's default ``alembic_version.version_num`` is VARCHAR(32). Slug-style
    # revision ids longer than 32 chars overflow it on Postgres
    # (StringDataRightTruncationError) and break the entire migration chain — a
    # failure SQLite tests never catch (SQLite ignores VARCHAR length). Ensure the
    # column is wide enough before any version stamp. Idempotent and safe whether
    # the table is absent (fresh DB), narrow (legacy), or already wide.
    if dialect_name == "postgresql":
        from sqlalchemy import text

        with connection.begin():
            connection.execute(
                text(
                    "CREATE TABLE IF NOT EXISTS alembic_version ("
                    "version_num VARCHAR(255) NOT NULL, "
                    "CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num))"
                )
            )
            connection.execute(text("ALTER TABLE alembic_version ALTER COLUMN version_num TYPE VARCHAR(255)"))

    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        render_as_batch=(dialect_name == "sqlite"),
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in 'online' mode with async engine.

    Creates an async Engine and associates a connection with the context.
    """
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_sync_migrations() -> None:
    """Run migrations in 'online' mode with sync engine (for SQLite)."""
    from sqlalchemy import create_engine

    url = config.get_main_option("sqlalchemy.url")
    connectable = create_engine(url, poolclass=pool.NullPool)

    with connectable.connect() as connection:
        do_run_migrations(connection)

    connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode (async wrapper)."""
    url = config.get_main_option("sqlalchemy.url") or ""
    if url.startswith("sqlite"):
        run_sync_migrations()
    else:
        asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
