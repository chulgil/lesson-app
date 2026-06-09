"""Phase 29 — 학부모 가입→자녀 연결→조회 E2E FE contract 정합성 regression.

학부모가 자녀의 booking 목록/상세를 정상 조회할 수 있는지 확인.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _parent_headers(user_id: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_child_with_booking(
    db_session: AsyncSession,
    *,
    parent_user_id: str,
    teacher_user_id: str,
    child_student_id: str,
) -> str:
    """학부모 ↔ 자녀(Student) ↔ 선생님 booking 의 스키마 link 풀세팅."""
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
    from app.models.schedule import BookingStatus, LessonBooking
    from app.models.student import Student
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id=parent_user_id, name="학부모"),
            Student(id=child_student_id, teacher_id=teacher_id, name="자녀", instrument="violin"),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id=child_student_id,
                status=ParentChildRelationStatus.active,
            ),
        ]
    )
    await db_session.flush()
    booking = LessonBooking(
        teacher_id=teacher_id,
        student_id=child_student_id,
        scheduled_date=date(2126, 7, 6),
        scheduled_time="14:00",
        duration=60,
        status=BookingStatus.confirmed,
    )
    db_session.add(booking)
    await db_session.flush()
    return booking.id


async def _setup_users(create_test_user) -> None:
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="학부모",
        email="parent@test.com",
    )
    await create_test_user(
        user_id="teacher-user-id",
        role="teacher",
        name="홍선생",
        email="t@test.com",
    )


@pytest.mark.asyncio
async def test_parent_can_get_child_booking_detail(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모가 자녀 booking 상세를 조회 — 200, 403 아님."""
    await _setup_users(create_test_user)
    booking_id = await _seed_child_with_booking(
        db_session,
        parent_user_id="parent-user-id",
        teacher_user_id="teacher-user-id",
        child_student_id="child-001",
    )
    await db_session.commit()

    response = await client.get(
        f"/api/v1/bookings/{booking_id}",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 200, response.text
    assert response.json()["id"] == booking_id


@pytest.mark.asyncio
async def test_parent_booking_list_with_child_student_id_returns_children_only(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모가 student_id=자녀 로 booking list 조회 → 자녀 booking 만 반환."""
    await _setup_users(create_test_user)
    booking_id = await _seed_child_with_booking(
        db_session,
        parent_user_id="parent-user-id",
        teacher_user_id="teacher-user-id",
        child_student_id="child-001",
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/bookings?student_id=child-001",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    items = body.get("items") if isinstance(body, dict) else body
    assert any(item["id"] == booking_id for item in items), f"expected child booking in: {items}"


@pytest.mark.asyncio
async def test_parent_cannot_read_unrelated_student_booking(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """IDOR guard 유지 — 자녀가 아닌 학생의 booking 은 403."""
    from app.models.schedule import BookingStatus, LessonBooking
    from app.models.student import Student
    from app.services.subscription_service import resolve_teacher_id

    await _setup_users(create_test_user)
    await _seed_child_with_booking(
        db_session,
        parent_user_id="parent-user-id",
        teacher_user_id="teacher-user-id",
        child_student_id="child-001",
    )
    # 무관 학생의 booking.
    teacher_id = await resolve_teacher_id(db_session, "teacher-user-id")
    db_session.add(Student(id="unrelated-student", teacher_id=teacher_id, name="무관", instrument="piano"))
    await db_session.flush()
    other = LessonBooking(
        teacher_id=teacher_id,
        student_id="unrelated-student",
        scheduled_date=date(2126, 8, 1),
        scheduled_time="14:00",
        duration=60,
        status=BookingStatus.confirmed,
    )
    db_session.add(other)
    await db_session.flush()
    other_id = other.id
    await db_session.commit()

    response = await client.get(
        f"/api/v1/bookings/{other_id}",
        headers=_parent_headers("parent-user-id"),
    )

    assert response.status_code == 403, response.text
