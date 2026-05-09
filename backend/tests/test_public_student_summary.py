"""Public student lesson summary API tests."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.lesson import Lesson, LessonStatus
from app.models.lesson_summary_share_token import LessonSummaryShareToken
from app.models.student import Student
from app.services.lesson_summary_share_service import LessonSummaryShareService


async def _create_summary_fixture(
    db_session: AsyncSession,
    *,
    raw_token: str = "public-token",
    expires_at: datetime | None = None,
    revoked_at: datetime | None = None,
) -> LessonSummaryShareToken:
    student = Student(
        id="student-001",
        teacher_id="test-user-id-prof",
        name="김학생",
        instrument="피아노",
        phone="010-9999-0000",
        email="student-private@example.com",
        notes="선생님 내부 메모",
    )
    lesson = Lesson(
        id="lesson-001",
        student_id="student-001",
        teacher_id="test-user-id-prof",
        student_name="김학생",
        teacher_name="홍길동",
        instrument="피아노",
        date=date(2026, 5, 10),
        start_time="15:00",
        duration=60,
        status=LessonStatus.completed,
        feedback="오늘은 오른손 박자 안정화에 집중했습니다.",
        practice_tips="메트로놈 70으로 10분씩 연습",
        student_note="앱 내부 학생 메모",
        session_number=3,
    )
    token = LessonSummaryShareToken(
        lesson_id="lesson-001",
        teacher_id="test-user-id",
        student_id="student-001",
        token_hash=LessonSummaryShareService.hash_token(raw_token),
        expires_at=expires_at or datetime.now(UTC) + timedelta(hours=24),
        revoked_at=revoked_at,
    )
    db_session.add_all([student, lesson, token])
    await db_session.flush()
    return token


@pytest.mark.asyncio
async def test_public_student_summary_returns_read_only_summary_and_updates_audit(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher = await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")
    teacher.phone = "010-1111-2222"
    teacher.email = "teacher-private@example.com"
    teacher.profile_image_url = "https://cdn.lessonaza.com/teacher.png"
    token = await _create_summary_fixture(db_session)

    response = await client.get("/api/v1/public/student-summaries/public-token")

    assert response.status_code == 200
    data = response.json()
    assert data["lesson"] == {
        "id": "lesson-001",
        "date": "2026-05-10",
        "start_time": "15:00",
        "duration_minutes": 60,
        "session_number": 3,
        "status": "completed",
    }
    assert data["teacher"] == {
        "name": "홍길동",
        "instrument": "피아노",
        "profile_image_url": "https://cdn.lessonaza.com/teacher.png",
    }
    assert data["student"] == {"name": "김학생"}
    assert data["summary"]["lesson_note"] == "오늘은 오른손 박자 안정화에 집중했습니다."
    assert data["summary"]["homework"] == "메트로놈 70으로 10분씩 연습"
    assert data["share"]["url"] == "https://lessonaza.com/student/public-token/summary"
    assert data["share"]["app_deep_link"] == "lessonapp://student/summary/public-token"

    serialized = response.text
    assert "010-1111-2222" not in serialized
    assert "010-9999-0000" not in serialized
    assert "teacher-private@example.com" not in serialized
    assert "student-private@example.com" not in serialized
    assert "내부 메모" not in serialized
    assert "payment" not in serialized.lower()

    await db_session.refresh(token)
    assert token.access_count == 1
    assert token.last_accessed_at is not None


@pytest.mark.asyncio
async def test_public_student_summary_unknown_token_returns_404(client: AsyncClient) -> None:
    response = await client.get("/api/v1/public/student-summaries/unknown-token")

    assert response.status_code == 404


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("expires_at", "revoked_at"),
    [
        (datetime.now(UTC) - timedelta(seconds=1), None),
        (datetime.now(UTC) + timedelta(hours=1), datetime.now(UTC)),
    ],
)
async def test_public_student_summary_unusable_token_returns_410(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    expires_at: datetime,
    revoked_at: datetime | None,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")
    await _create_summary_fixture(
        db_session,
        raw_token="blocked-token",
        expires_at=expires_at,
        revoked_at=revoked_at,
    )

    response = await client.get("/api/v1/public/student-summaries/blocked-token")

    assert response.status_code == 410
