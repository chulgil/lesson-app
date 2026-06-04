"""Tests for makeup credit endpoints (#432).

Spec: docs/specs/subscription/makeup_credit_spec.md §8.1.
FE contract: frontend/lib/.../remote_makeup_credit_repository.dart.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.makeup_credit import MakeupCredit, MakeupCreditReason
from app.models.student import Student
from app.models.teacher import Teacher

pytestmark = pytest.mark.asyncio


TEACHER_USER_ID = "test-user-id"
TEACHER_PROFILE_ID = f"{TEACHER_USER_ID}-prof"
STUDENT_USER_ID = "test-student-id"


def _teacher_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": TEACHER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _student_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": STUDENT_USER_ID, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_student(db_session: AsyncSession, *, with_user: bool = True) -> str:
    student_id = f"student-{uuid4()}"
    db_session.add(
        Student(
            id=student_id,
            user_id=STUDENT_USER_ID if with_user else None,
            teacher_id=TEACHER_PROFILE_ID,
            name="Test Student",
        )
    )
    await db_session.flush()
    return student_id


async def _seed_credit(
    db_session: AsyncSession,
    *,
    student_id: str,
    teacher_id: str = TEACHER_PROFILE_ID,
    reason: MakeupCreditReason = MakeupCreditReason.manualGrant,
    used: bool = False,
    expired: bool = False,
) -> str:
    now = datetime.now(UTC)
    expires_at = now - timedelta(days=1) if expired else now + timedelta(days=30)
    credit = MakeupCredit(
        id=f"credit-{uuid4()}",
        student_id=student_id,
        teacher_id=teacher_id,
        reason=reason,
        expires_at=expires_at,
        used_at=now if used else None,
        used_lesson_id=f"lesson-{uuid4()}" if used else None,
    )
    db_session.add(credit)
    await db_session.flush()
    return credit.id


# ---------------------------------------------------------------------------
# Teacher: grant + list
# ---------------------------------------------------------------------------


async def test_teacher_grants_manual_credit(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)

    response = await client.post(
        "/api/v1/teachers/me/makeup-credits",
        headers=_teacher_headers(),
        json={"student_id": student_id, "reason_note": "exception"},
    )

    assert response.status_code == 201
    body = response.json()
    assert body["student_id"] == student_id
    assert body["teacher_id"] == TEACHER_PROFILE_ID
    assert body["reason"] == "manualGrant"
    assert body["used_at"] is None


async def test_teacher_lists_only_own_issued_credits(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)

    # Another teacher issued a credit to the same student — must not appear.
    other_teacher_id = f"other-teacher-{uuid4()}"
    db_session.add(Teacher(id=other_teacher_id, user_id=f"other-user-{uuid4()}"))
    await db_session.flush()
    mine = await _seed_credit(db_session, student_id=student_id)
    await _seed_credit(db_session, student_id=student_id, teacher_id=other_teacher_id)
    await db_session.commit()

    response = await client.get(
        "/api/v1/teachers/me/makeup-credits",
        headers=_teacher_headers(),
        params={"student_id": student_id},
    )

    assert response.status_code == 200
    credits = response.json()["credits"]
    assert [c["id"] for c in credits] == [mine]


# ---------------------------------------------------------------------------
# Student: list active only
# ---------------------------------------------------------------------------


async def test_student_sees_only_active_credits(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    await create_test_user(user_id=STUDENT_USER_ID, role="student", name="Test Student", email="s@test.com")
    student_id = await _seed_student(db_session)

    active = await _seed_credit(db_session, student_id=student_id)
    await _seed_credit(db_session, student_id=student_id, used=True)
    await _seed_credit(db_session, student_id=student_id, expired=True)
    await db_session.commit()

    response = await client.get(
        "/api/v1/students/me/makeup-credits",
        headers=_student_headers(),
    )

    assert response.status_code == 200
    credits = response.json()["credits"]
    assert [c["id"] for c in credits] == [active]


# ---------------------------------------------------------------------------
# Teacher: revoke
# ---------------------------------------------------------------------------


async def test_teacher_revokes_unused_credit(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)
    credit_id = await _seed_credit(db_session, student_id=student_id)
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teachers/me/makeup-credits/{credit_id}",
        headers=_teacher_headers(),
    )
    assert response.status_code == 204

    # Verify it's actually gone.
    remaining = await db_session.get(MakeupCredit, credit_id)
    assert remaining is None


async def test_revoke_used_credit_returns_409(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)
    credit_id = await _seed_credit(db_session, student_id=student_id, used=True)
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teachers/me/makeup-credits/{credit_id}",
        headers=_teacher_headers(),
    )
    assert response.status_code == 409


async def test_revoke_other_teachers_credit_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)

    other_teacher_id = f"other-teacher-{uuid4()}"
    db_session.add(Teacher(id=other_teacher_id, user_id=f"other-user-{uuid4()}"))
    await db_session.flush()
    credit_id = await _seed_credit(db_session, student_id=student_id, teacher_id=other_teacher_id)
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/teachers/me/makeup-credits/{credit_id}",
        headers=_teacher_headers(),
    )
    assert response.status_code == 403


async def test_revoke_missing_credit_returns_404(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()

    response = await client.delete(
        "/api/v1/teachers/me/makeup-credits/nonexistent-id",
        headers=_teacher_headers(),
    )
    assert response.status_code == 404
