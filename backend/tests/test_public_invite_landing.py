"""Public invite landing API tests for Ghost-rendered student install pages."""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.invite import Invite, InviteStatus, InviteUserRole
from app.models.teacher import Teacher
from app.models.user import User


async def _create_invite(
    db_session: AsyncSession,
    *,
    code: str = "PIANO7X",
    status: InviteStatus = InviteStatus.active,
    expires_at: datetime | None = None,
    use_count: int = 0,
    max_uses: int | None = None,
) -> Invite:
    invite = Invite(
        creator_id="test-user-id",
        creator_name="홍길동",
        creator_role=InviteUserRole.teacher,
        invite_code=code,
        invite_url=f"lessonapp://invite/{code}",
        qr_code_data=f"lessonapp://invite/{code}",
        status=status,
        max_uses=max_uses,
        use_count=use_count,
        note="내부 초대 메모는 공개되면 안 됩니다",
        expires_at=expires_at or datetime.now(UTC) + timedelta(days=7),
    )
    db_session.add(invite)
    await db_session.flush()
    return invite


@pytest.mark.asyncio
async def test_public_invite_landing_returns_minimal_teacher_share_contract_without_auth(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher: User = await create_test_user(
        user_id="test-user-id",
        role="teacher",
        name="홍길동",
        email="private-teacher@example.com",
    )
    teacher.phone = "010-1111-2222"
    teacher.profile_image_url = "https://cdn.lessonaza.com/profile.png"
    teacher_profile = await db_session.scalar(select(Teacher).where(Teacher.user_id == teacher.id))
    assert teacher_profile is not None
    teacher_profile.instruments = ["피아노", "작곡"]
    await _create_invite(db_session)
    await db_session.flush()

    response = await client.get("/api/v1/public/invites/PIANO7X/landing")

    assert response.status_code == 200
    data = response.json()
    assert data["code"] == "PIANO7X"
    assert data["status"] == "active"
    assert data["teacher"] == {
        "id": "test-user-id",
        "name": "홍길동",
        "instrument": "피아노",
        "profile_image_url": "https://cdn.lessonaza.com/profile.png",
    }
    assert data["share"]["title"] == "홍길동 선생님의 레슨앱 초대"
    assert data["share"]["description"] == "피아노 레슨 기록과 숙제를 함께 확인해요"
    assert data["share"]["url"] == "https://lessonaza.com/invite/PIANO7X"
    assert data["share"]["app_deep_link"] == "lessonapp://invite/PIANO7X"

    serialized = response.text
    assert "private-teacher@example.com" not in serialized
    assert "010-1111-2222" not in serialized
    assert "내부 초대 메모" not in serialized
    assert "payment" not in serialized.lower()


@pytest.mark.asyncio
async def test_public_invite_landing_unknown_code_returns_404(client: AsyncClient) -> None:
    response = await client.get("/api/v1/public/invites/NOPE/landing")

    assert response.status_code == 404


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("invite_status", "expires_at", "use_count", "max_uses"),
    [
        (InviteStatus.revoked, None, 0, None),
        (InviteStatus.used, None, 0, None),
        (InviteStatus.active, datetime.now(UTC) - timedelta(minutes=1), 0, None),
        (InviteStatus.active, None, 3, 3),
    ],
)
async def test_public_invite_landing_unusable_invites_return_410(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
    invite_status: InviteStatus,
    expires_at: datetime | None,
    use_count: int,
    max_uses: int | None,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="홍길동")
    await _create_invite(
        db_session,
        status=invite_status,
        expires_at=expires_at,
        use_count=use_count,
        max_uses=max_uses,
    )
    await db_session.flush()

    response = await client.get("/api/v1/public/invites/piano7x/landing")

    assert response.status_code == 410
