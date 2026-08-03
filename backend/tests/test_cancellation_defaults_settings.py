"""#1178 — teacher cancellation defaults BE persistence.

The four policy fields (+ deadline hours) that were FE-local-only (#1167 spec
§4 limitation) gain a server row so a non-academy teacher's compensation
toggle/message actually drives the late-cancel notifications.

Key semantics: ``cancellation_defaults.teacher_id`` stores **teachers.id**
(NOT user id — unlike sibling settings tables) so lesson_service can resolve
straight from ``Lesson.teacher_id``.
"""

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

_DEFAULT_COMPENSATION_MESSAGE = "지각 취소로 다음 레슨에 보너스 연습시간을 제공해 드립니다."

# Exact keys the FE entity's generated fromJson reads
# (frontend/lib/features/profile/domain/entities/cancellation_defaults.g.dart).
_FE_WIRE_KEYS = {
    "id",
    "cancellation_deadline_hours",
    "student_compensation_extra_minutes_enabled",
    "include_extra_minutes_text_on_late_cancel",
    "student_compensation_extra_minutes_message",
    "notify_owner_on_late_cancel",
    "created_at",
    "updated_at",
}


# ---------------------------------------------------------------------------
# API — GET/PUT /settings/cancellation
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_cancellation_defaults_auto_creates_with_fe_wire_shape(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """GET auto-creates a defaults row and the payload carries the FE contract keys."""
    from app.models.teacher import Teacher

    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/settings/cancellation", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()

    assert _FE_WIRE_KEYS.issubset(data.keys()), f"missing FE contract keys: {_FE_WIRE_KEYS - data.keys()}"
    assert data["cancellation_deadline_hours"] == 12
    assert data["student_compensation_extra_minutes_enabled"] is True
    assert data["include_extra_minutes_text_on_late_cancel"] is True
    assert data["student_compensation_extra_minutes_message"] is None
    assert data["notify_owner_on_late_cancel"] is False
    # FE CancellationDefaults.fromJson requires a non-null created_at string.
    assert isinstance(data["created_at"], str)

    # Row is keyed by teachers.id, not the user id.
    from app.models.settings import CancellationDefaults

    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    row = await db_session.scalar(select(CancellationDefaults).where(CancellationDefaults.teacher_id == teacher.id))
    assert row is not None, "GET must persist the auto-created row keyed by teachers.id"


@pytest.mark.asyncio
async def test_put_cancellation_defaults_persists_across_requests(client: AsyncClient, auth_headers, create_test_user):
    """PUT updates provided fields; a subsequent GET returns the stored values."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.put(
        "/api/v1/settings/cancellation",
        headers=auth_headers,
        json={
            "student_compensation_extra_minutes_enabled": False,
            "student_compensation_extra_minutes_message": "다음 레슨 10분 연장해 드립니다.",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["student_compensation_extra_minutes_enabled"] is False
    assert data["student_compensation_extra_minutes_message"] == "다음 레슨 10분 연장해 드립니다."
    # Untouched fields keep their defaults.
    assert data["include_extra_minutes_text_on_late_cancel"] is True
    assert data["cancellation_deadline_hours"] == 12

    again = await client.get("/api/v1/settings/cancellation", headers=auth_headers)
    assert again.status_code == 200
    assert again.json()["student_compensation_extra_minutes_enabled"] is False
    assert again.json()["student_compensation_extra_minutes_message"] == "다음 레슨 10분 연장해 드립니다."


@pytest.mark.asyncio
async def test_put_can_clear_custom_message_with_null(client: AsyncClient, auth_headers, create_test_user):
    """Explicit null clears the custom message (falls back to the default text)."""
    await create_test_user(user_id="test-user-id", role="teacher")

    await client.put(
        "/api/v1/settings/cancellation",
        headers=auth_headers,
        json={"student_compensation_extra_minutes_message": "커스텀"},
    )
    response = await client.put(
        "/api/v1/settings/cancellation",
        headers=auth_headers,
        json={"student_compensation_extra_minutes_message": None},
    )
    assert response.status_code == 200
    assert response.json()["student_compensation_extra_minutes_message"] is None


@pytest.mark.asyncio
async def test_cancellation_defaults_requires_teacher_role(client: AsyncClient, student_auth_headers, create_test_user):
    await create_test_user(user_id="test-student-id", role="student", email="cd-student@test.com")

    response = await client.get("/api/v1/settings/cancellation", headers=student_auth_headers)
    assert response.status_code == 403


# ---------------------------------------------------------------------------
# Resolution — lesson_service uses the persisted row for non-academy lessons
# ---------------------------------------------------------------------------


async def _make_teacher_student_lesson(db_session, create_test_user, *, suffix):
    from app.models.lesson import Lesson
    from app.models.student import Student
    from app.models.teacher import Teacher

    teacher_user = await create_test_user(user_id=f"t-cd-{suffix}", role="teacher", name=f"Teacher {suffix}")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == f"t-cd-{suffix}"))

    student_user = await create_test_user(
        user_id=f"s-cd-{suffix}", role="student", name=f"Student {suffix}", email=f"s-cd-{suffix}@test.com"
    )
    student = Student(
        id=f"student-cd-{suffix}",
        teacher_id=teacher.id,
        user_id=student_user.id,
        name=f"Student {suffix}",
    )
    db_session.add(student)
    await db_session.flush()

    lesson = Lesson(
        id=f"lesson-cd-{suffix}",
        teacher_id=teacher.id,
        student_id=student.id,
        student_name=f"Student {suffix}",
        instrument="violin",
        date=date(2026, 7, 10),
        start_time="14:00",
        duration=60,
    )
    db_session.add(lesson)
    await db_session.flush()
    return teacher_user, teacher, student_user, lesson


async def _persist_defaults(db_session, teacher_id, **overrides):
    from app.models.settings import CancellationDefaults

    row = CancellationDefaults(teacher_id=teacher_id, **overrides)
    db_session.add(row)
    await db_session.flush()
    return row


async def _notifs(db_session, user_id, notif_type):
    from app.models.notification import Notification

    return (
        await db_session.scalars(
            select(Notification).where(
                Notification.user_id == user_id,
                Notification.type == notif_type,
            )
        )
    ).all()


@pytest.mark.asyncio
async def test_persisted_toggle_off_suppresses_compensation(db_session: AsyncSession, create_test_user):
    """The #1167 spec §4 limitation: toggle off must now suppress the notification."""
    from app.services.lesson_service import LessonService

    teacher_user, teacher, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="off"
    )
    await _persist_defaults(db_session, teacher.id, student_compensation_extra_minutes_enabled=False)

    await LessonService(db_session).update_status(lesson.id, "cancelledByStudentLate", teacher_user)

    assert await _notifs(db_session, student_user.id, "compensationApplied") == []
    # The plain cancellation notice still goes out, without the compensation echo.
    cancelled = await _notifs(db_session, student_user.id, "lessonCancelled")
    assert len(cancelled) == 1
    assert _DEFAULT_COMPENSATION_MESSAGE not in cancelled[0].body


