"""Tests for share token service and student summary endpoint."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import Lesson, LessonStatus
from app.models.share_token import ShareToken, ShareTokenScope
from app.models.student import Student, StudentLevel
from app.services.share_token_service import ShareTokenService

# ---------------------------------------------------------------------------
# Service-level (unit) tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_issue_token_persists_and_returns_valid_record(db_session: AsyncSession):
    service = ShareTokenService(db_session)

    token = await service.issue_token(
        scope=ShareTokenScope.student_summary,
        target_id="student-123",
        ttl_days=7,
        created_by_user_id=None,
    )

    assert token.id is not None
    assert len(token.token) >= 32
    assert token.scope == ShareTokenScope.student_summary
    assert token.target_id == "student-123"
    # SQLite under test stores naive datetimes; normalize before comparing.
    expires = token.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=UTC)
    assert expires > datetime.now(UTC)


@pytest.mark.asyncio
async def test_resolve_token_returns_token_when_valid(db_session: AsyncSession):
    service = ShareTokenService(db_session)
    issued = await service.issue_token(
        scope=ShareTokenScope.student_summary,
        target_id="student-123",
    )

    resolved = await service.resolve_token(issued.token)

    assert resolved is not None
    assert resolved.id == issued.id


@pytest.mark.asyncio
async def test_resolve_token_returns_none_when_expired(db_session: AsyncSession):
    expired = ShareToken(
        token="expired-token",
        scope=ShareTokenScope.student_summary,
        target_id="student-x",
        expires_at=datetime.now(UTC) - timedelta(days=1),
    )
    db_session.add(expired)
    await db_session.flush()

    service = ShareTokenService(db_session)
    resolved = await service.resolve_token("expired-token")

    assert resolved is None


@pytest.mark.asyncio
async def test_resolve_token_returns_none_when_not_found(db_session: AsyncSession):
    service = ShareTokenService(db_session)
    resolved = await service.resolve_token("non-existent")
    assert resolved is None


# ---------------------------------------------------------------------------
# API endpoint integration tests
# ---------------------------------------------------------------------------


async def _make_student(
    db_session: AsyncSession,
    *,
    student_id: str = "student-int-1",
    name: str = "김철길",
) -> Student:
    student = Student(
        id=student_id,
        teacher_id="teacher-1",
        name=name,
        instrument="violin",
        level=StudentLevel.beginner,
    )
    db_session.add(student)
    await db_session.flush()
    return student


async def _make_lesson(
    db_session: AsyncSession,
    *,
    student: Student,
    lesson_date: date,
    status: LessonStatus = LessonStatus.completed,
    feedback: str | None = "great progress today",
) -> Lesson:
    lesson = Lesson(
        student_id=student.id,
        student_name=student.name,
        instrument=student.instrument,
        date=lesson_date,
        start_time="14:00",
        duration=45,
        status=status,
        feedback=feedback,
    )
    db_session.add(lesson)
    await db_session.flush()
    return lesson


@pytest.mark.asyncio
async def test_student_summary_returns_masked_name_and_lessons(
    db_session: AsyncSession,
    client: AsyncClient,
):
    student = await _make_student(db_session, name="김철길")
    await _make_lesson(db_session, student=student, lesson_date=date(2026, 5, 1))
    await _make_lesson(db_session, student=student, lesson_date=date(2026, 5, 8))

    service = ShareTokenService(db_session)
    token = await service.issue_token(
        scope=ShareTokenScope.student_summary,
        target_id=student.id,
    )
    await db_session.commit()

    response = await client.get(f"/api/v1/student/{token.token}/summary")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["student_name"] == "김*길"
    assert body["instrument"] == "violin"
    assert body["level"] == "beginner"
    assert body["lesson_count_total"] == 2
    assert len(body["recent_lessons"]) == 2
    assert body["recent_lessons"][0]["date"] == "2026-05-08"
    assert body["recent_lessons"][0]["duration_minutes"] == 45
    assert body["recent_lessons"][0]["notes_excerpt"] == "great progress today"


@pytest.mark.asyncio
async def test_student_summary_returns_404_for_unknown_token(client: AsyncClient):
    response = await client.get("/api/v1/student/does-not-exist/summary")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_student_summary_returns_410_for_expired_token(
    db_session: AsyncSession,
    client: AsyncClient,
):
    expired = ShareToken(
        token="expired-summary-token",
        scope=ShareTokenScope.student_summary,
        target_id="student-x",
        expires_at=datetime.now(UTC) - timedelta(hours=1),
    )
    db_session.add(expired)
    await db_session.commit()

    response = await client.get("/api/v1/student/expired-summary-token/summary")
    assert response.status_code == 410
