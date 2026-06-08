"""Shared test fixtures for the lesson-app backend test suite."""

import asyncio
import os
import tempfile
from collections.abc import AsyncGenerator
from datetime import UTC, datetime

# Plan C Phase 6a — must run before app.main import so APScheduler stays off.
os.environ.setdefault("TESTING", "1")

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.security import create_access_token
from app.models.base import Base

# SQLite test database (in-memory would be ideal, but aiosqlite needs a file)
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"


@pytest.fixture(scope="session")
def event_loop():
    """Create a single event loop for the entire test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(autouse=True)
async def setup_db(db_engine) -> AsyncGenerator[None, None]:
    """Create all tables before each test and drop them after."""
    # Import all models so Base.metadata is populated
    import app.models  # noqa: F401

    async with db_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with db_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def db_engine(request) -> AsyncGenerator:
    """Create a per-test isolated SQLite database engine.

    Opt-in FK enforcement via `@pytest.mark.sqlite_fk_on`:
    SQLite defaults to foreign_keys=OFF, which silently no-ops ON DELETE CASCADE.
    Production uses PostgreSQL where FKs are enforced by default; cascade tests
    must opt in to FK enforcement or they would silently pass.

    Default OFF (legacy) — many existing tests construct rows that violate FKs
    (e.g. students.teacher_id holding a user_id). Flipping ON globally would
    surface ~100 pre-existing data-construction bugs unrelated to this audit.
    Tracked separately; cascade tests use the explicit marker below.
    """
    fk_enabled = request.node.get_closest_marker("sqlite_fk_on") is not None
    with tempfile.TemporaryDirectory() as tmp_dir:
        test_db_path = f"{tmp_dir}/test.db"
        database_url = f"sqlite+aiosqlite:///{test_db_path}"
        engine = create_async_engine(database_url, echo=False)

        if fk_enabled:

            @event.listens_for(engine.sync_engine, "connect")
            def _enable_sqlite_fk(dbapi_connection, _connection_record):
                cursor = dbapi_connection.cursor()
                cursor.execute("PRAGMA foreign_keys=ON")
                cursor.close()

        try:
            yield engine
        finally:
            await engine.dispose()


@pytest.fixture
async def db_session(db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Yield a fresh database session for each test."""
    SessionLocal = async_sessionmaker(
        bind=db_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    async with SessionLocal() as session:
        yield session
        await session.rollback()


@pytest.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """HTTP test client with the DB dependency overridden."""
    from app.core.deps import get_db
    from app.main import app

    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture
async def create_test_user(db_session: AsyncSession):
    """Factory fixture that inserts a User into the test DB.

    Usage:
        user = await create_test_user()            # teacher with default id
        user = await create_test_user(
            user_id="custom-id", role="student", name="Student"
        )
    """
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    async def _create(
        user_id: str = "test-user-id",
        role: str = "teacher",
        name: str = "Test Teacher",
        email: str = "teacher@test.com",
    ) -> User:
        role_enum = UserRole(role) if role else None
        user = User(
            id=user_id,
            email=email,
            name=name,
            role=role_enum,
            locale="ko",
            country="KR",
            timezone="Asia/Seoul",
            currency="KRW",
        )
        db_session.add(user)
        await db_session.flush()

        if role == "teacher":
            # #430: Default fixture teachers are phone-verified to preserve
            # existing scenario tests. Tests that need to assert the E3 gate
            # behaviour must explicitly flip ``is_phone_verified`` to False.
            teacher = Teacher(
                id=f"{user_id}-prof",
                user_id=user_id,
                instruments=[],
                is_phone_verified=True,
                phone_verified_at=datetime.now(UTC),
            )
            db_session.add(teacher)
            await db_session.flush()

        return user

    return _create


@pytest.fixture
def auth_headers() -> dict[str, str]:
    """Authorization headers for a teacher (test-user-id)."""
    token = create_access_token(data={"sub": "test-user-id", "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def student_auth_headers() -> dict[str, str]:
    """Authorization headers for a student (test-student-id)."""
    token = create_access_token(data={"sub": "test-student-id", "role": "student"})
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Scenario helper fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
async def teacher(
    client: AsyncClient, auth_headers: dict, create_test_user, db_session: "AsyncSession"
) -> "TeacherActions":
    """Pre-seeded teacher with scenario helper methods.

    Usage:
        async def test_my_scenario(teacher):
            sid = await teacher.create_student("김학생")
            lid = await teacher.create_lesson(sid)
    """
    from tests.scenarios.helpers import TeacherActions

    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")
    return TeacherActions(client, auth_headers, db_session=db_session, user_id="test-user-id")


@pytest.fixture
async def student(client: AsyncClient, student_auth_headers: dict, create_test_user) -> "StudentActions":
    """Pre-seeded student with scenario helper methods.

    Usage:
        async def test_student_flow(student):
            await student.book_trial("teacher-id")
    """
    from tests.scenarios.helpers import StudentActions

    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student@test.com",
    )
    return StudentActions(client, student_auth_headers)
