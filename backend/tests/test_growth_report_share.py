"""Tests for #1217 child growth-report share token service and public endpoint.

Mirrors test_share_token.py's structure (service unit tests + API integration
tests), plus the data-minimality assertions specific to this minor-safe,
no-auth public endpoint.
"""

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
async def test_issue_growth_report_token_persists_hash_only_and_scopes_by_student(
    db_session: AsyncSession,
):
    service = ShareTokenService(db_session)

    plain_token, token_record = await service.issue_growth_report_token(
        student_id="student-123",
        teacher_id="teacher-user-id",
        expires_in_hours=24,
    )

    assert token_record.id is not None
    assert len(plain_token) >= 32
    assert token_record.token_hash != plain_token
    assert token_record.resource_type == "growth_report"
    assert token_record.lesson_id is None
    assert token_record.student_id == "student-123"
    assert token_record.access_count == 0


@pytest.mark.asyncio
async def test_resolve_growth_report_token_returns_token_when_valid(db_session: AsyncSession):
    service = ShareTokenService(db_session)
    plain_token, issued = await service.issue_growth_report_token(
        student_id="student-123",
        teacher_id="teacher-user-id",
    )

    resolved = await service.resolve_growth_report_token(plain_token)

    assert resolved is not None
    assert resolved.id == issued.id
    assert resolved.access_count == 1
    assert resolved.last_accessed_at is not None


@pytest.mark.asyncio
async def test_resolve_growth_report_token_returns_none_when_expired(db_session: AsyncSession):
    expired = ShareToken(
        token_hash=ShareTokenService.hash_token("expired-growth-token"),
        resource_type="growth_report",
        lesson_id=None,
        teacher_id="teacher-user-id",
        student_id="student-x",
        expires_at=datetime.now(UTC) - timedelta(days=1),
    )
    db_session.add(expired)
    await db_session.flush()

    service = ShareTokenService(db_session)
    resolved = await service.resolve_growth_report_token("expired-growth-token")

    assert resolved is None


@pytest.mark.asyncio
async def test_resolve_growth_report_token_does_not_match_lesson_summary_token(
    db_session: AsyncSession,
):
    """A lesson-summary token must never resolve as a growth-report token (resource_type gate)."""
    service = ShareTokenService(db_session)
    plain_token, _ = await service.issue_lesson_summary_token(
        lesson_id="lesson-1",
        teacher_id="teacher-user-id",
        student_id="student-1",
    )

    resolved = await service.resolve_growth_report_token(plain_token)

    assert resolved is None


def test_given_name_strips_korean_surname():
    assert ShareTokenService._given_name("박지선") == "지선"
    assert ShareTokenService._given_name("김하은") == "하은"


def test_given_name_keeps_western_first_name():
    assert ShareTokenService._given_name("John Smith") == "John"


# ---------------------------------------------------------------------------
# API endpoint integration tests
# ---------------------------------------------------------------------------


async def _make_student(
    db_session: AsyncSession,
    *,
    student_id: str = "student-gr-1",
    teacher_id: str = "test-user-id-prof",
    name: str = "김철길",
) -> Student:
    student = Student(
        id=student_id,
        teacher_id=teacher_id,
        name=name,
        instrument="violin",
        level=StudentLevel.beginner,
        phone="010-1234-5678",
        parent_phone="010-9999-8888",
        parent_name="김부모",
        email="student@example.com",
    )
    db_session.add(student)
    await db_session.flush()
    return student


async def _make_completed_lesson(
    db_session: AsyncSession,
    *,
    student: Student,
    lesson_date: date,
    lesson_id: str,
) -> Lesson:
    lesson = Lesson(
        id=lesson_id,
        student_id=student.id,
        teacher_id="test-user-id-prof",
        teacher_name="홍길동",
        student_name=student.name,
        instrument=student.instrument,
        date=lesson_date,
        start_time="14:00",
        duration=45,
        status=LessonStatus.completed,
        feedback="아주 상세한 비공개 레슨 노트 — 이 내용은 절대 공개 응답에 노출되면 안 됨",
    )
    db_session.add(lesson)
    await db_session.flush()
    return lesson


@pytest.mark.asyncio
async def test_create_growth_report_share_mints_token_for_owned_student(
    db_session: AsyncSession,
    client: AsyncClient,
    create_test_user,
    auth_headers: dict,
):
    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")
    student = await _make_student(db_session)
    await db_session.commit()

    response = await client.post(
        f"/api/v1/growth-reports/{student.id}/share",
        json={"expires_in_hours": 48},
        headers=auth_headers,
    )

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["token"]
    assert "/growth-report/" in body["url"]
    assert body["app_deep_link"].startswith("lessonapp://growth-report/")


