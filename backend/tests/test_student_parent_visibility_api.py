"""Issue #637 — /students/{id}/parent-visibility CRUD regression.

spec parent_system.md §6.1.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _teacher_headers(user_id: str = "teacher-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _parent_headers(user_id: str = "parent-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_chain(db_session: AsyncSession) -> str:
    """teacher ↔ student ↔ parent 풀세팅 → student_id."""
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
    from app.models.student import Student
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, "teacher-user-id")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"),
            Student(id="student-001", teacher_id=teacher_id, name="학생", instrument="violin"),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id="student-001",
                status=ParentChildRelationStatus.active,
            ),
        ]
    )
    await db_session.flush()
    return "student-001"


async def _setup(create_test_user) -> None:
    await create_test_user(user_id="teacher-user-id", role="teacher", name="홍선생", email="t@test.com")
    await create_test_user(user_id="parent-user-id", role="parent", name="학부모", email="p@test.com")


@pytest.mark.asyncio
async def test_teacher_gets_default_visibility_settings(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """선생님이 GET → 기본 7 카테고리 값."""
    await _setup(create_test_user)
    student_id = await _seed_chain(db_session)
    await db_session.commit()

    response = await client.get(
        f"/api/v1/students/{student_id}/parent-visibility",
        headers=_teacher_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    # 7 카테고리 keys 모두 응답에 있음.
    expected_keys = {
        "can_view_schedule",
        "can_view_assignments",
        "can_view_practice",
        "can_view_lesson_notes",
        "can_view_recordings",
        "can_view_detailed_feedback",
        "can_view_chat",
    }
    assert expected_keys.issubset(set(body.keys()))
    # 기본값: schedule/assignments/practice/notes = True, 나머지 False.
    assert body["can_view_schedule"] is True
    assert body["can_view_recordings"] is False


@pytest.mark.asyncio
async def test_parent_can_view_own_child_visibility(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모가 자녀의 권한 조회 가능 — 200."""
    await _setup(create_test_user)
    student_id = await _seed_chain(db_session)
    await db_session.commit()

    response = await client.get(
        f"/api/v1/students/{student_id}/parent-visibility",
        headers=_parent_headers(),
    )

    assert response.status_code == 200, response.text
    assert response.json()["student_id"] == student_id


@pytest.mark.asyncio
async def test_teacher_patches_partial_categories(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """선생님이 PATCH 로 일부 카테고리만 갱신."""
    await _setup(create_test_user)
    student_id = await _seed_chain(db_session)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/students/{student_id}/parent-visibility",
        headers=_teacher_headers(),
        json={"can_view_recordings": True, "can_view_chat": True},
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["can_view_recordings"] is True
    assert body["can_view_chat"] is True
    # 미명시 카테고리는 default 유지.
    assert body["can_view_schedule"] is True
    assert body["can_view_lesson_notes"] is True


@pytest.mark.asyncio
async def test_parent_cannot_patch_visibility_403(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """학부모 PATCH 시도 → 403."""
    await _setup(create_test_user)
    student_id = await _seed_chain(db_session)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/students/{student_id}/parent-visibility",
        headers=_parent_headers(),
        json={"can_view_chat": True},
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_unknown_student_returns_404(
    client: AsyncClient,
    create_test_user,
):
    await _setup(create_test_user)

    response = await client.get(
        "/api/v1/students/00000000-0000-0000-0000-000000000000/parent-visibility",
        headers=_teacher_headers(),
    )

    assert response.status_code == 404, response.text
