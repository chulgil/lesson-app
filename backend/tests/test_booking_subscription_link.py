"""#580 Gap B/C — direct booking 수강권 연결 + 완료 시 차감.

SSOT: docs/specs/schedule/student_direct_booking_spec.md §6,
subscription_required_spec.md §1 (모든 레슨은 수강권 연결, 예외 없음).

Gap B: ``POST /bookings`` 가 ``subscription_id`` 를 받지 않으면
``ScheduleService._find_active_subscription_id`` 가 teacher-student 활성
수강권을 자동 연결한다(생성은 하지 않음).

Gap C: ``approve_booking(target_status="completed")`` 가
``SubscriptionService.deduct_for_completed_lesson`` 을 호출해 1회 차감한다
(재완료해도 중복 차감 없음 — idempotent).
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


def _headers(user_id: str, role: str = "student"):
    from app.core.security import create_access_token

    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


async def _seed_active_subscription(
    db_session: AsyncSession,
    teacher_user_id: str,
    student_id: str,
    *,
    total_lessons: int = 4,
    used_lessons: int = 0,
) -> tuple[str, str]:
    """Seed a LessonClass/ClassMembership/Subscription triple. Returns (teacher_id, subscription_id)."""
    from app.models.lesson import ClassMembership, LessonClass
    from app.models.subscription import Subscription
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    lc = LessonClass(teacher_id=teacher_id, name="Test")
    db_session.add(lc)
    await db_session.flush()
    membership = ClassMembership(
        lesson_class_id=lc.id,
        student_id=student_id,
        instrument="violin",
        lesson_duration=60,
    )
    db_session.add(membership)
    await db_session.flush()
    sub = Subscription(
        student_id=student_id,
        membership_id=membership.id,
        type="monthly",
        lessons_per_month=total_lessons,
        total_lessons=total_lessons,
        used_lessons=used_lessons,
        start_date=date(2126, 7, 1),
        end_date=date(2126, 7, 31),
        amount=200000,
    )
    db_session.add(sub)
    await db_session.flush()
    return teacher_id, sub.id


@pytest.mark.asyncio
async def test_create_booking_auto_attaches_active_subscription(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """subscription_id 를 안 보내도 활성 수강권이 있으면 자동 연결된다."""
    from app.models.schedule import LessonBooking

    await create_test_user(user_id="sub-link-teacher", role="teacher", email="t-sub-link@test.com")
    await create_test_user(user_id="sub-link-student", role="student", email="s-sub-link@test.com")
    teacher_id, sub_id = await _seed_active_subscription(db_session, "sub-link-teacher", "sub-link-student")
    await db_session.commit()

    response = await client.post(
        "/api/v1/bookings",
        headers=_headers("sub-link-student"),
        json={
            "teacher_id": teacher_id,
            "student_id": "sub-link-student",
            "student_name": "학생",
            "scheduled_date": "2126-07-06",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["subscription_id"] == sub_id

    db_session.expire_all()
    booking = await db_session.get(LessonBooking, body["id"])
    assert booking is not None
    assert booking.subscription_id == sub_id


@pytest.mark.asyncio
async def test_create_booking_stays_unlinked_when_no_active_subscription(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """활성 수강권이 없으면 subscription_id=None 유지 — 예약 자체는 성공."""
    await create_test_user(user_id="sub-none-teacher", role="teacher", email="t-sub-none@test.com")
    await create_test_user(user_id="sub-none-student", role="student", email="s-sub-none@test.com")
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, "sub-none-teacher")
    await db_session.commit()

    response = await client.post(
        "/api/v1/bookings",
        headers=_headers("sub-none-student"),
        json={
            "teacher_id": teacher_id,
            "student_id": "sub-none-student",
            "student_name": "학생",
            "scheduled_date": "2126-07-06",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert response.status_code == 201, response.text
    assert response.json()["subscription_id"] is None


@pytest.mark.asyncio
async def test_create_booking_exhausted_subscription_stays_unlinked(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """잔여 0인 활성 수강권은 후보에서 제외된다 (음수 잔여로 연결하지 않음)."""
    await create_test_user(user_id="sub-exh-teacher", role="teacher", email="t-sub-exh@test.com")
    await create_test_user(user_id="sub-exh-student", role="student", email="s-sub-exh@test.com")
    teacher_id, _sub_id = await _seed_active_subscription(
        db_session, "sub-exh-teacher", "sub-exh-student", total_lessons=4, used_lessons=4
    )
    await db_session.commit()

    response = await client.post(
        "/api/v1/bookings",
        headers=_headers("sub-exh-student"),
        json={
            "teacher_id": teacher_id,
            "student_id": "sub-exh-student",
            "student_name": "학생",
            "scheduled_date": "2126-07-06",
            "scheduled_time": "14:00",
            "duration": 60,
        },
    )
    assert response.status_code == 201, response.text
    assert response.json()["subscription_id"] is None


@pytest.mark.asyncio
async def test_create_booking_explicit_subscription_id_not_overridden(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """FE 가 subscription_id 를 명시하면 auto-attach 를 건드리지 않는다."""
    await create_test_user(user_id="sub-explicit-teacher", role="teacher", email="t-sub-explicit@test.com")
    await create_test_user(user_id="sub-explicit-student", role="student", email="s-sub-explicit@test.com")
    teacher_id, sub_id = await _seed_active_subscription(db_session, "sub-explicit-teacher", "sub-explicit-student")
    await db_session.commit()

    response = await client.post(
        "/api/v1/bookings",
        headers=_headers("sub-explicit-student"),
        json={
            "teacher_id": teacher_id,
            "student_id": "sub-explicit-student",
            "student_name": "학생",
            "scheduled_date": "2126-07-06",
            "scheduled_time": "14:00",
            "duration": 60,
            "subscription_id": sub_id,
        },
    )
    assert response.status_code == 201, response.text
    assert response.json()["subscription_id"] == sub_id


@pytest.mark.asyncio
async def test_approve_booking_completed_deducts_once(client: AsyncClient, create_test_user, db_session: AsyncSession):
    """approve_booking(status=completed) 가 1회 차감하고, 재완료해도 중복 차감하지 않는다."""
    from sqlalchemy import select

    from app.models.schedule import BookingStatus, LessonBooking
    from app.models.subscription import Subscription, SubscriptionUsage

    await create_test_user(user_id="dedupe-teacher", role="teacher", email="t-dedupe@test.com")
    await create_test_user(user_id="dedupe-student", role="student", email="s-dedupe@test.com")
    teacher_id, sub_id = await _seed_active_subscription(db_session, "dedupe-teacher", "dedupe-student")

    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id="dedupe-student",
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        subscription_id=sub_id,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    await db_session.commit()

    headers = _headers("dedupe-teacher", role="teacher")

    first = await client.patch(
        f"/api/v1/bookings/{booking.id}/approve",
        headers=headers,
        json={"status": "completed"},
    )
    assert first.status_code == 200, first.text

    # Re-completing (idempotent re-save) must not double-deduct. Back-to-back
    # requests on the shared test session — no interleaved db_session reads,
    # which would expire objects the second request's ORM session still holds.
    second = await client.patch(
        f"/api/v1/bookings/{booking.id}/approve",
        headers=headers,
        json={"status": "completed"},
    )
    assert second.status_code == 200, second.text

    db_session.expire_all()
    sub_row = await db_session.get(Subscription, sub_id)
    assert sub_row is not None
    assert sub_row.used_lessons == 1

    usage_rows = (
        await db_session.scalars(select(SubscriptionUsage).where(SubscriptionUsage.subscription_id == sub_id))
    ).all()
    assert len(usage_rows) == 1


@pytest.mark.asyncio
async def test_approve_booking_completed_without_subscription_skips_deduction(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """subscription_id 없는 booking 완료는 차감 로직을 건드리지 않는다 (trial/free booking)."""
    from app.models.schedule import BookingStatus, LessonBooking
    from app.services.subscription_service import resolve_teacher_id

    await create_test_user(user_id="nosub-teacher", role="teacher", email="t-nosub@test.com")
    await create_test_user(user_id="nosub-student", role="student", email="s-nosub@test.com")
    teacher_id = await resolve_teacher_id(db_session, "nosub-teacher")

    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id="nosub-student",
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        subscription_id=None,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/bookings/{booking.id}/approve",
        headers=_headers("nosub-teacher", role="teacher"),
        json={"status": "completed"},
    )
    assert response.status_code == 200, response.text


@pytest.mark.asyncio
async def test_cancel_after_complete_releases_deduction(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """완료 후 취소하면 차감된 세션을 되돌려준다 (release_lesson_usage)."""
    from app.models.schedule import BookingStatus, LessonBooking
    from app.models.subscription import Subscription

    await create_test_user(user_id="release-teacher", role="teacher", email="t-release@test.com")
    await create_test_user(user_id="release-student", role="student", email="s-release@test.com")
    teacher_id, sub_id = await _seed_active_subscription(db_session, "release-teacher", "release-student")

    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id="release-student",
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        subscription_id=sub_id,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    await db_session.commit()

    teacher_headers = _headers("release-teacher", role="teacher")
    complete = await client.patch(
        f"/api/v1/bookings/{booking.id}/approve",
        headers=teacher_headers,
        json={"status": "completed"},
    )
    assert complete.status_code == 200, complete.text

    # No test-side db_session reads between the two requests — see the
    # dedupe test above for why interleaving expires objects the second
    # request's ORM session still holds.
    cancel = await client.patch(
        f"/api/v1/bookings/{booking.id}/cancel",
        headers=teacher_headers,
        json={"reason": "실수로 완료 처리함"},
    )
    assert cancel.status_code == 200, cancel.text

    db_session.expire_all()
    sub_row = await db_session.get(Subscription, sub_id)
    assert sub_row is not None
    assert sub_row.used_lessons == 0
