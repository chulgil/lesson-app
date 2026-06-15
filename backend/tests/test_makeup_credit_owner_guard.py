"""Authorization guard: grant_makeup_credit must scope to the calling teacher's students.

Issue #741 — teacher A must not be able to grant makeup credits for teacher B's students.

Tests:
  (a) Granting to a student NOT belonging to the calling teacher → 403.
  (b) Granting to the calling teacher's OWN student → 201 success.
"""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.student import Student
from app.models.teacher import Teacher

pytestmark = pytest.mark.asyncio

TEACHER_USER_ID = "test-user-id"
TEACHER_PROFILE_ID = f"{TEACHER_USER_ID}-prof"


def _teacher_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": TEACHER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_own_student(db_session: AsyncSession) -> str:
    """A student whose teacher_id == TEACHER_PROFILE_ID (calling teacher owns them)."""
    student_id = f"student-own-{uuid4()}"
    db_session.add(
        Student(
            id=student_id,
            teacher_id=TEACHER_PROFILE_ID,
            name="Own Student",
        )
    )
    await db_session.flush()
    return student_id


async def _seed_other_teacher_student(db_session: AsyncSession) -> str:
    """A student belonging to a DIFFERENT teacher — the calling teacher must not touch them."""
    other_teacher_id = f"other-teacher-{uuid4()}"
    other_user_id = f"other-user-{uuid4()}"
    db_session.add(Teacher(id=other_teacher_id, user_id=other_user_id))
    await db_session.flush()

    student_id = f"student-other-{uuid4()}"
    db_session.add(
        Student(
            id=student_id,
            teacher_id=other_teacher_id,
            name="Other Student",
        )
    )
    await db_session.flush()
    return student_id


# ---------------------------------------------------------------------------
# (a) Cross-teacher grant must be rejected with 403
# ---------------------------------------------------------------------------


async def test_grant_credit_to_other_teachers_student_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Teacher may not grant a makeup credit to a student that belongs to another teacher."""
    await create_test_user()  # seeds the calling teacher (TEACHER_PROFILE_ID)
    other_student_id = await _seed_other_teacher_student(db_session)
    await db_session.commit()

    response = await client.post(
        "/api/v1/teachers/me/makeup-credits",
        headers=_teacher_headers(),
        json={"student_id": other_student_id, "reason_note": "cross-teacher attack"},
    )

    assert response.status_code == 403, response.text


# ---------------------------------------------------------------------------
# (b) Grant to own student must succeed with 201
# ---------------------------------------------------------------------------


async def test_grant_credit_to_own_student_returns_201(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    """Teacher can successfully grant a makeup credit to their own student."""
    await create_test_user()  # seeds the calling teacher (TEACHER_PROFILE_ID)
    own_student_id = await _seed_own_student(db_session)
    await db_session.commit()

    response = await client.post(
        "/api/v1/teachers/me/makeup-credits",
        headers=_teacher_headers(),
        json={"student_id": own_student_id, "reason_note": "legitimate grant"},
    )

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["student_id"] == own_student_id
    assert body["teacher_id"] == TEACHER_PROFILE_ID
    assert body["reason"] == "manualGrant"
