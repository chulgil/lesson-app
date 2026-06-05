"""Tests for AC-M2 권한 매트릭스 dependencies.

Spec: docs/specs/web/academy/context_toggle_spec.md §6.

검증 대상:
- require_owner_context — active_context == "teacher" → 403 FORBIDDEN_TEACHER_SCOPE
- require_teacher_context — active_context == "academy_owner" → 403 FORBIDDEN_ACADEMY_OWNER_SCOPE
- active_context 미지정 (AC-M1 호환 토큰) → 통과
"""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.academy import AcademyMember, AcademyMemberRole
from app.models.academy_governance import ContextAccessDenialLog

pytestmark = pytest.mark.asyncio


async def _list_denial_logs(db_session: AsyncSession) -> list[ContextAccessDenialLog]:
    """모든 ContextAccessDenialLog row 반환 (created_at desc). 테스트 헬퍼."""
    result = await db_session.scalars(select(ContextAccessDenialLog).order_by(ContextAccessDenialLog.denied_at.desc()))
    return list(result.all())


USER_ID = "test-user-id"


def _headers(active_context: str | None = None, academy_id: str | None = None) -> dict[str, str]:
    payload: dict[str, str] = {"sub": USER_ID, "role": "teacher"}
    if active_context:
        payload["active_context"] = active_context
    if academy_id:
        payload["academy_id"] = academy_id
    return {"Authorization": f"Bearer {create_access_token(data=payload)}"}


