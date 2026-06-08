"""Phase 23 — parent spec compliance regression tests.

spec parent_system.md §3 (invite code 410 Gone), §12.7 (notification 4 카테고리),
announcement_service parent_id resolution fix.
"""

from datetime import UTC, datetime, timedelta

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_parent_notification_settings_includes_4_new_categories(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """spec §12.7 — 수강권 잔여/만료/등록완료/장소 변경 4 카테고리."""
    from app.models.parent import Parent

    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )
    db_session.add(Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"))
    await db_session.flush()

    response = await client.get(
        "/api/v1/parents/notification-settings?parent_id=parent-profile-id",
        headers=_headers("parent-user-id", "parent"),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    for field in (
        "subscription_low_remaining",
        "subscription_expiring_soon",
        "subscription_registered",
        "lesson_location_change",
    ):
        assert field in body, f"missing field: {field}"
        assert body[field] is True


@pytest.mark.asyncio
async def test_parent_notification_settings_can_update_new_categories(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """4 새 카테고리는 update 로 토글 가능."""
    from app.models.parent import Parent

    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )
    db_session.add(Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"))
    await db_session.flush()

    response = await client.put(
        "/api/v1/parents/notification-settings",
        headers=_headers("parent-user-id", "parent"),
        json={
            "parent_id": "parent-profile-id",
            "subscription_low_remaining": False,
            "lesson_location_change": False,
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["subscription_low_remaining"] is False
    assert body["lesson_location_change"] is False
    # 토글하지 않은 새 필드는 그대로 True 유지.
    assert body["subscription_expiring_soon"] is True
    assert body["subscription_registered"] is True


@pytest.mark.asyncio
async def test_connect_child_with_expired_invite_returns_410(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """spec §3 — expired invite code 는 410 Gone, not-found 는 404."""
    from app.models.parent import Parent, ParentInvitation

    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            ParentInvitation(
                id="invite-expired",
                invitation_code="EXPIRED-CODE",
                student_id="any-student",
                source="teacher",
                parent_phone="01000000000",
                expires_at=datetime.now(UTC) - timedelta(days=1),
            ),
        ]
    )
    await db_session.flush()

    response = await client.post(
        "/api/v1/parents/me/children",
        headers=_headers("parent-user-id", "parent"),
        json={"invite_code": "EXPIRED-CODE"},
    )

    assert response.status_code == 410, response.text


@pytest.mark.asyncio
async def test_connect_child_with_unknown_invite_returns_404(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """unknown invite code 는 404 유지 (regression)."""
    from app.models.parent import Parent

    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )
    db_session.add(Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"))
    await db_session.flush()

    response = await client.post(
        "/api/v1/parents/me/children",
        headers=_headers("parent-user-id", "parent"),
        json={"invite_code": "UNKNOWN-CODE"},
    )

    assert response.status_code == 404, response.text


@pytest.mark.asyncio
async def test_parent_sees_announcements_targeting_children_teachers(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Phase 22 leftover bug regression — Parent.id ↔ User.id 혼동 fix."""
    from app.models.parent import Parent, ParentChildRelation
    from app.models.relationship import TeacherStudentRelation
    from app.models.student import Student
    from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementType

    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )
    await create_test_user(
        user_id="teacher-user-id",
        role="teacher",
        name="Teacher",
        email="t@test.com",
    )
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            Student(id="child-001", teacher_id="teacher-user-id-prof", name="Child", instrument="violin"),
            ParentChildRelation(parent_id="parent-profile-id", student_id="child-001"),
            TeacherStudentRelation(
                id="rel-1",
                teacher_id="teacher-user-id-prof",
                student_id="child-001",
                status="active",
            ),
            TeacherAnnouncement(
                id="anc-1",
                teacher_id="teacher-user-id-prof",
                type=TeacherAnnouncementType.general,
                message="hello",
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/announcements/visible",
        headers=_headers("parent-user-id", "parent"),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert any(item.get("id") == "anc-1" for item in body), (
        f"Parent should see child's teacher announcement, got: {body}"
    )
