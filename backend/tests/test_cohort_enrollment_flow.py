"""P2-4 학생 코호트 신청 → 챗형 승인 — 안 A 배선 (J15b, 2026-08-20 설계).

기존 lesson_request 재사용: 신규 RequestEventType/request_type 값 0 (FE
$enumDecode 크래시 계약). `lesson_requests.group_class_id` nullable 컬럼과
`confirm_proposal` 의 발급 직후 멤버 배정 훅만 추가한다.

1. 신청이 반(group_class_id)을 지정해 생성·반환된다
2. 같은 학생x같은 반 활성 신청 중복 409
3. 그룹 템플릿 제안 confirm → 수강권 발급 + 로스터 배정
4. 정원 초과 시 confirm 전체가 400 (수강권도 미발급 — 승인 시점 집행)
5. 이미 멤버면 confirm 은 멱등 성공 (배정 스킵)

Spec: `.harness/spec/2026-07-31-group-lesson.md` §2 P2-4 챗형 승인 배선.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

_REQUESTS = "/api/v1/schedule/lesson-requests"
_CLASSES = "/api/v1/groups/classes"


async def _make_group_class(
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


async def _make_student(db_session: AsyncSession, create_test_user, *, user_id: str = "test-student-id") -> str:
    """User + 교사 소속 Student 프로필(id == user_id — 제안·수강권 FK 실상 반영)."""
    from app.models.student import Student
    from app.services.subscription_service import resolve_teacher_id

    await create_test_user(user_id=user_id, role="student", name="학생", email=f"{user_id}@test.com")
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    db_session.add(Student(id=user_id, user_id=user_id, teacher_id=teacher_id, name="학생"))
    await db_session.flush()
    return user_id


async def _make_group_proposal(db_session: AsyncSession, class_id: str, *, student_id: str = "test-student-id") -> str:
    """paymentNotified 상태의 그룹 템플릿 제안 — confirm 만 남긴 상태."""
    from app.models.subscription import (
        ProposalPaymentStatus,
        ProposalStatus,
        SubscriptionAppliesTo,
        SubscriptionProposal,
        SubscriptionTemplate,
    )
    from app.services.subscription_service import resolve_teacher_id

    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    template = SubscriptionTemplate(
        teacher_id=teacher_id,
        name="앙상블반 8회권",
        type="package",
        lessons_count=8,
        amount=280000,
        applies_to=SubscriptionAppliesTo.group,
        group_class_id=class_id,
    )
    db_session.add(template)
    await db_session.flush()

    proposal = SubscriptionProposal(
        teacher_id=teacher_id,
        student_id=student_id,
        template_id=template.id,
        status=ProposalStatus.paymentNotified,
        payment_status=ProposalPaymentStatus.completed,
        payment_notified_at=datetime.now(UTC),
        expires_at=datetime.now(UTC) + timedelta(days=7),
    )
    db_session.add(proposal)
    await db_session.flush()
    return proposal.id


async def _members_of(db_session: AsyncSession, class_id: str) -> list:
    from app.models.schedule_ext import GroupClassMember

    rows = await db_session.scalars(select(GroupClassMember).where(GroupClassMember.group_class_id == class_id))
    return list(rows.all())


@pytest.mark.asyncio
async def test_request_carries_group_class_id(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """학생 신청이 반을 지정하고, 응답·조회에 group_class_id 가 실린다."""
    class_id = await _make_group_class(client, auth_headers, create_test_user)
    await _make_student(db_session, create_test_user)
    await db_session.commit()

    response = await client.post(
        _REQUESTS,
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "request_type": "regular", "group_class_id": class_id},
    )
    assert response.status_code in (200, 201), response.text
    assert response.json()["group_class_id"] == class_id


@pytest.mark.asyncio
async def test_duplicate_active_request_conflict(
    client: AsyncClient,
    auth_headers,
    student_auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """같은 학생x같은 반의 활성 신청이 있으면 409."""
    class_id = await _make_group_class(client, auth_headers, create_test_user)
    await _make_student(db_session, create_test_user)
    await db_session.commit()

    payload = {"teacher_id": "test-user-id", "request_type": "regular", "group_class_id": class_id}
    first = await client.post(_REQUESTS, headers=student_auth_headers, json=payload)
    assert first.status_code in (200, 201), first.text
    second = await client.post(_REQUESTS, headers=student_auth_headers, json=payload)
    assert second.status_code == 409, second.text


@pytest.mark.asyncio
async def test_confirm_assigns_member(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """그룹 템플릿 제안 confirm → 수강권 발급 + 로스터 배정 (챗형 승인 종점)."""
    from app.models.subscription import Subscription, SubscriptionProposal

    class_id = await _make_group_class(client, auth_headers, create_test_user)
    await _make_student(db_session, create_test_user)
    proposal_id = await _make_group_proposal(db_session, class_id)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    refreshed = await db_session.get(SubscriptionProposal, proposal_id)
    assert refreshed.subscription_id is not None
    issued = await db_session.get(Subscription, refreshed.subscription_id)
    assert issued.group_class_id == class_id
    members = await _members_of(db_session, class_id)
    assert [m.student_id for m in members] == ["test-student-id"]


@pytest.mark.asyncio
async def test_confirm_blocked_when_capacity_full(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """정원이 차면 confirm 전체가 400 — 수강권도 발급되지 않는다 (승인 시점 집행)."""
    from app.models.schedule_ext import GroupClassMember
    from app.models.student import Student
    from app.models.subscription import SubscriptionProposal
    from app.services.subscription_service import resolve_teacher_id

    class_id = await _make_group_class(client, auth_headers, create_test_user, max_capacity=1)
    await _make_student(db_session, create_test_user)
    teacher_id = await resolve_teacher_id(db_session, "test-user-id")
    other = Student(id="other-prof", user_id="other-user", teacher_id=teacher_id, name="선점학생")
    db_session.add(other)
    db_session.add(GroupClassMember(group_class_id=class_id, student_id="other-prof"))
    proposal_id = await _make_group_proposal(db_session, class_id)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 400, response.text

    db_session.expire_all()
    refreshed = await db_session.get(SubscriptionProposal, proposal_id)
    assert refreshed.subscription_id is None, "정원 초과 시 발급 자체가 롤백돼야 한다"
    members = await _members_of(db_session, class_id)
    assert [m.student_id for m in members] == ["other-prof"]


@pytest.mark.asyncio
async def test_confirm_idempotent_when_already_member(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
):
    """이미 로스터에 있으면 confirm 은 멱등 성공 — 멤버 행 1개 유지."""
    from app.models.schedule_ext import GroupClassMember
    from app.models.subscription import SubscriptionProposal

    class_id = await _make_group_class(client, auth_headers, create_test_user)
    await _make_student(db_session, create_test_user)
    db_session.add(GroupClassMember(group_class_id=class_id, student_id="test-student-id"))
    proposal_id = await _make_group_proposal(db_session, class_id)
    await db_session.commit()

    response = await client.patch(
        f"/api/v1/subscriptions-proposals/{proposal_id}/confirm",
        headers=auth_headers,
        json={},
    )
    assert response.status_code == 200, response.text

    db_session.expire_all()
    refreshed = await db_session.get(SubscriptionProposal, proposal_id)
    assert refreshed.subscription_id is not None
    members = await _members_of(db_session, class_id)
    assert len(members) == 1
