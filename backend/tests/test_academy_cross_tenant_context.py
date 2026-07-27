"""Regression test: a user who is a teacher-member at Academy B must not see
Academy B's full student roster just because their JWT's cached
``active_context`` (set while last using a DIFFERENT academy, e.g. as owner
of Academy A) isn't literally the string "teacher".

Bug: list_students()/get_student() derived teacher-mode isolation purely from
the JWT's active_context claim, discarding the JWT's own embedded academy_id
and never re-deriving the caller's actual role at the *requested* academy_id.
A user who owns Academy A and is separately a teacher at Academy B could hit
GET /academies/{B}/students with a JWT still carrying
active_context=academy_owner (from switching into Academy A) and see every
student in Academy B instead of only their own matched students.

Fix: derive teacher-mode isolation from a fresh per-academy role lookup
(AcademyService.get_teacher_member_id_for_user) instead of trusting the
cached context string.
"""

from __future__ import annotations

from datetime import UTC, datetime
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import Academy, AcademyMember, AcademyMemberRole, AcademyStudent

pytestmark = pytest.mark.asyncio

DUAL_ROLE_USER_ID = "dual-role-user"
OTHER_TEACHER_USER_ID = "other-teacher-user"


async def _seed_two_academy_scenario(db_session: AsyncSession, create_test_user):
    """Academy A: dual_role_user is owner. Academy B: dual_role_user is a
    teacher-member, alongside another teacher who has a student matched to
    them (not to dual_role_user)."""
    await create_test_user(user_id=DUAL_ROLE_USER_ID, role="teacher", email="dual-role@test.com")
    await create_test_user(user_id=OTHER_TEACHER_USER_ID, role="teacher", email="other-teacher@test.com")

    academy_a = Academy(
        id=str(uuid4()), slug=f"academy-a-{uuid4().hex[:8]}", name="Academy A", owner_user_id=DUAL_ROLE_USER_ID
    )
    academy_b = Academy(
        id=str(uuid4()), slug=f"academy-b-{uuid4().hex[:8]}", name="Academy B", owner_user_id=OTHER_TEACHER_USER_ID
    )
    db_session.add_all([academy_a, academy_b])
    await db_session.flush()

    owner_a_member = AcademyMember(academy_id=academy_a.id, user_id=DUAL_ROLE_USER_ID, role=AcademyMemberRole.owner)
    owner_b_member = AcademyMember(academy_id=academy_b.id, user_id=OTHER_TEACHER_USER_ID, role=AcademyMemberRole.owner)
    dual_role_teacher_at_b = AcademyMember(
        academy_id=academy_b.id, user_id=DUAL_ROLE_USER_ID, role=AcademyMemberRole.teacher
    )
    other_teacher_at_b = AcademyMember(
        academy_id=academy_b.id, user_id=OTHER_TEACHER_USER_ID, role=AcademyMemberRole.teacher
    )
    db_session.add_all([owner_a_member, owner_b_member, dual_role_teacher_at_b, other_teacher_at_b])
    await db_session.flush()

    # A student in Academy B matched to the OTHER teacher, not dual_role_user.
    other_teachers_student = AcademyStudent(
        academy_id=academy_b.id,
        teacher_member_id=other_teacher_at_b.id,
        name="다른 강사의 학생",
        registered_at=datetime.now(UTC),
    )
    db_session.add(other_teachers_student)
    await db_session.flush()
    await db_session.commit()

    return academy_a.id, academy_b.id, other_teachers_student.id


def _stale_owner_context_headers(academy_a_id: str) -> dict[str, str]:
    """JWT for dual_role_user whose active_context is still set for Academy A
    (owner mode there), not switched to Academy B's teacher context."""
    token = create_access_token(
        data={
            "sub": DUAL_ROLE_USER_ID,
            "role": "teacher",
            "active_context": "academy_owner",
            "academy_id": academy_a_id,
        }
    )
    return {"Authorization": f"Bearer {token}"}


async def test_list_students_isolates_by_real_role_not_stale_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_a_id, academy_b_id, _student_id = await _seed_two_academy_scenario(db_session, create_test_user)

    response = await client.get(
        f"/api/v1/academies/{academy_b_id}/students",
        headers=_stale_owner_context_headers(academy_a_id),
    )
    assert response.status_code == 200
    body = response.json()
    # dual_role_user is only a *teacher* at Academy B (with no matched
    # students of their own) — must NOT see the other teacher's student,
    # regardless of their JWT's stale active_context from Academy A.
    assert body["total_count"] == 0
    assert body["students"] == []


async def test_get_student_blocks_by_real_role_not_stale_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_a_id, _academy_b_id, student_id = await _seed_two_academy_scenario(db_session, create_test_user)

    response = await client.get(
        f"/api/v1/academies/students/{student_id}",
        headers=_stale_owner_context_headers(academy_a_id),
    )
    # dual_role_user is a teacher (not owner) at Academy B and this student is
    # matched to a DIFFERENT teacher — must be blocked regardless of the
    # stale active_context from Academy A.
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_NOT_YOUR_STUDENT"
