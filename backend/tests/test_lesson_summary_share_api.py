"""Lesson summary share API tests."""

from __future__ import annotations

import hashlib
from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.lesson import Lesson, LessonStatus
from app.models.lesson_summary_share_token import LessonSummaryShareToken
from app.models.student import Student


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


async def _create_completed_lesson(db_session: AsyncSession) -> Lesson:
    student = Student(
        id="student-001",
        teacher_id="test-user-id-prof",
        name="김학생",
        instrument="피아노",
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
        session_number=3,
    )
    db_session.add_all([student, lesson])
    await db_session.flush()
    return lesson


@pytest.mark.asyncio
async def test_teacher_can_create_lesson_summary_share_token(
    client: AsyncClient,
    auth_headers: dict[str, str],
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")
    await _create_completed_lesson(db_session)

    response = await client.post(
        "/api/v1/lesson-summaries/lesson-001/share",
        headers=auth_headers,
        json={"expires_in_hours": 24},
    )

    assert response.status_code == 201
    data = response.json()
    assert data["token"]
    assert data["url"] == f"https://lessonaza.com/student/{data['token']}/summary"
    assert data["app_deep_link"] == f"lessonapp://student/summary/{data['token']}"
    assert "홍길동 선생님" in data["share_text"]
    assert "피아노 레슨" in data["share_text"]
    assert "바이엘" not in data["share_text"]
    assert "오른손 박자 안정화" in data["share_text"]

    token_row = await db_session.scalar(select(LessonSummaryShareToken))
    assert token_row is not None
    assert token_row.lesson_id == "lesson-001"
    assert token_row.teacher_id == "test-user-id"
    assert token_row.student_id == "student-001"
    assert token_row.token_hash == hashlib.sha256(data["token"].encode()).hexdigest()
    assert data["token"] != token_row.token_hash


@pytest.mark.asyncio
async def test_non_owner_teacher_cannot_create_lesson_summary_share_token(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")
    await create_test_user(user_id="other-teacher-id", role="teacher", name="다른선생님", email="other@test.com")
    await _create_completed_lesson(db_session)

    response = await client.post(
        "/api/v1/lesson-summaries/lesson-001/share",
        headers=_headers("other-teacher-id"),
        json={},
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_missing_lesson_summary_share_target_returns_404(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")

    response = await client.post(
        "/api/v1/lesson-summaries/missing/share",
        headers=auth_headers,
        json={},
    )

    assert response.status_code == 404