@pytest.mark.asyncio
async def test_create_growth_report_share_forbidden_for_non_owner_teacher(
    db_session: AsyncSession,
    client: AsyncClient,
    create_test_user,
    auth_headers: dict,
):
    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")
    # Student owned by a different teacher.
    student = await _make_student(db_session, teacher_id="other-teacher-prof")
    await db_session.commit()

    response = await client.post(
        f"/api/v1/growth-reports/{student.id}/share",
        json={"expires_in_hours": 24},
        headers=auth_headers,
    )

    assert response.status_code == 403


@pytest.mark.asyncio
async def test_public_growth_report_returns_minimal_metrics_and_tracks_access(
    db_session: AsyncSession,
    client: AsyncClient,
):
    student = await _make_student(db_session)
    today = datetime.now(UTC).date()
    await _make_completed_lesson(db_session, student=student, lesson_date=today, lesson_id="lesson-gr-1")
    await _make_completed_lesson(
        db_session, student=student, lesson_date=today - timedelta(days=3), lesson_id="lesson-gr-2"
    )

    service = ShareTokenService(db_session)
    token, token_record = await service.issue_growth_report_token(
        student_id=student.id,
        teacher_id="test-user-id",
    )
    await db_session.commit()

    response = await client.get(f"/api/v1/public/growth-reports/{token}")

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["child"]["given_name"] == "철길"
    assert body["child"]["instrument"] == "violin"
    assert body["metrics"]["recent_lesson_count"] == 2
    assert isinstance(body["metrics"]["practice_streak_days"], int)
    assert isinstance(body["metrics"]["progress_summary"], str)

    refreshed = await db_session.get(ShareToken, token_record.id)
    assert refreshed is not None
    assert refreshed.access_count == 1
    assert refreshed.last_accessed_at is not None


@pytest.mark.asyncio
async def test_public_growth_report_returns_404_for_unknown_token(client: AsyncClient):
    response = await client.get("/api/v1/public/growth-reports/does-not-exist")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_public_growth_report_returns_404_for_expired_token(
    db_session: AsyncSession,
    client: AsyncClient,
):
    expired = ShareToken(
        token_hash=ShareTokenService.hash_token("expired-growth-report-token"),
        resource_type="growth_report",
        lesson_id=None,
        teacher_id="teacher-user-id",
        student_id="student-x",
        expires_at=datetime.now(UTC) - timedelta(hours=1),
    )
    db_session.add(expired)
    await db_session.commit()

    response = await client.get("/api/v1/public/growth-reports/expired-growth-report-token")

    # #1217 hard requirement: expired resolves to 404 (not 410), same as
    # unknown — this endpoint must never leak "a token existed here".
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_public_growth_report_response_excludes_pii_fields(
    db_session: AsyncSession,
    client: AsyncClient,
):
    """Data-minimality: contact/address/payment/full-name/notes must never appear."""
    student = await _make_student(db_session)
    await _make_completed_lesson(
        db_session,
        student=student,
        lesson_date=datetime.now(UTC).date(),
        lesson_id="lesson-gr-pii",
    )

    service = ShareTokenService(db_session)
    token, _ = await service.issue_growth_report_token(student_id=student.id, teacher_id="test-user-id")
    await db_session.commit()

    response = await client.get(f"/api/v1/public/growth-reports/{token}")

    assert response.status_code == 200, response.text
    raw_body = response.text

    # Contact/address/payment fields must not leak.
    for forbidden in (
        "010-1234-5678",
        "010-9999-8888",
        "김부모",
        "student@example.com",
    ):
        assert forbidden not in raw_body

    # Detailed lesson notes (teacher feedback) must not leak.
    assert "아주 상세한 비공개 레슨 노트" not in raw_body

    # Full legal name must not leak — only the given-name-stripped form.
    assert student.name not in raw_body

    body = response.json()
    allowed_top_level_keys = {"child", "metrics", "generated_at"}
    assert set(body.keys()) == allowed_top_level_keys
    assert set(body["child"].keys()) == {"given_name", "instrument"}
    assert set(body["metrics"].keys()) == {
        "practice_streak_days",
        "recent_lesson_count",
        "progress_summary",
    }
