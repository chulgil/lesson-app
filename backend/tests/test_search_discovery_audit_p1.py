"""Phase 44 (2026-06-10 audit) — 검색/탐색 도메인 P1 + P0 regression.

P0 #1: /teachers/{id}/reviews RESTful alias
P1 #2: instruments 다중 query 지원
P1 #3: visibility_settings.is_public=false 인 선생님 검색 결과 차단
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _student_headers(user_id: str = "student-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_teacher(
    db_session: AsyncSession,
    *,
    user_id: str,
    name: str,
    instruments: list[str],
    visibility_settings: dict | None = None,
) -> str:
    from app.models.teacher import Teacher
    from app.models.user import User, UserRole

    db_session.add(User(id=user_id, email=f"{user_id}@test.com", name=name, role=UserRole.teacher))
    await db_session.flush()
    teacher = Teacher(
        user_id=user_id,
        instruments=instruments,
        visibility_settings=visibility_settings,
    )
    db_session.add(teacher)
    await db_session.flush()
    return teacher.id


@pytest.mark.asyncio
async def test_teacher_reviews_alias_returns_paginated(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P0 #1 — GET /teachers/{id}/reviews 정상 응답 (alias)."""
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    teacher_id = await _seed_teacher(db_session, user_id="teacher-1", name="홍선생", instruments=["violin"])
    await db_session.commit()

    response = await client.get(
        f"/api/v1/teachers/{teacher_id}/reviews",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert "items" in body
    assert "total" in body


@pytest.mark.asyncio
async def test_teacher_reviews_summary_alias(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P0 #1 — GET /teachers/{id}/reviews/summary 정상 응답."""
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    teacher_id = await _seed_teacher(db_session, user_id="teacher-2", name="홍선생2", instruments=["piano"])
    await db_session.commit()

    response = await client.get(
        f"/api/v1/teachers/{teacher_id}/reviews/summary",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text


@pytest.mark.asyncio
async def test_search_with_multiple_instruments(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #2 — instruments=violin&instruments=piano OR 매칭."""
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    await _seed_teacher(db_session, user_id="t-violin", name="바이올린", instruments=["violin"])
    await _seed_teacher(db_session, user_id="t-piano", name="피아노", instruments=["piano"])
    await _seed_teacher(db_session, user_id="t-flute", name="플루트", instruments=["flute"])
    await db_session.commit()

    response = await client.get(
        "/api/v1/teachers?instruments=violin&instruments=piano",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    user_ids = {item.get("user_id") for item in body["items"]}
    assert "t-violin" in user_ids
    assert "t-piano" in user_ids
    assert "t-flute" not in user_ids


@pytest.mark.asyncio
async def test_search_single_instrument_backward_compat(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #2 — 단수 instrument 도 backward-compat."""
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    await _seed_teacher(db_session, user_id="t-cello", name="첼로", instruments=["cello"])
    await _seed_teacher(db_session, user_id="t-other", name="기타", instruments=["guitar"])
    await db_session.commit()

    response = await client.get(
        "/api/v1/teachers?instrument=cello",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    user_ids = {item.get("user_id") for item in body["items"]}
    assert "t-cello" in user_ids
    assert "t-other" not in user_ids


@pytest.mark.asyncio
async def test_private_teacher_excluded_from_search(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #3 — visibility_settings.is_public=false 인 선생님은 검색 결과 제외."""
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    await _seed_teacher(db_session, user_id="t-public", name="공개", instruments=["violin"])
    await _seed_teacher(
        db_session,
        user_id="t-private",
        name="비공개",
        instruments=["violin"],
        visibility_settings={"is_public": False},
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/teachers?instrument=violin",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    user_ids = {item.get("user_id") for item in body["items"]}
    assert "t-public" in user_ids
    assert "t-private" not in user_ids


@pytest.mark.asyncio
async def test_teacher_visibility_settings_null_treated_as_public(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #3 — visibility_settings NULL (기본) → public 처리."""
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    await _seed_teacher(db_session, user_id="t-default", name="기본", instruments=["violin"])
    await db_session.commit()

    response = await client.get(
        "/api/v1/teachers?instrument=violin",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    user_ids = {item.get("user_id") for item in response.json()["items"]}
    assert "t-default" in user_ids