async def _create_academy(client: AsyncClient, create_test_user) -> str:
    await create_test_user(user_id=USER_ID, role="teacher", name="김원장")
    resp = await client.post(
        "/api/v1/academies",
        headers=_headers(),
        json={
            "slug": f"perm-{uuid4().hex[:8]}",
            "name": "권한 매트릭스 테스트",
            "also_register_as_teacher": True,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


async def _get_owner_teacher_member_id(db_session: AsyncSession, academy_id: str) -> str:
    """학원장 본인의 teacher AcademyMember id 조회."""
    member_id = await db_session.scalar(
        select(AcademyMember.id).where(
            AcademyMember.academy_id == academy_id,
            AcademyMember.user_id == USER_ID,
            AcademyMember.role == AcademyMemberRole.teacher,
        )
    )
    assert member_id is not None
    return member_id


async def _create_student(
    client: AsyncClient,
    academy_id: str,
    *,
    name: str,
    teacher_member_id: str | None = None,
) -> str:
    """학원장 모드로 학생 등록. teacher_member_id None 이면 waiting 상태."""
    body: dict = {"name": name, "instrument": "피아노"}
    if teacher_member_id:
        body["teacher_member_id"] = teacher_member_id
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_headers(),
        json=body,
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# require_owner_context — 콘솔 라우트 (academy_billing, academy_governance)
# ---------------------------------------------------------------------------


async def test_teacher_context_blocked_from_billing(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher 강사 모드 JWT 로 billing 라우트 → 403."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    body = response.json()
    assert body["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"
    assert "학원 운영" in body["detail"]["message"]


async def test_teacher_context_blocked_from_governance(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher 강사 모드 JWT 로 governance 라우트 → 403."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/context-switches/me",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_owner_context_passes_billing(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """active_context=academy_owner JWT → billing 라우트 통과 (200)."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_headers(active_context="academy_owner", academy_id=academy_id),
    )
    assert response.status_code == 200


async def test_no_active_context_passes_billing_backward_compat(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """AC-M1 호환: active_context 없는 JWT 로 billing 라우트 호출 → 200.

    토글을 거치지 않은 일반 로그인 토큰은 차단하지 않는다 (기존 라우트의
    assert_owner / role 체크가 권한을 강제).
    """
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_headers(),  # active_context 미지정
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# require_teacher_context — lesson-app 전용 라우트 (recordings, practice_logs)
# ---------------------------------------------------------------------------


async def test_owner_context_blocked_from_recordings(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=academy_owner 학원장 모드 JWT 로 recordings → 403."""
    await create_test_user(user_id=USER_ID, role="teacher")
    response = await client.get(
        "/api/v1/recordings",
        headers=_headers(active_context="academy_owner"),
    )
    assert response.status_code == 403
    body = response.json()
    assert body["detail"]["error"] == "FORBIDDEN_ACADEMY_OWNER_SCOPE"
    assert "학생" in body["detail"]["message"]


async def test_owner_context_blocked_from_practice_logs(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=academy_owner JWT 로 practice_logs → 403."""
    await create_test_user(user_id=USER_ID, role="teacher")
    response = await client.get(
        "/api/v1/practice-logs/",
        headers=_headers(active_context="academy_owner"),
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_ACADEMY_OWNER_SCOPE"


async def test_teacher_context_passes_recordings(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher 강사 모드 JWT → recordings 통과 (200)."""
    await create_test_user(user_id=USER_ID, role="teacher")
    response = await client.get(
        "/api/v1/recordings",
        headers=_headers(active_context="teacher"),
    )
    assert response.status_code == 200


async def test_no_active_context_passes_recordings_backward_compat(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """AC-M1 호환: active_context 없는 일반 강사 토큰 → recordings 통과."""
    await create_test_user(user_id=USER_ID, role="teacher")
    response = await client.get(
        "/api/v1/recordings",
        headers=_headers(),
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# academies.py endpoint 단위 require_owner_context
# ---------------------------------------------------------------------------


async def test_teacher_context_blocked_from_update_academy(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → PATCH /academies/{id} 차단."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.patch(
        f"/api/v1/academies/{academy_id}",
        headers=_headers(active_context="teacher", academy_id=academy_id),
        json={"name": "이름 변경 시도"},
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_teacher_context_blocked_from_create_invite(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → POST /academies/{id}/invites 차단 (spec §6.2 강사 초대)."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_headers(active_context="teacher", academy_id=academy_id),
        json={"display_name": "신규 강사", "email": "new@test.com"},
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_teacher_context_blocked_from_list_invites(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → GET /academies/{id}/invites 차단."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/invites",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_teacher_context_blocked_from_create_student(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → POST /academies/{id}/students 차단."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/students",
        headers=_headers(active_context="teacher", academy_id=academy_id),
        json={"display_name": "신규 학생"},
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_owner_context_passes_update_academy(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=academy_owner → PATCH /academies/{id} 통과."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.patch(
        f"/api/v1/academies/{academy_id}",
        headers=_headers(active_context="academy_owner", academy_id=academy_id),
        json={"name": "이름 갱신"},
    )
    assert response.status_code == 200


async def test_no_active_context_passes_update_academy_backward_compat(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """AC-M1 호환: active_context 없는 owner 토큰 → PATCH /academies/{id} 통과."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.patch(
        f"/api/v1/academies/{academy_id}",
        headers=_headers(),
        json={"name": "AC-M1 호환"},
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# 공용 endpoint — teacher 모드에서도 통과해야 함
# ---------------------------------------------------------------------------


async def test_teacher_context_passes_get_academy_detail(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """공용: GET /academies/{id} 는 teacher 모드에서도 통과."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 200


async def test_teacher_context_passes_list_my_academies(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """공용: GET /academies/me 는 teacher 모드에서도 통과."""
    await _create_academy(client, create_test_user)
    response = await client.get(
        "/api/v1/academies/me",
        headers=_headers(active_context="teacher"),
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# 강사 모드 학생 필터링 — spec §6.2: teacher 컨텍스트는 본인 매칭 학생만
# ---------------------------------------------------------------------------


async def test_teacher_context_lists_only_matched_students(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → list_students 는 본인 매칭 학생만 반환."""
    academy_id = await _create_academy(client, create_test_user)
    teacher_member_id = await _get_owner_teacher_member_id(db_session, academy_id)

    matched_id = await _create_student(client, academy_id, name="김지민", teacher_member_id=teacher_member_id)
    await _create_student(client, academy_id, name="이대기")  # 매칭 없음 (waiting)

    response = await client.get(
        f"/api/v1/academies/{academy_id}/students",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 1
    assert len(body["students"]) == 1
    assert body["students"][0]["id"] == matched_id


async def test_owner_context_lists_all_students(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=academy_owner → list_students 전체 반환."""
    academy_id = await _create_academy(client, create_test_user)
    teacher_member_id = await _get_owner_teacher_member_id(db_session, academy_id)

    await _create_student(client, academy_id, name="김지민", teacher_member_id=teacher_member_id)
    await _create_student(client, academy_id, name="이대기")

    response = await client.get(
        f"/api/v1/academies/{academy_id}/students",
        headers=_headers(active_context="academy_owner", academy_id=academy_id),
    )
    assert response.status_code == 200
    assert response.json()["total_count"] == 2


async def test_no_active_context_lists_all_students_backward_compat(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """AC-M1 호환: active_context 미지정 → 전체 학생 반환."""
    academy_id = await _create_academy(client, create_test_user)
    teacher_member_id = await _get_owner_teacher_member_id(db_session, academy_id)
    await _create_student(client, academy_id, name="김지민", teacher_member_id=teacher_member_id)
    await _create_student(client, academy_id, name="이대기")

    response = await client.get(
        f"/api/v1/academies/{academy_id}/students",
        headers=_headers(),
    )
    assert response.status_code == 200
    assert response.json()["total_count"] == 2


async def test_teacher_context_gets_own_matched_student(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher + 본인 매칭 학생 GET → 200."""
    academy_id = await _create_academy(client, create_test_user)
    teacher_member_id = await _get_owner_teacher_member_id(db_session, academy_id)
    matched_id = await _create_student(client, academy_id, name="김지민", teacher_member_id=teacher_member_id)

    response = await client.get(
        f"/api/v1/academies/students/{matched_id}",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 200
    assert response.json()["id"] == matched_id


async def test_teacher_context_blocked_from_unmatched_student(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher + 본인 매칭 아닌 학생 GET → 403 FORBIDDEN_NOT_YOUR_STUDENT."""
    academy_id = await _create_academy(client, create_test_user)
    waiting_id = await _create_student(client, academy_id, name="이대기")

    response = await client.get(
        f"/api/v1/academies/students/{waiting_id}",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    body = response.json()
    assert body["detail"]["error"] == "FORBIDDEN_NOT_YOUR_STUDENT"
    assert "본인이 담당하지 않는" in body["detail"]["message"]


async def test_owner_context_gets_any_student(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """active_context=academy_owner → 매칭 무관 GET 통과."""
    academy_id = await _create_academy(client, create_test_user)
    waiting_id = await _create_student(client, academy_id, name="이대기")

    response = await client.get(
        f"/api/v1/academies/students/{waiting_id}",
        headers=_headers(active_context="academy_owner", academy_id=academy_id),
    )
    assert response.status_code == 200


# ---------------------------------------------------------------------------
# AuditLog 통합 — spec §6.3 audit_id 응답 + §9 DB 기록 보존
# ---------------------------------------------------------------------------


async def test_denial_returns_audit_id_and_records_log(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """차단 응답 detail.audit_id == ContextAccessDenialLog.id 일치 + DB row 보존."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    body = response.json()
    audit_id = body["detail"]["audit_id"]
    assert isinstance(audit_id, str) and len(audit_id) > 0

    logs = await _list_denial_logs(db_session)
    assert len(logs) == 1
    log = logs[0]
    assert log.id == audit_id
    assert log.user_id == USER_ID
    assert log.active_context == "teacher"
    assert log.academy_id == academy_id
    assert log.denial_code == "FORBIDDEN_TEACHER_SCOPE"
    assert log.endpoint_path == f"/api/v1/academies/{academy_id}/billing/subscriptions"
    assert log.http_method == "GET"


async def test_owner_context_denial_records_audit(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=academy_owner → recordings 차단 시 audit 기록 + audit_id 응답."""
    await create_test_user(user_id=USER_ID, role="teacher")
    response = await client.get(
        "/api/v1/recordings",
        headers=_headers(active_context="academy_owner"),
    )
    assert response.status_code == 403
    audit_id = response.json()["detail"]["audit_id"]

    logs = await _list_denial_logs(db_session)
    assert len(logs) == 1
    log = logs[0]
    assert log.id == audit_id
    assert log.denial_code == "FORBIDDEN_ACADEMY_OWNER_SCOPE"
    assert log.endpoint_path == "/api/v1/recordings"
    assert log.academy_id is None  # JWT 에 academy_id 미포함


async def test_not_your_student_denial_records_audit_with_target(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """FORBIDDEN_NOT_YOUR_STUDENT 차단도 audit 기록 + target_resource_id 채움."""
    academy_id = await _create_academy(client, create_test_user)
    waiting_id = await _create_student(client, academy_id, name="이대기")

    response = await client.get(
        f"/api/v1/academies/students/{waiting_id}",
        headers=_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    audit_id = response.json()["detail"]["audit_id"]

    logs = await _list_denial_logs(db_session)
    assert len(logs) == 1
    log = logs[0]
    assert log.id == audit_id
    assert log.denial_code == "FORBIDDEN_NOT_YOUR_STUDENT"
    assert log.target_resource_id == waiting_id
    assert log.academy_id == academy_id


async def test_pass_through_does_not_record_audit(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """통과한 요청은 audit 미기록."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_headers(active_context="academy_owner", academy_id=academy_id),
    )
    assert response.status_code == 200

    logs = await _list_denial_logs(db_session)
    assert len(logs) == 0


async def test_no_active_context_does_not_record_audit_backward_compat(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """AC-M1 호환 토큰 (active_context 미지정) → 통과, audit 미기록."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/billing/subscriptions",
        headers=_headers(),
    )
    assert response.status_code == 200

    logs = await _list_denial_logs(db_session)
    assert len(logs) == 0
