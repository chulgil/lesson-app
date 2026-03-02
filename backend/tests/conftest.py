"""Shared test fixtures for the lesson-app backend test suite."""

import asyncio
from collections.abc import AsyncGenerator

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.security import create_access_token
from app.models.base import Base

# SQLite test database (in-memory would be ideal, but aiosqlite needs a file)
TEST_DATABASE_URL = "sqlite+aiosqlite:///./test.db"

test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@pytest.fixture(scope="session")
def event_loop():
    """Create a single event loop for the entire test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(autouse=True)
async def setup_db():
    """Create all tables before each test and drop them after."""
    # Import all models so Base.metadata is populated
    import app.models  # noqa: F401

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Yield a fresh database session for each test."""
    async with TestSessionLocal() as session:
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
