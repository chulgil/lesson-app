"""Parent API alignment tests for frontend/spec endpoints."""

import pytest
from httpx import AsyncClient

from app.core.security import create_access_token


def _headers(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_parent_crud_and_relations_match_frontend_contract(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Teachers can query parent relations in the shape used by RemoteParentRepository."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student@test.com",
    )
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )

    from app.models.parent import Parent, ParentChildRelation

    parent = Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", phone="01012345678")
    relation = ParentChildRelation(
        id="relation-id",
        parent_id="parent-profile-id",
        student_id="student-user-id",
        is_primary_guardian=True,
        is_billing_target=True,
        status="active",
    )
    db_session.add_all([parent, relation])
    await db_session.flush()

    list_response = await client.get("/api/v1/parents", headers=auth_headers)
    assert list_response.status_code == 200
    assert list_response.json()["items"][0]["id"] == "parent-profile-id"

    detail_response = await client.get("/api/v1/parents/parent-profile-id", headers=auth_headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["user_id"] == "parent-user-id"

    relations_response = await client.get(
        "/api/v1/parents/relations",
        headers=auth_headers,
        params={"student_id": "student-user-id"},
    )
    assert relations_response.status_code == 200
    assert relations_response.json()["items"] == [
        {
            "id": "relation-id",
            "parent_id": "parent-profile-id",
            "student_id": "student-user-id",
            "is_primary_guardian": True,
            "is_billing_target": True,
            "status": "active",
            "linked_at": relations_response.json()["items"][0]["linked_at"],
            "unlinked_at": None,
        }
    ]

    update_response = await client.put(
        "/api/v1/parents/relations/relation-id",
        headers=auth_headers,
        json={
            "parent_id": "parent-profile-id",
            "student_id": "student-user-id",
            "is_primary_guardian": False,
            "is_billing_target": False,
            "status": "inactive",
        },
    )
    assert update_response.status_code == 200
    assert update_response.json()["is_primary_guardian"] is False
    assert update_response.json()["is_billing_target"] is False
    assert update_response.json()["status"] == "inactive"
    assert update_response.json()["unlinked_at"] is not None

    billing_response = await client.get(
        "/api/v1/parents/billing-target",
        headers=auth_headers,
        params={"student_id": "student-user-id"},
    )
    assert billing_response.status_code == 404


@pytest.mark.asyncio
async def test_parent_relations_are_scoped_to_teacher_and_linked_parent(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Other teachers and unlinked parents cannot list a student's parent relations."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-parent-rel-teacher@test.com")
    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent-rel@test.com")
    await create_test_user(
        user_id="other-parent-user-id",
        role="parent",
        name="Other Parent",
        email="other-parent-rel@test.com",
    )

    from app.models.parent import Parent, ParentChildRelation
    from app.models.student import Student

    db_session.add_all(
        [
            Student(
                id="owned-student",
                teacher_id="test-user-id-prof",
                name="Owned Student",
                instrument="violin",
            ),
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", status="active"),
            Parent(id="other-parent-profile-id", user_id="other-parent-user-id", name="Other Parent", status="active"),
            ParentChildRelation(
                id="owned-relation-id",
                parent_id="parent-profile-id",
                student_id="owned-student",
                status="active",
            ),
        ]
    )
    await db_session.flush()

    owner_response = await client.get(
        "/api/v1/parents/relations",
        headers=auth_headers,
        params={"student_id": "owned-student"},
    )
    other_teacher_response = await client.get(
        "/api/v1/parents/relations",
        headers=_headers("other-teacher-id", "teacher"),
        params={"student_id": "owned-student"},
    )
    linked_parent_response = await client.get(
        "/api/v1/parents/relations",
        headers=_headers("parent-user-id", "parent"),
        params={"student_id": "owned-student"},
    )
    other_parent_response = await client.get(
        "/api/v1/parents/relations",
        headers=_headers("other-parent-user-id", "parent"),
        params={"student_id": "owned-student"},
    )

    assert owner_response.status_code == 200
    assert [item["id"] for item in owner_response.json()["items"]] == ["owned-relation-id"]
    assert other_teacher_response.status_code == 403
    assert linked_parent_response.status_code == 200
    assert other_parent_response.status_code == 403


@pytest.mark.asyncio
async def test_parent_invitation_endpoints_match_frontend_contract(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Parent invitation endpoints support create, lookup, pending list, and mark-used."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student@test.com",
    )

    create_response = await client.post(
        "/api/v1/parents/invitations",
        headers=auth_headers,
        json={
            "student_id": "student-user-id",
            "teacher_id": "test-user-id-prof",
            "source": "teacher",
            "parent_phone": "01012345678",
            "parent_email": "parent@test.com",
        },
    )
    assert create_response.status_code == 201
    invitation = create_response.json()
    assert invitation["student_id"] == "student-user-id"
    assert invitation["teacher_id"] == "test-user-id-prof"
    assert invitation["source"] == "teacher"
    assert invitation["is_used"] is False
    assert invitation["invitation_code"]

    lookup_response = await client.get(
        "/api/v1/parents/invitations",
        headers=auth_headers,
        params={"code": invitation["invitation_code"]},
    )
    assert lookup_response.status_code == 200
    assert lookup_response.json()["id"] == invitation["id"]

    pending_response = await client.get(
        "/api/v1/parents/invitations",
        headers=auth_headers,
        params={"student_id": "student-user-id", "status": "pending"},
    )
    assert pending_response.status_code == 200
    assert [item["id"] for item in pending_response.json()["items"]] == [invitation["id"]]

    used_response = await client.patch(
        f"/api/v1/parents/invitations/{invitation['id']}/use",
        headers=auth_headers,
    )
    assert used_response.status_code == 200
    assert used_response.json()["is_used"] is True


@pytest.mark.asyncio
async def test_parent_notification_settings_endpoint_uses_spec_defaults_and_permissions(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Parents can manage their notification settings through /parents/notification-settings."""
    await create_test_user(
        user_id="parent-user-id",
        role="parent",
        name="Parent",
        email="parent@test.com",
    )
    await create_test_user(
        user_id="other-parent-user-id",
        role="parent",
        name="Other Parent",
        email="other-parent@test.com",
    )

    from app.models.parent import Parent

    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent"),
            Parent(id="other-parent-profile-id", user_id="other-parent-user-id", name="Other Parent"),
        ]
    )
    await db_session.flush()

    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }
    get_response = await client.get(
        "/api/v1/parents/notification-settings",
        headers=parent_headers,
        params={"parent_id": "parent-profile-id"},
    )
    assert get_response.status_code == 200
    defaults = get_response.json()
    assert defaults["payment_request"] is True
    assert defaults["payment_complete"] is True
    assert defaults["lesson_start"] is False
    assert defaults["lesson_end"] is False
    assert defaults["practice_complete"] is False
    assert defaults["streak_achievement"] is False
    assert defaults["lesson_note_update"] is False

    save_response = await client.put(
        "/api/v1/parents/notification-settings",
        headers=parent_headers,
        json={
            "parent_id": "parent-profile-id",
            "payment_request": False,
            "payment_complete": False,
            "practice_complete": True,
            "lesson_start": True,
        },
    )
    assert save_response.status_code == 200
    saved = save_response.json()
    assert saved["payment_request"] is True
    assert saved["payment_complete"] is True
    assert saved["practice_complete"] is True
    assert saved["lesson_start"] is True

    forbidden_response = await client.get(
        "/api/v1/parents/notification-settings",
        headers=parent_headers,
        params={"parent_id": "other-parent-profile-id"},
    )
    assert forbidden_response.status_code == 403
