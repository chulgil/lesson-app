"""Gate: alembic upgrade head 가 실 Postgres 에서 깨끗이 적용되는지 검증.

SQLite + ``Base.metadata.create_all`` 테스트(conftest)는 마이그레이션을 실행하지
않으므로 enum double-create / 타입 이름충돌 / ``op.add_column`` enum 미생성 류를
못 잡는다. 이 테스트는 testcontainers Postgres 에 실제 ``alembic upgrade head`` 를
돌려 그 버그 클래스를 자동 차단한다. docker/Postgres 가 없으면 graceful skip.

배경: 2026-06-16 beta 배포가 academy/student 마이그레이션 버그로 실패. 근본 원인
= 마이그레이션이 CI/테스트에서 한 번도 실 Postgres 에 적용된 적이 없었음.
"""

from __future__ import annotations

from pathlib import Path

import pytest
from alembic.config import Config
from alembic.script import ScriptDirectory
from sqlalchemy import create_engine, text

from alembic import command

pytestmark = pytest.mark.migration

try:
    from testcontainers.postgres import PostgresContainer

    _HAS_TESTCONTAINERS = True
except Exception:  # pragma: no cover - 의존성/플랫폼 미지원
    _HAS_TESTCONTAINERS = False

_BACKEND_ROOT = Path(__file__).resolve().parent.parent


def _alembic_config() -> Config:
    return Config(str(_BACKEND_ROOT / "alembic.ini"))


def _single_head() -> str:
    script = ScriptDirectory.from_config(_alembic_config())
    heads = script.get_heads()
    assert len(heads) == 1, f"alembic 다중 head/단절: {heads}"
    return heads[0]


@pytest.fixture
def postgres_container():
    if not _HAS_TESTCONTAINERS:
        pytest.skip("testcontainers 미설치 — 마이그레이션 게이트 skip")
    try:
        container = PostgresContainer("postgres:16")
        container.start()
    except Exception as exc:  # docker 미가용 등
        pytest.skip(f"Postgres testcontainer 기동 불가 (docker 없음?): {exc}")
    try:
        yield container
    finally:
        container.stop()


def test_alembic_upgrade_head_applies_cleanly_on_postgres(postgres_container, monkeypatch) -> None:
    """clean Postgres 에 upgrade head 가 성공하고 단일 head 에 도달해야 한다."""
    sync_url = postgres_container.get_connection_url()  # postgresql+psycopg2://...
    async_url = sync_url.replace("+psycopg2", "+asyncpg")

    engine = create_engine(sync_url, future=True)
    try:
        # prod/beta 의 alembic_version 은 varchar(255). fresh alembic 기본은 varchar(32)
        # 라 33자 revision id 에서 환경 의존적 truncation 이 난다 (마이그레이션 로직과
        # 무관한 잡음). prod 현실에 맞춰 미리 생성한다.
        with engine.begin() as conn:
            conn.execute(
                text(
                    "CREATE TABLE alembic_version "
                    "(version_num VARCHAR(255) NOT NULL, "
                    "CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num))"
                )
            )

        cfg = _alembic_config()
        monkeypatch.setenv("ALEMBIC_DATABASE_URL", async_url)

        # 1) clean upgrade head — 마이그레이션 버그가 있으면 여기서 실패한다.
        command.upgrade(cfg, "head")

        head = _single_head()
        with engine.connect() as conn:
            current = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
        assert current == head, f"upgrade 후 head 미도달: current={current!r}, head={head!r}"

        # 2) 멱등성 — 재실행은 no-op, 에러 없음, 리비전 불변.
        command.upgrade(cfg, "head")
        with engine.connect() as conn:
            current_again = conn.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
        assert current_again == head
    finally:
        engine.dispose()
