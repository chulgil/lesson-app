"""Retention / at-risk analytics contract tests (#1216).

At-risk detection reuses existing signals only:
- absence pattern: ``attendance_scheduler_service`` criterion (14 days, 2+ absences)
- imminent expiry: ``subscription_expiry_service.EXPIRING_THRESHOLD_DAYS`` (D-7)
- practice drop: PracticeLog recent vs prior window

Re-purchase rate follows docs/specs/analytics/event_instrumentation.md §5.2.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from app.services.subscription_expiry_service import compute_today_kst

TEACHER_USER_ID = "test-user-id"
TEACHER_ID = "test-user-id-prof"


def _student(student_id: str, name: str, teacher_id: str = TEACHER_ID):
    from app.models.student import Student

    return Student(id=student_id, teacher_id=teacher_id, name=name, instrument="piano")


def _lesson(student_id: str, day, status, teacher_id: str = TEACHER_ID):
    from app.models.lesson import Lesson

    return Lesson(
        student_id=student_id,
        teacher_id=teacher_id,
        student_name=student_id,
        instrument="piano",
        date=day,
        start_time="10:00",
        duration=60,
        status=status,
    )


def _practice(student_id: str, day, minutes: int):
    from app.models.practice_log import PracticeLog

    return PracticeLog(student_id=student_id, date=day, total_minutes=minutes)


def _subscription(student_id: str, *, end_date, confirmed_at=None, status=None):
    from app.models.subscription import Subscription, SubscriptionStatus

    return Subscription(
        student_id=student_id,
        membership_id="",
        type="monthly",
        total_lessons=4,
        amount=100000,
        start_date=end_date - timedelta(days=30),
        end_date=end_date,
        status=status or SubscriptionStatus.active,
        payment_confirmed=True,
        payment_confirmed_at=confirmed_at,
    )


async def _fetch_retention(client, auth_headers):
    response = await client.get("/api/v1/analytics/retention", headers=auth_headers)
    assert response.status_code == 200, response.text
    return response.json()


@pytest.mark.asyncio
async def test_at_risk_students_derive_from_existing_signals(client, auth_headers, create_test_user, db_session):
    """Each existing signal flags a student; a healthy student is never flagged."""
    from app.models.lesson import LessonStatus

    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    today = compute_today_kst()
    far_expiry = today + timedelta(days=90)

    db_session.add_all(
        [
            _student("risk-absence", "결석학생"),
            _student("risk-expiry", "만료임박학생"),
            _student("risk-practice", "연습급감학생"),
            _student("risk-all", "삼중위험학생"),
            _student("healthy", "건강한학생"),
            _student("other-teacher", "타선생학생", teacher_id="other-teacher-prof"),
        ]
    )
    await db_session.flush()

    lessons = [
        # 2 absences inside the 14-day window -> absence pattern fires.
        _lesson("risk-absence", today - timedelta(days=3), LessonStatus.studentAbsent),
        _lesson("risk-absence", today - timedelta(days=10), LessonStatus.noShow),
        _lesson("risk-all", today - timedelta(days=2), LessonStatus.studentAbsent),
        _lesson("risk-all", today - timedelta(days=9), LessonStatus.studentAbsent),
        # Healthy student attends; a single absence must not trip the 2+ threshold.
        _lesson("healthy", today - timedelta(days=4), LessonStatus.completed),
        _lesson("healthy", today - timedelta(days=11), LessonStatus.studentAbsent),
        _lesson("risk-expiry", today - timedelta(days=5), LessonStatus.completed),
        _lesson("risk-practice", today - timedelta(days=6), LessonStatus.completed),
        # Other teacher's student has an absence pattern but must stay invisible.
        _lesson(
            "other-teacher",
            today - timedelta(days=3),
            LessonStatus.studentAbsent,
            teacher_id="other-teacher-prof",
        ),
        _lesson(
            "other-teacher",
            today - timedelta(days=8),
            LessonStatus.noShow,
            teacher_id="other-teacher-prof",
        ),
    ]
    db_session.add_all(lessons)

    practice = []
    # Stable practice for everyone except the drop cases.
    for sid in ("risk-absence", "risk-expiry", "healthy"):
        practice.append(_practice(sid, today - timedelta(days=3), 120))
        practice.append(_practice(sid, today - timedelta(days=20), 120))
    # Sharp drop: 200 -> 40 minutes (-80%).
    practice.append(_practice("risk-practice", today - timedelta(days=20), 200))
    practice.append(_practice("risk-practice", today - timedelta(days=3), 40))
    practice.append(_practice("risk-all", today - timedelta(days=20), 200))
    practice.append(_practice("risk-all", today - timedelta(days=3), 40))
    db_session.add_all(practice)

    db_session.add_all(
        [
            _subscription("risk-absence", end_date=far_expiry),
            _subscription("risk-practice", end_date=far_expiry),
            _subscription("healthy", end_date=far_expiry),
            # D-3 -> inside EXPIRING_THRESHOLD_DAYS (7).
            _subscription("risk-expiry", end_date=today + timedelta(days=3)),
            _subscription("risk-all", end_date=today + timedelta(days=1)),
        ]
    )
    await db_session.flush()

    body = await _fetch_retention(client, auth_headers)
    by_id = {item["student_id"]: item for item in body["at_risk_students"]}

    assert set(by_id) == {"risk-absence", "risk-expiry", "risk-practice", "risk-all"}
    assert "healthy" not in by_id
    assert "other-teacher" not in by_id

    # Signal count drives risk level: 3 signals -> high, 1 signal -> low.
    assert by_id["risk-all"]["risk_level"] == "high"
    assert by_id["risk-absence"]["risk_level"] == "low"
    assert by_id["risk-expiry"]["risk_level"] == "low"
    assert by_id["risk-practice"]["risk_level"] == "low"

    assert by_id["risk-expiry"]["days_until_expiry"] == 3
    assert by_id["risk-practice"]["practice_drop_percent"] == pytest.approx(-80.0)
    assert by_id["risk-absence"]["last_lesson_date"] == (today - timedelta(days=3)).isoformat()


@pytest.mark.asyncio
async def test_repurchase_rate_counts_confirmed_payment_within_window(
    client, auth_headers, create_test_user, db_session
):
    """재구매율 = 만료 후 30일 내 입금 확인된 학생 / 만료된 학생 (§5.2)."""
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")
    today = compute_today_kst()

    db_session.add_all([_student("repurchased", "재구매학생"), _student("churned", "이탈학생")])
    await db_session.flush()

    expired_on = today - timedelta(days=90)
    db_session.add_all(
        [
            _subscription("repurchased", end_date=expired_on),
            # Confirmed 10 days after expiry -> inside the 30-day observation window.
            _subscription(
                "repurchased",
                end_date=today + timedelta(days=60),
                confirmed_at=datetime.combine(expired_on + timedelta(days=10), datetime.min.time(), tzinfo=UTC),
            ),
            # Expired and never bought again.
            _subscription("churned", end_date=today - timedelta(days=60)),
        ]
    )
    await db_session.flush()

    body = await _fetch_retention(client, auth_headers)

    assert body["renewal_rate"] == pytest.approx(0.5)
    assert len(body["renewal_trend"]) == 6
    trend_by_month = {row["month"][:7]: row for row in body["renewal_trend"]}
    assert trend_by_month[expired_on.strftime("%Y-%m")]["expired"] == 1
    assert trend_by_month[expired_on.strftime("%Y-%m")]["renewed"] == 1


@pytest.mark.asyncio
async def test_retention_returns_documented_defaults_when_no_data(client, auth_headers, create_test_user, db_session):
    """A teacher with no students gets zeroed aggregates, not a 500."""
    await create_test_user(user_id=TEACHER_USER_ID, role="teacher")

    body = await _fetch_retention(client, auth_headers)

    assert body["at_risk_students"] == []
    assert body["renewal_rate"] == 0.0
    assert body["avg_subscription_months"] == 0.0
    assert len(body["renewal_trend"]) == 6
    assert sum(bucket["count"] for bucket in body["tenure_distribution"]) == 0


@pytest.mark.asyncio
async def test_retention_requires_teacher_authentication(client):
    """Unauthenticated callers cannot read another teacher's retention data."""
    response = await client.get("/api/v1/analytics/retention")

    assert response.status_code in (401, 403)
