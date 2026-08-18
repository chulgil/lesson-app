"""P2-4 코호트 멤버 — 교사 배정·정원 검증 (J4).

반(코호트)의 고정 로스터를 고정한다.

1. 소유 교사만 배정/제외 (타 교사 403), 타 교사의 학생 배정 403 (IDOR)
2. 정원(max_capacity) 초과 배정 400, 중복 배정 409
3. 학생은 자기 등록 반만 조회 (`GET /groups/classes?student_id=`) — 타인 403

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P2-4 / §4 API.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

_CLASSES = "/api/v1/groups/classes"


def _members_url(class_id: str) -> str:
    return f"{_CLASSES}/{class_id}/members"


async def _make_teacher_and_class(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    *,
    max_capacity: int = 6,
) -> str:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍선생")
    payload = {
        "name": "앙상블반",
        "type": "regular",
        "max_capacity": max_capacity,
        "duration_minutes": 60,
        "no_show_policy": "deductCredit",
        "repeat_days_of_week": [1],
        "repeat_time_of_day": "18:00",
    }
    response = await client.post(_CLASSES, headers=auth_headers, json=payload)
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def _make_student(
    db_session: AsyncSession,
    create_test_user,
    *,
    user_id: str,
    teacher_id: str,
    name: str = "학생",
) -> str:
    from app.models.student import Student

    await create_test_user(user_id=user_id, role="student", name=name, email=f"{user_id}@test.com")
    student = Student(id=f"{user_id}-prof", user_id=user_id, teacher_id=teacher_id, name=name)
    db_session.add(student)
    await db_session.flush()
    return student.id


async def _teacher_profile_id(db_session: AsyncSession, user_id: str = "test-user-id") -> str:
    from app.services.subscription_service import resolve_teacher_id

    return await resolve_teacher_id(db_session, user_id)


def _headers_for(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_assign_and_list_member(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """소유 교사가 자기 학생을 배정하면 로스터에 나타난다."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    teacher_id = await _teacher_profile_id(db_session)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    await db_session.commit()

    assigned = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": student_id})
    assert assigned.status_code == 201, assigned.text

    listed = await client.get(_members_url(class_id), headers=auth_headers)
    assert listed.status_code == 200, listed.text
    members = listed.json()
    assert len(members) == 1
    assert members[0]["student_id"] == student_id
    assert members[0]["student_name"] == "학생"


@pytest.mark.asyncio
async def test_capacity_blocks_assignment(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """정원이 차면 추가 배정은 400 — 로스터가 좌석을 초과하지 않는다."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user, max_capacity=2)
    teacher_id = await _teacher_profile_id(db_session)
    sids = []
    for i in range(3):
        sids.append(
            await _make_student(db_session, create_test_user, user_id=f"s{i}", teacher_id=teacher_id, name=f"학생{i}")
        )
    await db_session.commit()

    for sid in sids[:2]:
        ok = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": sid})
        assert ok.status_code == 201, ok.text

    blocked = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": sids[2]})
    assert blocked.status_code == 400, blocked.text


@pytest.mark.asyncio
async def test_duplicate_assignment_conflict(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """같은 학생을 두 번 배정하면 409."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    teacher_id = await _teacher_profile_id(db_session)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    await db_session.commit()

    first = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": student_id})
    assert first.status_code == 201, first.text
    second = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": student_id})
    assert second.status_code == 409, second.text


@pytest.mark.asyncio
async def test_other_teacher_cannot_assign(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """타 교사는 남의 클래스에 배정할 수 없다 (403)."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    teacher_id = await _teacher_profile_id(db_session)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    await create_test_user(user_id="other-teacher", role="teacher", name="타교사", email="other@test.com")
    await db_session.commit()

    response = await client.post(
        _members_url(class_id),
        headers=_headers_for("other-teacher", "teacher"),
        json={"student_id": student_id},
    )
    assert response.status_code in (403, 404), response.text


@pytest.mark.asyncio
async def test_assign_other_teachers_student_forbidden(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """내 클래스라도 남의 학생은 배정 불가 (403 — IDOR 차단)."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    await create_test_user(user_id="other-teacher", role="teacher", name="타교사", email="other@test.com")
    other_teacher_id = await _teacher_profile_id(db_session, "other-teacher")
    foreign_student = await _make_student(
        db_session, create_test_user, user_id="s9", teacher_id=other_teacher_id, name="남의학생"
    )
    await db_session.commit()

    response = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": foreign_student})
    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_remove_member(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """배정 제외 후 로스터에서 사라진다."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    teacher_id = await _teacher_profile_id(db_session)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    await db_session.commit()

    assigned = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": student_id})
    assert assigned.status_code == 201, assigned.text

    removed = await client.delete(f"{_members_url(class_id)}/{student_id}", headers=auth_headers)
    assert removed.status_code == 200, removed.text

    listed = await client.get(_members_url(class_id), headers=auth_headers)
    assert listed.json() == []


@pytest.mark.asyncio
async def test_student_lists_enrolled_classes(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """학생은 자기 등록 반만 student_id 필터로 조회한다 (아젠다 데이터원)."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    teacher_id = await _teacher_profile_id(db_session)
    student_id = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    # 두 번째 반은 배정하지 않는다 — 필터가 로스터 기준임을 증명.
    other = await client.post(
        _CLASSES,
        headers=auth_headers,
        json={
            "name": "미배정반",
            "type": "regular",
            "max_capacity": 6,
            "duration_minutes": 60,
            "no_show_policy": "deductCredit",
            "repeat_days_of_week": [2],
            "repeat_time_of_day": "17:00",
        },
    )
    assert other.status_code == 201, other.text
    await db_session.commit()

    assigned = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": student_id})
    assert assigned.status_code == 201, assigned.text

    response = await client.get(
        _CLASSES,
        headers=_headers_for("s1", "student"),
        params={"student_id": student_id},
    )
    assert response.status_code == 200, response.text
    items = response.json()["items"]
    assert [item["id"] for item in items] == [class_id]


@pytest.mark.asyncio
async def test_student_cannot_list_others_enrollments(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """타 학생의 등록 반 조회는 403."""
    class_id = await _make_teacher_and_class(client, auth_headers, create_test_user)
    teacher_id = await _teacher_profile_id(db_session)
    target = await _make_student(db_session, create_test_user, user_id="s1", teacher_id=teacher_id)
    await _make_student(db_session, create_test_user, user_id="s2", teacher_id=teacher_id, name="다른학생")
    await db_session.commit()

    assigned = await client.post(_members_url(class_id), headers=auth_headers, json={"student_id": target})
    assert assigned.status_code == 201, assigned.text

    response = await client.get(
        _CLASSES,
        headers=_headers_for("s2", "student"),
        params={"student_id": target},
    )
    assert response.status_code == 403, response.text
