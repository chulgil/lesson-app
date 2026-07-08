"""Teacher announcement UPDATE / DELETE API contract tests."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementDate

TEACHER_USER_ID = "test-user-id"
TEACHER_PROFILE_ID = "test-user-id-prof"

OTHER_TEACHER_USER_ID = "other-teacher-id"
OTHER_TEACHER_PROFILE_ID = "other-teacher-id-prof"


def _other_teacher_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": OTHER_TEACHER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


async def _create_general(client: AsyncClient, headers: dict[str, str], *, teacher_id: str) -> str:
    response = await client.post(
        "/api/v1/announcements",
        headers=headers,
        json={"teacher_id": teacher_id, "type": "general", "message": "원본 공지", "dates": []},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


async def _create_day_off(
    client: AsyncClient,
    headers: dict[str, str],
    *,
    teacher_id: str,
    dates: list[str],
) -> str:
    response = await client.post(
        "/api/v1/announcements",
        headers=headers,
        json={"teacher_id": teacher_id, "type": "dayOff", "message": "휴강 원본", "dates": dates},
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


@pytest.mark.asyncio
async def test_update_general_announcement_changes_message(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    announcement_id = await _create_general(client, auth_headers, teacher_id=TEACHER_PROFILE_ID)

    response = await client.put(
        f"/api/v1/announcements/{announcement_id}",
        headers=auth_headers,
        json={"message": "수정된 공지", "dates": []},
    )
    assert response.status_code == 200, response.text

    body = response.json()
    assert body["id"] == announcement_id
    assert body["message"] == "수정된 공지"
    assert body["type"] == "general"
    assert body["dates"] == []


@pytest.mark.asyncio
async def test_update_day_off_replaces_dates(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    announcement_id = await _create_day_off(
        client, auth_headers, teacher_id=TEACHER_PROFILE_ID, dates=["2026-05-09", "2026-05-10"]
    )

    response = await client.put(
        f"/api/v1/announcements/{announcement_id}",
        headers=auth_headers,
        json={"message": "휴강 변경", "dates": ["2026-05-15", "2026-05-15"]},
    )
    assert response.status_code == 200, response.text

    body = response.json()
    assert body["type"] == "dayOff"
    assert body["message"] == "휴강 변경"
    assert body["dates"] == ["2026-05-15"]

    # 기존 날짜 행이 완전히 교체되었는지 DB 로 확인.
    remaining_dates = (
        await db_session.scalars(
            select(TeacherAnnouncementDate).where(TeacherAnnouncementDate.teacher_announcement_id == announcement_id)
        )
    ).all()
    assert [row.announcement_date.isoformat() for row in remaining_dates] == ["2026-05-15"]


@pytest.mark.asyncio
async def test_update_general_with_dates_is_rejected(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    announcement_id = await _create_general(client, auth_headers, teacher_id=TEACHER_PROFILE_ID)

    response = await client.put(
        f"/api/v1/announcements/{announcement_id}",
        headers=auth_headers,
        json={"message": "잘못된 수정", "dates": ["2026-05-09"]},
    )
    assert response.status_code == 422, response.text


@pytest.mark.asyncio
async def test_update_ownership_is_enforced(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id=OTHER_TEACHER_USER_ID, role="teacher", email="other@test.com")

    # other 소유 공지를 default teacher 가 수정 시도 → 403.
    announcement_id = await _create_general(client, _other_teacher_headers(), teacher_id=OTHER_TEACHER_PROFILE_ID)

    response = await client.put(
        f"/api/v1/announcements/{announcement_id}",
        headers=auth_headers,
        json={"message": "남의 공지 수정", "dates": []},
    )
    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_update_missing_announcement_returns_404(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    response = await client.put(
        "/api/v1/announcements/does-not-exist",
        headers=auth_headers,
        json={"message": "없는 공지", "dates": []},
    )
    assert response.status_code == 404, response.text


@pytest.mark.asyncio
async def test_delete_removes_announcement_and_dates(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    announcement_id = await _create_day_off(client, auth_headers, teacher_id=TEACHER_PROFILE_ID, dates=["2026-05-09"])

    response = await client.delete(f"/api/v1/announcements/{announcement_id}", headers=auth_headers)
    assert response.status_code == 204, response.text
    assert response.content == b""

    assert await db_session.get(TeacherAnnouncement, announcement_id) is None
    remaining_dates = (
        await db_session.scalars(
            select(TeacherAnnouncementDate).where(TeacherAnnouncementDate.teacher_announcement_id == announcement_id)
        )
    ).all()
    assert remaining_dates == []


@pytest.mark.asyncio
async def test_delete_ownership_is_enforced(
    client: AsyncClient,
    auth_headers,
    create_test_user,
) -> None:
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    await create_test_user(user_id=OTHER_TEACHER_USER_ID, role="teacher", email="other@test.com")

    announcement_id = await _create_general(client, _other_teacher_headers(), teacher_id=OTHER_TEACHER_PROFILE_ID)

    response = await client.delete(f"/api/v1/announcements/{announcement_id}", headers=auth_headers)
    assert response.status_code == 403, response.text
