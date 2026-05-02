"""Recording endpoint tests."""

import io

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_upload_recording(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/recordings/upload fails gracefully without object storage."""
    await create_test_user(user_id="test-user-id", role="teacher")

    fake_audio = io.BytesIO(b"\x00" * 1024)
    fake_audio.name = "recording.m4a"

    response = await client.post(
        "/api/v1/recordings/upload",
        headers=auth_headers,
        files={"file": ("recording.m4a", fake_audio, "audio/mp4")},
        data={
            "section_id": "section-001",
            "duration_seconds": "120",
            "bpm": "80",
        },
    )
    # Upload fails because object storage is not configured in test env
    assert response.status_code == 500


@pytest.mark.asyncio
async def test_list_recordings(client: AsyncClient, auth_headers, create_test_user):
    """GET /api/v1/recordings returns empty paginated list."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/recordings", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["items"] == []
    assert data["total"] == 0


@pytest.mark.asyncio
async def test_list_recordings_only_returns_current_users_recordings(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """GET /api/v1/recordings only returns recordings owned by the current user."""
    await create_test_user(user_id="test-user-id", role="student")
    await create_test_user(
        user_id="other-user-id",
        role="student",
        name="Other Student",
        email="other@test.com",
    )

    from app.models.practice import PracticeRecording

    own_recording = PracticeRecording(
        id="own-recording-id",
        section_id="section-001",
        student_id="test-user-id",
        file_path="recordings/own.m4a",
        file_key="recordings/own.m4a",
        file_url="https://storage.example/own.m4a",
        duration_seconds=120,
    )
    other_recording = PracticeRecording(
        id="other-recording-id",
        section_id="section-002",
        student_id="other-user-id",
        file_path="recordings/other.m4a",
        file_key="recordings/other.m4a",
        file_url="https://storage.example/other.m4a",
        duration_seconds=180,
    )
    db_session.add_all([own_recording, other_recording])
    await db_session.flush()

    response = await client.get("/api/v1/recordings", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1
    assert [item["id"] for item in data["items"]] == ["own-recording-id"]


@pytest.mark.asyncio
async def test_other_users_recording_is_not_accessible(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Recording detail, download, delete, and share reject records owned by another user."""
    await create_test_user(user_id="test-user-id", role="student")
    await create_test_user(
        user_id="other-user-id",
        role="student",
        name="Other Student",
        email="other@test.com",
    )

    from app.models.practice import PracticeRecording

    other_recording = PracticeRecording(
        id="other-recording-id",
        section_id="section-002",
        student_id="other-user-id",
        file_path="recordings/other.m4a",
        file_key="recordings/other.m4a",
        file_url="https://storage.example/other.m4a",
        duration_seconds=180,
    )
    db_session.add(other_recording)
    await db_session.flush()

    for method, path in [
        ("GET", "/api/v1/recordings/other-recording-id"),
        ("GET", "/api/v1/recordings/other-recording-id/download"),
        ("POST", "/api/v1/recordings/other-recording-id/share"),
        ("DELETE", "/api/v1/recordings/other-recording-id"),
    ]:
        response = await client.request(method, path, headers=auth_headers)
        assert response.status_code == 404

    still_exists = await db_session.scalar(
        select(PracticeRecording).where(PracticeRecording.id == "other-recording-id")
    )
    assert still_exists is not None


@pytest.mark.asyncio
async def test_connected_teacher_can_access_student_recording(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """A teacher with an active app connection can access a student's shared recording."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-user@test.com",
    )

    from app.models.practice import PracticeRecording
    from app.models.relationship import TeacherStudentRelation

    recording = PracticeRecording(
        id="shared-recording-id",
        section_id="section-003",
        student_id="student-user-id",
        file_path="recordings/shared.m4a",
        file_key="recordings/shared.m4a",
        file_url="https://storage.example/shared.m4a",
        duration_seconds=180,
    )
    relation = TeacherStudentRelation(
        teacher_id="test-user-id-prof",
        student_id="student-user-id",
        status="active",
        is_app_connected=True,
    )
    db_session.add_all([recording, relation])
    await db_session.flush()

    list_response = await client.get("/api/v1/recordings", headers=auth_headers)
    assert list_response.status_code == 200
    assert [item["id"] for item in list_response.json()["items"]] == ["shared-recording-id"]

    detail_response = await client.get(
        "/api/v1/recordings/shared-recording-id",
        headers=auth_headers,
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == "shared-recording-id"


@pytest.mark.asyncio
async def test_inactive_teacher_connection_cannot_access_student_recording(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """A teacher cannot access recordings when the student connection is not active."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-user@test.com",
    )

    from app.models.practice import PracticeRecording
    from app.models.relationship import TeacherStudentRelation

    recording = PracticeRecording(
        id="not-shared-recording-id",
        section_id="section-004",
        student_id="student-user-id",
        file_path="recordings/not-shared.m4a",
        file_key="recordings/not-shared.m4a",
        file_url="https://storage.example/not-shared.m4a",
        duration_seconds=180,
    )
    relation = TeacherStudentRelation(
        teacher_id="test-user-id-prof",
        student_id="student-user-id",
        status="inactive",
        is_app_connected=True,
    )
    db_session.add_all([recording, relation])
    await db_session.flush()

    list_response = await client.get("/api/v1/recordings", headers=auth_headers)
    assert list_response.status_code == 200
    assert list_response.json()["items"] == []

    detail_response = await client.get(
        "/api/v1/recordings/not-shared-recording-id",
        headers=auth_headers,
    )
    assert detail_response.status_code == 404


@pytest.mark.asyncio
async def test_teacher_cannot_access_recording_when_relation_disallows_practice(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """A teacher cannot access recordings when relation-level practice visibility is disabled."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-user@test.com",
    )

    from app.models.practice import PracticeRecording
    from app.models.relationship import TeacherStudentRelation

    db_session.add_all([
        PracticeRecording(
            id="permission-denied-recording-id",
            section_id="section-005",
            student_id="student-user-id",
            file_path="recordings/permission-denied.m4a",
            file_key="recordings/permission-denied.m4a",
            file_url="https://storage.example/permission-denied.m4a",
            duration_seconds=180,
        ),
        TeacherStudentRelation(
            teacher_id="test-user-id-prof",
            student_id="student-user-id",
            status="active",
            is_app_connected=True,
            can_view_practice=False,
        ),
    ])
    await db_session.flush()

    response = await client.get(
        "/api/v1/recordings/permission-denied-recording-id",
        headers=auth_headers,
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_teacher_cannot_access_recording_when_student_disabled_practice_share(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """A teacher cannot access recordings when the student disabled practice sharing for that teacher."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-user@test.com",
    )

    from app.models.practice import PracticeRecording
    from app.models.relationship import TeacherStudentRelation
    from app.models.settings import NotificationSettings

    db_session.add_all([
        PracticeRecording(
            id="share-disabled-recording-id",
            section_id="section-006",
            student_id="student-user-id",
            file_path="recordings/share-disabled.m4a",
            file_key="recordings/share-disabled.m4a",
            file_url="https://storage.example/share-disabled.m4a",
            duration_seconds=180,
        ),
        TeacherStudentRelation(
            teacher_id="test-user-id-prof",
            student_id="student-user-id",
            status="active",
            is_app_connected=True,
        ),
        NotificationSettings(
            user_id="student-user-id",
            target_user_id="test-user-id",
            practice_share_enabled=False,
        ),
    ])
    await db_session.flush()

    response = await client.get(
        "/api/v1/recordings/share-disabled-recording-id",
        headers=auth_headers,
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_parent_can_access_child_recording_when_visibility_allows(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """A linked parent can access child recordings only when teacher visibility allows recordings."""
    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-user@test.com",
    )

    from app.models.parent import Parent, ParentChildRelation, ParentVisibilitySettings
    from app.models.practice import PracticeRecording

    parent = Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", email="parent@test.com")
    db_session.add_all([
        parent,
        ParentChildRelation(parent_id="parent-profile-id", student_id="student-user-id"),
        ParentVisibilitySettings(
            teacher_id="teacher-profile-id",
            student_id="student-user-id",
            can_view_recordings=True,
        ),
        PracticeRecording(
            id="parent-visible-recording-id",
            section_id="section-007",
            student_id="student-user-id",
            file_path="recordings/parent-visible.m4a",
            file_key="recordings/parent-visible.m4a",
            file_url="https://storage.example/parent-visible.m4a",
            duration_seconds=180,
        ),
    ])
    await db_session.flush()

    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }
    response = await client.get(
        "/api/v1/recordings/parent-visible-recording-id",
        headers=parent_headers,
    )

    assert response.status_code == 200
    assert response.json()["id"] == "parent-visible-recording-id"


@pytest.mark.asyncio
async def test_parent_cannot_access_child_recording_when_visibility_denies(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """A linked parent cannot access child recordings when can_view_recordings is false by default."""
    await create_test_user(user_id="parent-user-id", role="parent", name="Parent", email="parent@test.com")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-user@test.com",
    )

    from app.models.parent import Parent, ParentChildRelation, ParentVisibilitySettings
    from app.models.practice import PracticeRecording

    db_session.add_all([
        Parent(id="parent-profile-id", user_id="parent-user-id", name="Parent", email="parent@test.com"),
        ParentChildRelation(parent_id="parent-profile-id", student_id="student-user-id"),
        ParentVisibilitySettings(
            teacher_id="teacher-profile-id",
            student_id="student-user-id",
            can_view_recordings=False,
        ),
        PracticeRecording(
            id="parent-hidden-recording-id",
            section_id="section-008",
            student_id="student-user-id",
            file_path="recordings/parent-hidden.m4a",
            file_key="recordings/parent-hidden.m4a",
            file_url="https://storage.example/parent-hidden.m4a",
            duration_seconds=180,
        ),
    ])
    await db_session.flush()

    parent_headers = {
        "Authorization": f"Bearer {create_access_token(data={'sub': 'parent-user-id', 'role': 'parent'})}"
    }
    response = await client.get(
        "/api/v1/recordings/parent-hidden-recording-id",
        headers=parent_headers,
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_upload_recording_saves_owner_and_storage_key(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    monkeypatch,
    db_session,
):
    """Successful uploads persist the current user as owner and keep the object storage key."""
    await create_test_user(user_id="test-user-id", role="student")

    async def fake_upload_to_storage(self, file_key, file):
        return f"https://storage.example/{file_key}"

    monkeypatch.setattr(
        "app.services.recording_service.RecordingService._upload_to_storage",
        fake_upload_to_storage,
    )

    fake_audio = io.BytesIO(b"\x00" * 1024)
    response = await client.post(
        "/api/v1/recordings/upload",
        headers=auth_headers,
        files={"file": ("recording.m4a", fake_audio, "audio/mp4")},
        data={
            "section_id": "section-001",
            "duration_seconds": "120",
            "bpm": "80",
        },
    )

    assert response.status_code == 201

    from app.models.practice import PracticeRecording

    recording = await db_session.scalar(
        select(PracticeRecording).where(PracticeRecording.section_id == "section-001")
    )
    assert recording is not None
    assert recording.student_id == "test-user-id"
    assert recording.file_key.startswith("recordings/")
    assert recording.file_path == recording.file_key


@pytest.mark.asyncio
async def test_share_recording(client: AsyncClient, auth_headers, create_test_user):
    """POST /api/v1/recordings/{id}/share returns 404 for non-existent recording."""
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.post(
        "/api/v1/recordings/some-recording-id/share",
        headers=auth_headers,
    )
    assert response.status_code == 404
