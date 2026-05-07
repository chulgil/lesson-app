"""Onboarding quest v2 API contract tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_onboarding_progress_and_quests_contract(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """The v2 onboarding spec exposes progress and quest sync endpoints."""
    await create_test_user(user_id="test-user-id", role="teacher")

    progress_response = await client.get("/api/v1/users/me/onboarding-progress", headers=auth_headers)

    assert progress_response.status_code == 200
    progress = progress_response.json()
    assert progress["user_id"] == "test-user-id"
    assert progress["role"] == "teacher"
    assert progress["current_phase"] == "quickStart"
    assert progress["profile_completeness"] == 0
    assert progress["walkthrough_skipped"] is False
    assert progress["completed_quest_count"] == 0
    assert progress["total_required_quests"] >= 3
    assert progress["is_all_required_completed"] is False

    quests_response = await client.get("/api/v1/users/me/quests", headers=auth_headers)
    assert quests_response.status_code == 200
    quests = quests_response.json()["quests"]
    quest_ids = {quest["id"] for quest in quests}
    assert {"teacher.profile", "teacher.firstStudent", "teacher.firstLesson", "teacher.firstNote"}.issubset(
        quest_ids
    )
    assert all("status" in quest for quest in quests)

    complete_response = await client.post(
        "/api/v1/users/me/quests/teacher.profile/complete",
        headers=auth_headers,
    )
    assert complete_response.status_code == 200
    completed = complete_response.json()
    assert completed["completed_quest_count"] == 1
    assert completed["quests"][0]["status"] in {"completed", "pending"}

    patch_response = await client.patch(
        "/api/v1/users/me/onboarding-progress",
        headers=auth_headers,
        json={
            "current_phase": "questBoard",
            "profile_completeness": 80,
            "walkthrough_skipped": True,
            "coach_marks_seen": {"home.questBoard": True},
            "coach_marks_dismissed": {"home.questBoard": False},
        },
    )
    assert patch_response.status_code == 200
    patched = patch_response.json()
    assert patched["current_phase"] == "questBoard"
    assert patched["profile_completeness"] == 80
    assert patched["walkthrough_skipped"] is True
    assert patched["coach_marks_seen"] == {"home.questBoard": True}
    assert patched["coach_marks_dismissed"] == {"home.questBoard": False}


@pytest.mark.asyncio
async def test_onboarding_quest_complete_rejects_unknown_quest(
    client: AsyncClient,
    student_auth_headers,
    create_test_user,
):
    """Quest completion must reject IDs outside the current role's quest catalog."""
    await create_test_user(user_id="test-student-id", role="student", email="student-quest@test.com")

    response = await client.post(
        "/api/v1/users/me/quests/teacher.profile/complete",
        headers=student_auth_headers,
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_teacher_domain_actions_auto_complete_onboarding_quests(
    client: AsyncClient,
    auth_headers,
    create_test_user,
):
    """Backend domain actions advance onboarding quests without frontend mock state."""
    await create_test_user(user_id="test-user-id", role="teacher")

    profile_response = await client.put(
        "/api/v1/teachers/me/profile",
        headers=auth_headers,
        json={"instruments": ["violin"], "introduction": "Lesson teacher"},
    )
    assert profile_response.status_code == 200
    progress_response = await client.get("/api/v1/users/me/onboarding-progress", headers=auth_headers)
    progress = progress_response.json()
    assert _quest_status(progress, "teacher.profile") == "completed"

    student_response = await client.post(
        "/api/v1/teachers/me/students",
        headers=auth_headers,
        json={"name": "Student", "instrument": "violin"},
    )
    assert student_response.status_code == 201
    progress_response = await client.get("/api/v1/users/me/onboarding-progress", headers=auth_headers)
    progress = progress_response.json()
    assert _quest_status(progress, "teacher.firstStudent") == "completed"

    lesson_response = await client.post(
        "/api/v1/lessons",
        headers=auth_headers,
        json={
            "student_id": student_response.json()["id"],
            "instrument": "violin",
            "date": "2026-05-07",
            "start_time": "15:00",
            "duration": 60,
        },
    )
    assert lesson_response.status_code == 201
    progress_response = await client.get("/api/v1/users/me/onboarding-progress", headers=auth_headers)
    progress = progress_response.json()
    assert _quest_status(progress, "teacher.firstLesson") == "completed"
    assert _quest_status(progress, "teacher.firstNote") == "available"
    assert progress["is_all_required_completed"] is False

    feedback_response = await client.put(
        f"/api/v1/lessons/{lesson_response.json()['id']}/feedback",
        headers=auth_headers,
        json={"feedback": "첫 레슨 노트를 남겼습니다."},
    )
    assert feedback_response.status_code == 200

    progress_response = await client.get("/api/v1/users/me/onboarding-progress", headers=auth_headers)
    progress = progress_response.json()
    assert _quest_status(progress, "teacher.firstNote") == "completed"
    assert progress["is_all_required_completed"] is True
    assert progress["current_phase"] == "completed"


def _quest_status(progress: dict, quest_id: str) -> str:
    return next(quest["status"] for quest in progress["quests"] if quest["id"] == quest_id)
