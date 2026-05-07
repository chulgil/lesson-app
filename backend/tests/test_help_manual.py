"""Help manual FAQ API tests."""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_student_help_faqs_include_practice_tool_questions(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
) -> None:
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student@test.com",
    )

    response = await client.get(
        "/api/v1/help/faqs",
        headers=student_auth_headers,
        params={"role": "student"},
    )

    assert response.status_code == 200
    faqs = response.json()
    questions = [faq["question"] for faq in faqs]

    assert any("메트로놈" in question for question in questions)
    assert any("튜너" in question for question in questions)
    assert any("녹음" in question for question in questions)
    assert all(faq["role"] == "student" for faq in faqs)
    assert all("search_keywords" in faq for faq in faqs)
    assert {faq["related_quest_id"] for faq in faqs if faq["related_quest_id"]} >= {
        "student.metronome",
        "student.firstRecording",
    }
    assert all("_" not in faq["related_quest_id"] for faq in faqs if faq["related_quest_id"])


@pytest.mark.asyncio
async def test_help_faqs_are_separated_by_teacher_and_parent_role(
    client: AsyncClient,
    auth_headers: dict[str, str],
    create_test_user,
) -> None:
    await create_test_user(user_id="test-user-id", role="teacher", name="Test Teacher")

    teacher_response = await client.get(
        "/api/v1/help/faqs",
        headers=auth_headers,
        params={"role": "teacher"},
    )
    parent_response = await client.get(
        "/api/v1/help/faqs",
        headers=auth_headers,
        params={"role": "parent"},
    )

    assert teacher_response.status_code == 200
    assert parent_response.status_code == 200

    teacher_faqs = teacher_response.json()
    parent_faqs = parent_response.json()

    assert teacher_faqs
    assert parent_faqs
    assert all(faq["role"] == "teacher" for faq in teacher_faqs)
    assert all(faq["role"] == "parent" for faq in parent_faqs)
    assert {faq["id"] for faq in teacher_faqs}.isdisjoint({faq["id"] for faq in parent_faqs})
    assert any("정기 레슨" in faq["question"] for faq in teacher_faqs)
    assert any("자녀" in faq["question"] for faq in parent_faqs)
    assert {faq["related_quest_id"] for faq in teacher_faqs if faq["related_quest_id"]} >= {
        "teacher.firstLesson",
        "teacher.firstNote",
    }
    assert all("_" not in faq["related_quest_id"] for faq in teacher_faqs if faq["related_quest_id"])


@pytest.mark.asyncio
async def test_help_faq_query_filters_case_insensitive_matches(
    client: AsyncClient,
    student_auth_headers: dict[str, str],
    create_test_user,
) -> None:
    await create_test_user(
        user_id="test-student-id",
        role="student",
        name="Test Student",
        email="student@test.com",
    )

    response = await client.get(
        "/api/v1/help/faqs",
        headers=student_auth_headers,
        params={"role": "student", "query": "메트로놈"},
    )

    assert response.status_code == 200
    faqs = response.json()

    assert faqs
    assert all(
        "메트로놈" in faq["question"]
        or "메트로놈" in faq["answer"]
        or "메트로놈" in faq["search_keywords"]
        for faq in faqs
    )
    assert any(faq["id"] == "student-metronome-open" for faq in faqs)
