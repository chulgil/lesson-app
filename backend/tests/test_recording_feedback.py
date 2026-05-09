"""Recording feedback endpoint tests."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_teacher_creates_and_lists_feedback_for_shared_recording(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """POST/GET recording feedback is scoped to an accessible recording."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-feedback@test.com",
    )

    from app.models.practice import PracticeRecording
    from app.models.relationship import TeacherStudentRelation
    from app.models.student import Student

    recording = PracticeRecording(
        id="feedback-recording-id",
        section_id="section-feedback",
        student_id="student-user-id",
        file_path="recordings/feedback.m4a",
        file_key="recordings/feedback.m4a",
        file_url="https://storage.example/feedback.m4a",
        duration_seconds=90,
    )
    relation = TeacherStudentRelation(
        teacher_id="test-user-id-prof",
        student_id="student-user-id",
        status="active",
        is_app_connected=True,
    )
    db_session.add_all(
        [
            Student(
                id="student-user-id",
                user_id="student-user-id",
                teacher_id="test-user-id-prof",
                name="Student",
                instrument="violin",
            ),
            recording,
            relation,
        ]
    )
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/recordings/feedback-recording-id/feedback",
        headers=auth_headers,
        json={"content": "  활 압력이 안정됐어요.  "},
    )

    assert create_response.status_code == 201
    created = create_response.json()
    assert created["recordingId"] == "feedback-recording-id"
    assert created["teacherId"] == "test-user-id-prof"
    assert created["content"] == "활 압력이 안정됐어요."
    assert created["createdAt"]

    list_response = await client.get(
        "/api/v1/recordings/feedback-recording-id/feedback",
        headers=auth_headers,
    )

    assert list_response.status_code == 200
    assert [item["id"] for item in list_response.json()] == [created["id"]]


@pytest.mark.asyncio
async def test_student_can_list_feedback_on_own_recording(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Students can read teacher feedback attached to their own recording."""
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student-own-feedback@test.com",
    )

    from app.models.practice import PracticeRecording, RecordingFeedback

    recording = PracticeRecording(
        id="student-feedback-recording-id",
        section_id="section-student-feedback",
        student_id="test-student-id",
        file_path="recordings/student-feedback.m4a",
        file_key="recordings/student-feedback.m4a",
        file_url="https://storage.example/student-feedback.m4a",
        duration_seconds=60,
    )
    feedback = RecordingFeedback(
        id="student-visible-feedback-id",
        recording_id="student-feedback-recording-id",
        teacher_id="teacher-profile-id",
        content="템포가 좋아졌어요.",
    )
    db_session.add_all([recording, feedback])
    await db_session.flush()

    token = create_access_token(data={"sub": "test-student-id", "role": "student"})
    response = await client.get(
        "/api/v1/recordings/student-feedback-recording-id/feedback",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200
    assert response.json()[0]["content"] == "템포가 좋아졌어요."


@pytest.mark.asyncio
async def test_teacher_updates_and_deletes_own_recording_feedback(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Only the feedback author can mutate feedback for an accessible recording."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="student-user-id",
        role="student",
        name="Student",
        email="student-mutate-feedback@test.com",
    )

    from app.models.practice import PracticeRecording, RecordingFeedback
    from app.models.relationship import TeacherStudentRelation
    from app.models.student import Student

    recording = PracticeRecording(
        id="mutate-feedback-recording-id",
        section_id="section-mutate-feedback",
        student_id="student-user-id",
        file_path="recordings/mutate-feedback.m4a",
        file_key="recordings/mutate-feedback.m4a",
        file_url="https://storage.example/mutate-feedback.m4a",
        duration_seconds=120,
    )
    feedback = RecordingFeedback(
        id="mutate-feedback-id",
        recording_id="mutate-feedback-recording-id",
        teacher_id="test-user-id-prof",
        content="처음 피드백",
    )
    relation = TeacherStudentRelation(
        teacher_id="test-user-id-prof",
        student_id="student-user-id",
        status="active",
        is_app_connected=True,
    )
    db_session.add_all(
        [
            Student(
                id="student-user-id",
                user_id="student-user-id",
                teacher_id="test-user-id-prof",
                name="Student",
                instrument="violin",
            ),
            recording,
            feedback,
            relation,
        ]
    )
    await db_session.flush()

    update_response = await client.put(
        "/api/v1/recordings/mutate-feedback-recording-id/feedback/mutate-feedback-id",
        headers=auth_headers,
        json={"content": "수정된 피드백"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["content"] == "수정된 피드백"

    delete_response = await client.delete(
        "/api/v1/recordings/mutate-feedback-recording-id/feedback/mutate-feedback-id",
        headers=auth_headers,
    )
    assert delete_response.status_code == 204

    remaining = await db_session.scalar(select(RecordingFeedback).where(RecordingFeedback.id == "mutate-feedback-id"))
    assert remaining is None


@pytest.mark.asyncio
async def test_student_cannot_create_feedback(
    client: AsyncClient,
    create_test_user,
    db_session,
):
    """Recording feedback creation is teacher-only."""
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Student",
        email="student-create-feedback@test.com",
    )

    from app.models.practice import PracticeRecording

    recording = PracticeRecording(
        id="student-create-feedback-recording-id",
        section_id="section-student-create-feedback",
        student_id="test-student-id",
        file_path="recordings/student-create-feedback.m4a",
        file_key="recordings/student-create-feedback.m4a",
        file_url="https://storage.example/student-create-feedback.m4a",
        duration_seconds=60,
    )
    db_session.add(recording)
    await db_session.flush()

    token = create_access_token(data={"sub": "test-student-id", "role": "student"})
    response = await client.post(
        "/api/v1/recordings/student-create-feedback-recording-id/feedback",
        headers={"Authorization": f"Bearer {token}"},
        json={"content": "학생이 쓰면 안 됨"},
    )

    assert response.status_code == 403
