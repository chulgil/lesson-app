"""Issue #638 — 만 14세 자녀 학생 계정 전환 endpoint regression.

spec parent_system.md §2.3.4.
"""

from __future__ import annotations

from datetime import date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _parent_headers(user_id: str = "parent-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_parent_and_child(
    db_session: AsyncSession,
    *,
    child_birth_date: date,
    child_id: str = "child-001",
) -> None:
    from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus
    from app.models.student import Student

    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"),
            Student(
                id=child_id,
                teacher_id=None,
                name="자녀",
                instrument="violin",
                birth_date=child_birth_date,
            ),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id=child_id,
                status=ParentChildRelationStatus.active,
            ),
        ]
    )
    await db_session.flush()


async def _setup(create_test_user) -> None:
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="학부모",
        email="parent@test.com",
    )


@pytest.mark.asyncio
async def test_convert_creates_student_user_and_links(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """만 14세 이상 자녀 → user 생성 + student.user_id 링크 + relation 유지."""
    from sqlalchemy import select

    from app.models.parent import ParentChildRelation
    from app.models.student import Student
    from app.models.user import User, UserRole

    await _setup(create_test_user)
    # 만 14세 (오늘 - 14년 - 1일).
    today = date.today()
    birth = date(today.year - 15, today.month, today.day)  # 만 15세 확실.
    await _seed_parent_and_child(db_session, child_birth_date=birth)
    await db_session.commit()

    response = await client.post(
        "/api/v1/parents/child-profiles/child-001/convert-to-account",
        headers=_parent_headers(),
        json={"email": "newstudent@test.com"},
    )

    assert response.status_code == 200, response.text
    db_session.expire_all()
    student = await db_session.get(Student, "child-001")
    assert student.user_id is not None
    new_user = await db_session.get(User, student.user_id)
    assert new_user is not None
    assert new_user.role == UserRole.student
    assert new_user.email == "newstudent@test.com"
    assert new_user.name == "자녀"
    # 관계 유지 — 학부모 대시보드 계속 모니터링.
    rel = await db_session.scalar(select(ParentChildRelation).where(ParentChildRelation.student_id == "child-001"))
    assert rel is not None


@pytest.mark.asyncio
async def test_under_14_rejected_with_422(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """만 14세 미만 → 422."""
    await _setup(create_test_user)
    today = date.today()
    birth = date(today.year - 10, today.month, today.day)
    await _seed_parent_and_child(db_session, child_birth_date=birth)
    await db_session.commit()

    response = await client.post(
        "/api/v1/parents/child-profiles/child-001/convert-to-account",
        headers=_parent_headers(),
        json={"email": "ten@test.com"},
    )

    assert response.status_code == 422, response.text


@pytest.mark.asyncio
async def test_already_converted_rejected_with_409(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """student.user_id 가 이미 있으면 409."""
    from app.models.student import Student

    await _setup(create_test_user)
    today = date.today()
    birth = date(today.year - 15, today.month, today.day)
    await _seed_parent_and_child(db_session, child_birth_date=birth)
    student = await db_session.get(Student, "child-001")
    student.user_id = "some-existing-user"
    await db_session.flush()
    await db_session.commit()

    response = await client.post(
        "/api/v1/parents/child-profiles/child-001/convert-to-account",
        headers=_parent_headers(),
        json={"email": "x@test.com"},
    )

    assert response.status_code == 409, response.text


@pytest.mark.asyncio
async def test_duplicate_email_rejected_with_409(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """이미 등록된 email → 409."""
    await _setup(create_test_user)
    await create_test_user(
        user_id="existing-user-id",
        role="student",
        name="기존",
        email="dup@test.com",
    )
    today = date.today()
    birth = date(today.year - 15, today.month, today.day)
    await _seed_parent_and_child(db_session, child_birth_date=birth)
    await db_session.commit()

    response = await client.post(
        "/api/v1/parents/child-profiles/child-001/convert-to-account",
        headers=_parent_headers(),
        json={"email": "dup@test.com"},
    )

    assert response.status_code == 409, response.text


@pytest.mark.asyncio
async def test_non_parent_role_rejected(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """선생님/학생 role → 403."""
    from app.core.security import create_access_token

    await _setup(create_test_user)
    await create_test_user(
        user_id="some-teacher",
        role="teacher",
        name="선생님",
        email="t@test.com",
    )
    today = date.today()
    birth = date(today.year - 15, today.month, today.day)
    await _seed_parent_and_child(db_session, child_birth_date=birth)
    await db_session.commit()

    teacher_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'some-teacher', 'role': 'teacher'})}"
    }
    response = await client.post(
        "/api/v1/parents/child-profiles/child-001/convert-to-account",
        headers=teacher_headers,
        json={"email": "x@test.com"},
    )

    assert response.status_code == 403, response.text
