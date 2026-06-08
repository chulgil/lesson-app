"""Test that User.quest_celebrated_at column exists and accepts nullable DateTime.

Refs: .harness/spec/2026-06-08-teacher-quest-system.md §8.2 (1회성 보장)
Refs: .harness/decomposition/2026-06-08-teacher-quest-system.md Job 0 Task 0.2
"""

from datetime import UTC, datetime

import pytest
from sqlalchemy import inspect

from app.models.user import User, UserRole


def test_quest_celebrated_at_column_exists():
    """quest_celebrated_at 컬럼이 User 모델에 정의되어 있어야 함."""
    mapper = inspect(User)
    columns = {c.key for c in mapper.columns}
    assert "quest_celebrated_at" in columns


def test_quest_celebrated_at_is_nullable():
    """quest_celebrated_at 은 nullable 이어야 함."""
    mapper = inspect(User)
    col = mapper.columns["quest_celebrated_at"]
    assert col.nullable is True


@pytest.mark.asyncio
async def test_quest_celebrated_at_accepts_datetime(db_session):
    """quest_celebrated_at 에 timezone-aware DateTime 저장 가능."""
    now = datetime.now(UTC)
    user = User(
        id="user-quest-celebrated-test",
        email="test_quest@example.com",
        name="Quest Tester",
        role=UserRole.teacher,
        quest_celebrated_at=now,
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    assert user.quest_celebrated_at is not None


@pytest.mark.asyncio
async def test_quest_celebrated_at_defaults_to_null(db_session):
    """quest_celebrated_at 미지정 시 None — 가입 직후 기본 상태."""
    user = User(
        id="user-quest-default-test",
        email="test_default@example.com",
        name="Default Tester",
        role=UserRole.teacher,
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    assert user.quest_celebrated_at is None
