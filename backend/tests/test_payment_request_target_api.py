"""Issue #636 — Student.payment_request_target CRUD regression.

spec user_master.md §5.2.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


async def _seed_student(db_session: AsyncSession, teacher_user_id: str = "test-user-id") -> str:
    from app.models.student import Student
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, teacher_user_id)
    db_session.add(
        Student(
            id="student-001",
            teacher_id=teacher_id,
            name="학생",
            instrument="violin",
        )
    )
    await db_session.flush()
    return "student-001"


async def _link_parent(db_session: AsyncSession, student_id: str) -> None:
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id=student_id,
                status=ParentChildRelationStatus.active,
            ),
        ]
    )
    await db_session.flush()


@pytest.mark.asyncio
async def test_default_payment_request_target_is_student(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """신규 student default payment_request_target='student'."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _seed_student(db_session)
    await db_session.commit()

    response = await client.get(
        f"/api/v1/students/{student_id}",
        headers=auth_headers,
    )

    assert response.status_code == 200, response.text
    assert response.json()["payment_request_target"] == "student"


@pytest.mark.asyncio
async def test_patch_to_parent_succeeds_with_active_link(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """ParentChildRelation active 있으면 target='parent' 설정 가능."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="학부모",
        email="p@test.com",
    )
    student_id = await _seed_student(db_session)
    await _link_parent(db_session, student_id)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/students/{student_id}/payment-request-target",
        headers=auth_headers,
        json={"payment_request_target": "parent"},
    )

    assert response.status_code == 200, response.text
    assert response.json()["payment_request_target"] == "parent"


@pytest.mark.asyncio
async def test_patch_to_parent_without_link_returns_422(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모 미연결 학생을 target='parent' 로 설정 → 422."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _seed_student(db_session)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/students/{student_id}/payment-request-target",
        headers=auth_headers,
        json={"payment_request_target": "parent"},
    )

    assert response.status_code == 422, response.text


@pytest.mark.asyncio
async def test_patch_invalid_target_returns_422(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """enum 외 값 → 422."""
    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _seed_student(db_session)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/students/{student_id}/payment-request-target",
        headers=auth_headers,
        json={"payment_request_target": "invalid"},
    )

    assert response.status_code == 422, response.text


@pytest.mark.asyncio
async def test_patch_back_to_student(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """parent 설정 후 student 복귀 (학부모 연결 없어도 가능)."""
    from app.models.student import PaymentRequestTarget, Student

    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _seed_student(db_session)
    # 직접 parent 로 세팅 (테스트 단순화).
    student = await db_session.get(Student, student_id)
    student.payment_request_target = PaymentRequestTarget.parent
    await db_session.flush()
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/students/{student_id}/payment-request-target",
        headers=auth_headers,
        json={"payment_request_target": "student"},
    )

    assert response.status_code == 200, response.text
    assert response.json()["payment_request_target"] == "student"


@pytest.mark.asyncio
async def test_non_teacher_role_rejected(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모/학생 role → 403."""
    from app.core.security import create_access_token

    await create_test_user(user_id="test-user-id", role="teacher")
    student_id = await _seed_student(db_session)
    await db_session.commit()

    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }
    response = await client.patch(
        f"/api/v1/students/{student_id}/payment-request-target",
        headers=parent_headers,
        json={"payment_request_target": "student"},
    )

    assert response.status_code in (401, 403), response.text
