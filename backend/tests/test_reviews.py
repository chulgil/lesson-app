"""Tests for teacher review endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_review(client: AsyncClient, student_auth_headers, create_test_user):
    """POST /reviews/ should create a review."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    response = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={
            "teacher_id": "test-user-id",
            "rating": 5,
            "content": "최고의 선생님!",
            "tags": ["친절", "전문적"],
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["rating"] == 5
    assert data["content"] == "최고의 선생님!"
    assert data["author_type"] == "student"
    assert data["is_active"] is True


@pytest.mark.asyncio
async def test_list_reviews(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """GET /reviews/{teacher_id} should list active reviews."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "rating": 4},
    )

    response = await client.get("/api/v1/reviews/test-user-id", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 1


@pytest.mark.asyncio
async def test_get_review_summary(client: AsyncClient, auth_headers, student_auth_headers, create_test_user):
    """GET /reviews/{teacher_id}/summary should return aggregate stats."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "rating": 5},
    )
    await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "rating": 3},
    )

    response = await client.get("/api/v1/reviews/test-user-id/summary", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total_reviews"] == 2
    assert data["average_rating"] == 4.0
    assert data["student_reviews"] == 2


@pytest.mark.asyncio
async def test_update_review(client: AsyncClient, student_auth_headers, create_test_user):
    """PUT /reviews/{id} should update rating and content."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    cr = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "teacher-1", "rating": 3},
    )
    review_id = cr.json()["id"]

    response = await client.put(
        f"/api/v1/reviews/{review_id}",
        headers=student_auth_headers,
        json={"rating": 5, "content": "수정된 리뷰"},
    )
    assert response.status_code == 200
    assert response.json()["rating"] == 5
    assert response.json()["content"] == "수정된 리뷰"


@pytest.mark.asyncio
async def test_delete_review_soft(client: AsyncClient, student_auth_headers, auth_headers, create_test_user):
    """DELETE /reviews/{id} should soft-delete (is_active=false)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    cr = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "rating": 4},
    )
    review_id = cr.json()["id"]

    response = await client.delete(f"/api/v1/reviews/{review_id}", headers=student_auth_headers)
    assert response.status_code == 204

    # Should not appear in active list
    list_resp = await client.get("/api/v1/reviews/test-user-id", headers=auth_headers)
    assert list_resp.json()["total"] == 0


@pytest.mark.asyncio
async def test_review_rating_boundary_min(client: AsyncClient, student_auth_headers, create_test_user):
    """Rating=1 (minimum) should be accepted."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    response = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "t1", "rating": 1},
    )
    assert response.status_code == 201
    assert response.json()["rating"] == 1


@pytest.mark.asyncio
async def test_review_rating_boundary_max(client: AsyncClient, student_auth_headers, create_test_user):
    """Rating=5 (maximum) should be accepted."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    response = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "t1", "rating": 5},
    )
    assert response.status_code == 201


@pytest.mark.asyncio
async def test_review_rating_out_of_range(client: AsyncClient, student_auth_headers, create_test_user):
    """Rating=0 or rating=6 should be rejected by validation."""
    await create_test_user(user_id="test-student-id", role="student", email="student@test.com", name="Student")

    r0 = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "t1", "rating": 0},
    )
    assert r0.status_code == 422

    r6 = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "t1", "rating": 6},
    )
    assert r6.status_code == 422


@pytest.mark.asyncio
async def test_review_is_verified_when_reviewer_completed_a_lesson(
    client: AsyncClient, student_auth_headers, create_test_user, db_session
):
    """A review from a student who actually completed a lesson with the
    teacher should be marked is_verified=True — the field existed on the
    model/schema but was never set anywhere.
    """
    from datetime import date

    from app.models.lesson import Lesson, LessonStatus

    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="test-student-id", role="student", email="student-verified@test.com", name="Student")

    db_session.add(
        Lesson(
            teacher_id="test-user-id-prof",
            student_id="test-student-id",
            student_name="Student",
            instrument="violin",
            date=date(2026, 5, 1),
            start_time="10:00",
            duration=60,
            status=LessonStatus.completed,
        )
    )
    await db_session.flush()
    await db_session.commit()

    response = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "rating": 5, "content": "실제로 배운 선생님"},
    )
    assert response.status_code == 201
    assert response.json()["is_verified"] is True


@pytest.mark.asyncio
async def test_review_is_not_verified_without_a_completed_lesson(
    client: AsyncClient, student_auth_headers, create_test_user
):
    """A review from someone who never had a lesson with the teacher must not
    be marked verified."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(
        user_id="test-student-id", role="student", email="student-unverified@test.com", name="Student"
    )

    response = await client.post(
        "/api/v1/reviews/",
        headers=student_auth_headers,
        json={"teacher_id": "test-user-id", "rating": 5, "content": "레슨 받아본 적 없음"},
    )
    assert response.status_code == 201
    assert response.json()["is_verified"] is False