@pytest.mark.asyncio
async def test_persisted_custom_message_is_used(db_session: AsyncSession, create_test_user):
    from app.services.lesson_service import LessonService

    teacher_user, teacher, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="msg"
    )
    await _persist_defaults(
        db_session,
        teacher.id,
        student_compensation_extra_minutes_message="다음 레슨 15분 보너스!",
    )

    await LessonService(db_session).update_status(lesson.id, "cancelledByStudentLate", teacher_user)

    comp = await _notifs(db_session, student_user.id, "compensationApplied")
    assert len(comp) == 1
    assert comp[0].body == "다음 레슨 15분 보너스!"
    # include_text default True → cancellation notice echoes the same message.
    cancelled = await _notifs(db_session, student_user.id, "lessonCancelled")
    assert "다음 레슨 15분 보너스!" in cancelled[0].body


@pytest.mark.asyncio
async def test_persisted_include_text_off_skips_echo_but_still_compensates(db_session: AsyncSession, create_test_user):
    from app.services.lesson_service import LessonService

    teacher_user, teacher, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="noecho"
    )
    await _persist_defaults(db_session, teacher.id, include_extra_minutes_text_on_late_cancel=False)

    await LessonService(db_session).update_status(lesson.id, "cancelledByStudentLate", teacher_user)

    comp = await _notifs(db_session, student_user.id, "compensationApplied")
    assert len(comp) == 1, "compensation itself stays enabled"
    cancelled = await _notifs(db_session, student_user.id, "lessonCancelled")
    assert _DEFAULT_COMPENSATION_MESSAGE not in cancelled[0].body


@pytest.mark.asyncio
async def test_no_persisted_row_keeps_default_on_behavior(db_session: AsyncSession, create_test_user):
    """Teachers who never opened the settings screen keep the enabled default."""
    from app.services.lesson_service import LessonService

    teacher_user, _, student_user, lesson = await _make_teacher_student_lesson(
        db_session, create_test_user, suffix="norow"
    )

    await LessonService(db_session).update_status(lesson.id, "cancelledByStudentLate", teacher_user)

    comp = await _notifs(db_session, student_user.id, "compensationApplied")
    assert len(comp) == 1
    assert comp[0].body == _DEFAULT_COMPENSATION_MESSAGE
