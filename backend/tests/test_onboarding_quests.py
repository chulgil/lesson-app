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
    assert {"teacher.profile", "teacher.firstStudent", "teacher.firstLesson"}.issubset(quest_ids)
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
