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

    from app.models.parent import Parent, ParentChildRelation, ParentTeacherConnection

    parent = Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", phone="01012345678")
    relation = ParentChildRelation(
        id="relation-id",
        parent_id="parent-profile-id",
        student_id="student-user-id",
        is_primary_guardian=True,
        is_billing_target=True,
        status="active",
    )
    # IDOR fix (#461): teacher↔parent access now requires a connection row.
    connection = ParentTeacherConnection(
        id="ptc-id",
        parent_id="parent-profile-id",
        teacher_id="test-user-id-prof",
        student_id="student-user-id",
    )
    db_session.add_all([parent, relation, connection])
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
async def test_parent_invitation_lists_are_scoped_to_actor(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Invitation list endpoints do not expose other teachers' invitations."""
    from datetime import UTC, datetime, timedelta

    from app.models.parent import ParentInvitation
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-invite-teacher@test.com")
    await create_test_user(user_id="student-user-id", role="student", name="Student", email="student-invite@test.com")
    db_session.add_all(
        [
            Student(
                id="student-user-id",
                user_id="student-user-id",
                teacher_id="test-user-id-prof",
                name="Student",
                instrument="violin",
            ),
            ParentInvitation(
                id="owner-invitation",
                student_id="student-user-id",
                teacher_id="test-user-id-prof",
                source="teacher",
                parent_phone="01011112222",
                invitation_code="OWNER-CODE",
                expires_at=datetime.now(UTC) + timedelta(days=7),
            ),
            ParentInvitation(
                id="other-invitation",
                student_id="other-student-id",
                teacher_id="other-teacher-id-prof",
                source="teacher",
                parent_phone="01033334444",
                invitation_code="OTHER-CODE",
                expires_at=datetime.now(UTC) + timedelta(days=7),
            ),
        ]
    )
    await db_session.flush()

    owner_list = await client.get("/api/v1/parents/invitations", headers=auth_headers)
    other_teacher_filtered = await client.get(
        "/api/v1/parents/invitations",
        headers=_headers("other-teacher-id", "teacher"),
        params={"student_id": "student-user-id"},
    )
    student_list = await client.get(
        "/api/v1/parents/invitations",
        headers=_headers("student-user-id", "student"),
    )

    assert owner_list.status_code == 200
    assert [item["id"] for item in owner_list.json()["items"]] == ["owner-invitation"]
    assert other_teacher_filtered.status_code == 403
    assert student_list.status_code == 200
    assert [item["id"] for item in student_list.json()["items"]] == ["owner-invitation"]


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


@pytest.mark.asyncio
async def test_get_parent_is_scoped_to_connected_teacher(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """IDOR #461: only a teacher with a connection (or the parent) can read parent PII."""
    from app.models.parent import Parent, ParentTeacherConnection

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-get-parent@test.com")
    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent-get@test.com")

    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", phone="01099998888"),
            ParentTeacherConnection(
                id="ptc-connected",
                parent_id="parent-profile-id",
                teacher_id="test-user-id-prof",
            ),
        ]
    )
    await db_session.flush()

    # Connected teacher can read.
    connected = await client.get("/api/v1/parents/parent-profile-id", headers=auth_headers)
    assert connected.status_code == 200
    assert connected.json()["phone"] == "01099998888"

    # The parent themselves can read.
    self_view = await client.get(
        "/api/v1/parents/parent-profile-id",
        headers=_headers("parent-user-id", "parent"),
    )
    assert self_view.status_code == 200

    # Unlinked teacher is blocked from the parent's PII.
    unlinked = await client.get(
        "/api/v1/parents/parent-profile-id",
        headers=_headers("other-teacher-id", "teacher"),
    )
    assert unlinked.status_code == 403


@pytest.mark.asyncio
async def test_invitation_code_lookup_and_mark_used_are_scoped_to_owner(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """IDOR #461: only the owning teacher can look up by code or mark an invitation used."""
    from datetime import UTC, datetime, timedelta

    from app.models.parent import ParentInvitation

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-invite-scope@test.com")

    db_session.add(
        ParentInvitation(
            id="scoped-invitation",
            student_id="student-user-id",
            teacher_id="test-user-id-prof",
            source="teacher",
            parent_phone="01055556666",
            parent_email="invitee@test.com",
            invitation_code="SCOPED-CODE",
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
    )
    await db_session.flush()

    other_headers = _headers("other-teacher-id", "teacher")

    # Unlinked teacher cannot fetch the invitation (and its PII) by code.
    unlinked_lookup = await client.get(
        "/api/v1/parents/invitations",
        headers=other_headers,
        params={"code": "SCOPED-CODE"},
    )
    assert unlinked_lookup.status_code == 403

    # Unlinked teacher cannot burn the invitation.
    unlinked_use = await client.patch(
        "/api/v1/parents/invitations/scoped-invitation/use",
        headers=other_headers,
    )
    assert unlinked_use.status_code == 403

    # Owning teacher can still look up and mark used.
    owner_lookup = await client.get(
        "/api/v1/parents/invitations",
        headers=auth_headers,
        params={"code": "SCOPED-CODE"},
    )
    assert owner_lookup.status_code == 200
    assert owner_lookup.json()["id"] == "scoped-invitation"

    owner_use = await client.patch(
        "/api/v1/parents/invitations/scoped-invitation/use",
        headers=auth_headers,
    )
    assert owner_use.status_code == 200
    assert owner_use.json()["is_used"] is True
