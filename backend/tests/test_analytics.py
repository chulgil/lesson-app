"""Analytics API contract tests."""

from __future__ import annotations

from datetime import UTC, date, datetime

import pytest


@pytest.mark.asyncio
async def test_monthly_stats_returns_six_month_lesson_trend_for_frontend_contract(
    client, auth_headers, create_test_user, db_session
):
    """Monthly analytics should expose the six-month trend expected by Flutter."""
    from app.models.lesson import Lesson, LessonStatus
    from app.models.student import Student
    from app.models.subscription import Subscription

    await create_test_user(user_id="test-user-id", role="teacher")

    db_session.add_all(
        [
            Student(
                id="trend-student-001",
                teacher_id="test-user-id-prof",
                name="Trend Student",
                instrument="piano",
            ),
            Student(
                id="trend-other-teacher-student",
                teacher_id="other-teacher-prof",
                name="Other Student",
                instrument="violin",
            ),
        ]
    )
    await db_session.flush()

    db_session.add_all(
        [
            Lesson(
                student_id="trend-student-001",
                teacher_id="test-user-id-prof",
                student_name="Trend Student",
                instrument="piano",
                date=date(2025, 12, 20),
                start_time="10:00",
                duration=60,
                status=LessonStatus.completed,
            ),
            Lesson(
                student_id="trend-student-001",
                teacher_id="test-user-id-prof",
                student_name="Trend Student",
                instrument="piano",
                date=date(2026, 3, 1),
                start_time="10:00",
                duration=60,
                status=LessonStatus.completed,
            ),
            Lesson(
                student_id="trend-student-001",
                teacher_id="test-user-id-prof",
                student_name="Trend Student",
                instrument="piano",
                date=date(2026, 3, 2),
                start_time="10:00",
                duration=60,
                status=LessonStatus.completed,
            ),
            Lesson(
                student_id="trend-student-001",
                teacher_id="test-user-id-prof",
                student_name="Trend Student",
                instrument="piano",
                date=date(2026, 5, 5),
                start_time="10:00",
                duration=60,
                status=LessonStatus.completed,
            ),
            Lesson(
                student_id="trend-student-001",
                teacher_id="test-user-id-prof",
                student_name="Trend Student",
                instrument="piano",
                date=date(2025, 11, 30),
                start_time="10:00",
                duration=60,
                status=LessonStatus.completed,
            ),
            Lesson(
                student_id="trend-other-teacher-student",
                teacher_id="other-teacher-prof",
                student_name="Other Student",
                instrument="violin",
                date=date(2026, 5, 6),
                start_time="10:00",
                duration=60,
                status=LessonStatus.completed,
            ),
        ]
    )
    db_session.add_all(
        [
            Subscription(
                student_id="trend-student-001",
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=100000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 1, 3, tzinfo=UTC),
            ),
            Subscription(
                student_id="trend-student-001",
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=150000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 4, 3, tzinfo=UTC),
            ),
            Subscription(
                student_id="trend-student-001",
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=200000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 5, 3, tzinfo=UTC),
            ),
            Subscription(
                student_id="trend-student-001",
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=90000,
                payment_confirmed=False,
                payment_confirmed_at=datetime(2026, 5, 4, tzinfo=UTC),
            ),
            Subscription(
                student_id="trend-other-teacher-student",
                membership_id="",
                type="monthly",
                total_lessons=4,
                amount=800000,
                payment_confirmed=True,
                payment_confirmed_at=datetime(2026, 5, 5, tzinfo=UTC),
            ),
        ]
    )
    await db_session.flush()

    response = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-05",
        headers=auth_headers,
    )

    assert response.status_code == 200
    assert response.json()["lesson_trend"] == [
        {"month": "2025-12-01T00:00:00", "lesson_count": 1, "revenue": 0},
        {"month": "2026-01-01T00:00:00", "lesson_count": 0, "revenue": 100000},
        {"month": "2026-02-01T00:00:00", "lesson_count": 0, "revenue": 0},
        {"month": "2026-03-01T00:00:00", "lesson_count": 2, "revenue": 0},
        {"month": "2026-04-01T00:00:00", "lesson_count": 0, "revenue": 150000},
        {"month": "2026-05-01T00:00:00", "lesson_count": 1, "revenue": 200000},
    ]


@pytest.mark.asyncio
async def test_monthly_stats_rejects_malformed_month_with_422(
    client, auth_headers, create_test_user
):
    """Malformed month query returns 422, not an opaque 500 (0625 §20 N17)."""
    await create_test_user(user_id="test-user-id", role="teacher")

    bad = await client.get(
        "/api/v1/analytics/monthly-stats?month=abc",
        headers=auth_headers,
    )
    assert bad.status_code == 422

    out_of_range = await client.get(
        "/api/v1/analytics/monthly-stats?month=2026-13",
        headers=auth_headers,
    )
    assert out_of_range.status_code == 422
