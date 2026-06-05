"""Tests for /academies/{id}/announcements — AC-M3 학원 공지 BE."""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"
OTHER_USER_ID = "other-user-id"


def _owner_headers(active_context: str | None = None, academy_id: str | None = None) -> dict[str, str]:
    payload: dict[str, str] = {"sub": OWNER_USER_ID, "role": "teacher"}
    if active_context:
        payload["active_context"] = active_context
    if academy_id:
        payload["academy_id"] = academy_id
    return {"Authorization": f"Bearer {create_access_token(data=payload)}"}


async def _create_academy(client: AsyncClient, create_test_user) -> str:
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={
            "slug": f"ann-{uuid4().hex[:8]}",
            "name": "공지 테스트",
            "also_register_as_teacher": True,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# POST /academies/{id}/announcements — 학원장 draft 생성
# ---------------------------------------------------------------------------


async def test_owner_creates_announcement_draft(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "휴원 안내",
            "body_markdown": "**다음 주 월요일 휴원합니다.**",
            "audience": "all",
            "channels": ["inapp"],
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "휴원 안내"
    assert body["audience"] == "all"
    assert body["status"] == "draft"
    assert body["channels"] == ["inapp"]
    assert body["academy_id"] == academy_id
    assert body["author_user_id"] == OWNER_USER_ID


async def test_teacher_context_blocked_from_create(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → 학원장 전용 endpoint 차단 (§6.2)."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
        json={
            "title": "차단 시도",
            "body_markdown": "차단되어야 함",
            "audience": "all",
        },
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_non_owner_create_returns_403(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """학원 비멤버 → 403 (assert_owner)."""
    academy_id = await _create_academy(client, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="other@test.com")

    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=other_headers,
        json={"title": "차단", "body_markdown": "x", "audience": "all"},
    )
    assert response.status_code == 403


async def test_teacher_students_audience_requires_filter(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """audience=teacher_students 인데 audience_filter 없으면 400."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "강사별 안내",
            "body_markdown": "강사 X 의 학생들에게만",
            "audience": "teacher_students",
        },
    )
    assert response.status_code == 400


async def test_audience_filter_persists(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """audience_filter JSON 보존."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "강사 김선생 학생",
            "body_markdown": "강사별 공지",
            "audience": "teacher_students",
            "audience_filter": {"teacher_member_id": "tm-123"},
            "channels": ["inapp", "kakao"],
            "kakao_template_id": "TPL_GENERAL",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["audience_filter"] == {"teacher_member_id": "tm-123"}
    assert body["channels"] == ["inapp", "kakao"]
    assert body["kakao_template_id"] == "TPL_GENERAL"


# ---------------------------------------------------------------------------
# GET 목록 + 단건
# ---------------------------------------------------------------------------


async def test_member_lists_announcements(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    # 2건 생성
    for title in ["공지 1", "공지 2"]:
        await client.post(
            f"/api/v1/academies/{academy_id}/announcements",
            headers=_owner_headers(),
            json={"title": title, "body_markdown": "x", "audience": "all"},
        )

    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 2
    titles = [a["title"] for a in body["announcements"]]
    assert "공지 1" in titles and "공지 2" in titles


async def test_non_member_list_returns_403(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="o@test.com")
    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=other_headers,
    )
    assert response.status_code == 403


async def test_get_announcement_detail(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    created = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={"title": "단건 조회", "body_markdown": "**굵게**", "audience": "all"},
    )
    announcement_id = created.json()["id"]

    response = await client.get(
        f"/api/v1/academies/announcements/{announcement_id}",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == announcement_id
    assert body["body_markdown"] == "**굵게**"


async def test_get_announcement_404_when_not_found(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/announcements/{uuid4()}",
        headers=_owner_headers(),
    )
    assert response.status_code == 404


async def test_teacher_member_can_list_but_not_create(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원 강사 멤버는 목록 조회 OK, 생성은 owner_context 가드로 차단."""
    academy_id = await _create_academy(client, create_test_user)
    # 학원장 1건 생성
    await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={"title": "공통", "body_markdown": "x", "audience": "all"},
    )

    # 같은 user 의 teacher 모드 (학원장 겸직 강사)
    teacher_headers = _owner_headers(active_context="teacher", academy_id=academy_id)

    # 목록 조회는 통과 (router-level 의존성 없음)
    list_resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=teacher_headers,
    )
    assert list_resp.status_code == 200
    assert list_resp.json()["total_count"] == 1

    # 생성은 차단 (endpoint-level require_owner_context)
    create_resp = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=teacher_headers,
        json={"title": "강사 시도", "body_markdown": "x", "audience": "all"},
    )
    assert create_resp.status_code == 403
