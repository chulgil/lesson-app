"""Tests for share token service and public lesson summary endpoints."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import Lesson, LessonStatus
from app.models.share_token import ShareToken
from app.models.student import Student, StudentLevel
from app.services.share_token_service import ShareTokenService

# ---------------------------------------------------------------------------
# Service-level (unit) tests
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_issue_token_persists_hash_only_and_returns_plain_token(db_session: AsyncSession):
    service = ShareTokenService(db_session)

    plain_token, token_record = await service.issue_lesson_summary_token(
        lesson_id="lesson-123",
        teacher_id="teacher-user-id",
        student_id="student-123",
        expires_in_hours=24,
    )

    assert token_record.id is not None
    assert len(plain_token) >= 32
    assert token_record.token_hash != plain_token
    assert token_record.lesson_id == "lesson-123"
    assert token_record.teacher_id == "teacher-user-id"
    assert token_record.student_id == "student-123"
    assert token_record.access_count == 0
    assert token_record.last_accessed_at is None
    # SQLite under test stores naive datetimes; normalize before comparing.
    expires = token_record.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=UTC)
    assert expires > datetime.now(UTC)


@pytest.mark.asyncio
async def test_resolve_token_returns_token_when_valid(db_session: AsyncSession):
    service = ShareTokenService(db_session)
    plain_token, issued = await service.issue_lesson_summary_token(
        lesson_id="lesson-123",
        teacher_id="teacher-user-id",
        student_id="student-123",
    )

    resolved = await service.resolve_lesson_summary_token(plain_token)

    assert resolved is not None
    assert resolved.id == issued.id
    assert resolved.access_count == 1
    assert resolved.last_accessed_at is not None


@pytest.mark.asyncio
async def test_resolve_token_returns_none_when_expired(db_session: AsyncSession):
    expired = ShareToken(
        token_hash=ShareTokenService.hash_token("expired-token"),
        lesson_id="lesson-x",
        teacher_id="teacher-user-id",
        student_id="student-x",
        expires_at=datetime.now(UTC) - timedelta(days=1),
    )
    db_session.add(expired)
    await db_session.flush()

    service = ShareTokenService(db_session)
    resolved = await service.resolve_lesson_summary_token("expired-token")

    assert resolved is None


@pytest.mark.asyncio
async def test_resolve_token_returns_none_when_not_found(db_session: AsyncSession):
    service = ShareTokenService(db_session)
    resolved = await service.resolve_lesson_summary_token("non-existent")
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
        id="lesson-int-1",
        student_id=student.id,
        teacher_id="test-user-id-prof",
        teacher_name="홍길동",
        student_name=student.name,
        instrument=student.instrument,
        date=lesson_date,
        start_time="14:00",
        duration=45,
        status=status,
        feedback=feedback,
        session_number=3,
    )
    db_session.add(lesson)
    await db_session.flush()
    return lesson


@pytest.mark.asyncio
@pytest.mark.asyncio
async def test_public_student_summary_returns_lesson_summary_and_tracks_access(
    db_session: AsyncSession,
    client: AsyncClient,
):
    student = await _make_student(db_session, name="김철길")
    lesson = await _make_lesson(db_session, student=student, lesson_date=date(2026, 5, 8))

    service = ShareTokenService(db_session)
    token, token_record = await service.issue_lesson_summary_token(
        lesson_id=lesson.id,
        teacher_id="test-user-id",
        student_id=student.id,
    )
    await db_session.commit()

    response = await client.get(f"/api/v1/public/student-summaries/{token}")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["lesson"]["id"] == lesson.id
    assert body["lesson"]["date"] == "2026-05-08"
    assert body["lesson"]["start_time"] == "14:00"
    assert body["lesson"]["duration_minutes"] == 45
    assert body["lesson"]["session_number"] == 3
    assert body["teacher"]["name"] == "홍길동"
    assert body["student"]["name"] == "김철길"
    assert body["summary"]["feedback"] == "great progress today"

    refreshed = await db_session.get(ShareToken, token_record.id)
    assert refreshed is not None
    assert refreshed.access_count == 1
    assert refreshed.last_accessed_at is not None


@pytest.mark.asyncio
async def test_student_summary_returns_404_for_unknown_token(client: AsyncClient):
    response = await client.get("/api/v1/public/student-summaries/does-not-exist")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_student_summary_returns_410_for_expired_token(
    db_session: AsyncSession,
    client: AsyncClient,
):
    expired = ShareToken(
        token_hash=ShareTokenService.hash_token("expired-summary-token"),
        lesson_id="lesson-x",
        teacher_id="teacher-user-id",
        student_id="student-x",
        expires_at=datetime.now(UTC) - timedelta(hours=1),
    )
    db_session.add(expired)
    await db_session.commit()

    response = await client.get("/api/v1/public/student-summaries/expired-summary-token")
    assert response.status_code == 410
