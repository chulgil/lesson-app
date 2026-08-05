"""Tests for the journey sticker catalog endpoint (P3b, doc 46 §5).

Pure computed aggregation — no accrual table. Every test seeds source-of-truth
rows directly (practice_logs, practice_journal_volumes, practice_repertoires/
sections, practice_recordings) and asserts the catalog reflects them.
"""

from datetime import date, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.practice import PracticeRecording, PracticeRepertoire, PracticeSection
from app.models.practice_journal import BoundVolume
from app.models.practice_log import PracticeLog
from app.models.student import Student


def _headers(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


def _add_owned_student(
    db_session: AsyncSession,
    student_id: str,
    teacher_id: str = "test-user-id-prof",
    user_id: str | None = None,
) -> None:
    db_session.add(
        Student(
            id=student_id,
            teacher_id=teacher_id,
            user_id=user_id,
            name="Owned Student",
            instrument="violin",
        )
    )


def _repertoire(student_id: str, repertoire_id: str) -> PracticeRepertoire:
    return PracticeRepertoire(
        id=repertoire_id,
        student_id=student_id,
        name="기본 레퍼토리",
        start_date=date(2026, 1, 1),
    )


@pytest.mark.asyncio
async def test_journey_sticker_catalog_zero_state(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A student with no logs gets a fully computed, all-unachieved catalog."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-1")
    await db_session.flush()

    response = await client.get(
        "/api/v1/gamification/student-1/journey-stickers",
        headers=auth_headers,
    )
    assert response.status_code == 200
    data = response.json()
    assert data["student_id"] == "student-1"
    stickers = data["stickers"]
    assert len(stickers) > 0
    assert all(s["achieved"] is False for s in stickers)
    assert all(s["current"] == 0 for s in stickers)

    keys = {s["key"] for s in stickers}
    assert "practice_minutes_10h" in keys
    assert "practice_days_30" in keys
    assert "journey_first_piece" in keys
    assert "journey_bound_1" in keys
    assert "streak_7" in keys
    assert "growth_recordings_10" in keys


@pytest.mark.asyncio
async def test_practice_minutes_threshold_below_at_above(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Aggregated practice minutes cross the 10h (600min) tier exactly at 600."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-2")
    db_session.add(PracticeLog(student_id="student-2", date=date(2026, 1, 1), total_minutes=599))
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-2/journey-stickers", headers=auth_headers)
    entry = next(s for s in response.json()["stickers"] if s["key"] == "practice_minutes_10h")
    assert entry["current"] == 599
    assert entry["achieved"] is False

    # One more minute crosses the threshold.
    db_session.add(PracticeLog(student_id="student-2", date=date(2026, 1, 2), total_minutes=1))
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-2/journey-stickers", headers=auth_headers)
    entry = next(s for s in response.json()["stickers"] if s["key"] == "practice_minutes_10h")
    assert entry["current"] == 600
    assert entry["achieved"] is True


@pytest.mark.asyncio
async def test_practice_days_counts_distinct_positive_minute_days(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Zero-minute logs (rest days) do not count toward practice_days."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-3")
    db_session.add(PracticeLog(student_id="student-3", date=date(2026, 1, 1), total_minutes=10))
    db_session.add(PracticeLog(student_id="student-3", date=date(2026, 1, 2), total_minutes=0))
    db_session.add(PracticeLog(student_id="student-3", date=date(2026, 1, 3), total_minutes=15))
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-3/journey-stickers", headers=auth_headers)
    entry = next(s for s in response.json()["stickers"] if s["key"] == "practice_days_30")
    assert entry["current"] == 2


@pytest.mark.asyncio
async def test_journey_bound_volumes_counted_and_achieved_at_first(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A single bound volume (제본) satisfies journey_bound_1 and journey_first_piece."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-4")
    db_session.add(_repertoire("student-4", "rep-4"))
    await db_session.flush()
    db_session.add(
        PracticeSection(repertoire_id="rep-4", piece_name="바이올린 협주곡", start_measure=1, end_measure=10)
    )
    db_session.add(
        BoundVolume(
            child_profile_id="student-4",
            piece_id="piece-1",
            piece_name="바이올린 협주곡",
            volume_no=1,
            bound_date=date(2026, 1, 5),
        )
    )
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-4/journey-stickers", headers=auth_headers)
    stickers = {s["key"]: s for s in response.json()["stickers"]}
    assert stickers["journey_bound_1"]["current"] == 1
    assert stickers["journey_bound_1"]["achieved"] is True
    assert stickers["journey_bound_5"]["achieved"] is False
    assert stickers["journey_first_piece"]["current"] == 1
    assert stickers["journey_first_piece"]["achieved"] is True


@pytest.mark.asyncio
async def test_streak_uses_longest_ever_not_current(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """streak_7 stays achieved even after the streak has broken (longest, not current)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-5")
    base = date.today() - timedelta(days=60)
    for i in range(7):
        db_session.add(PracticeLog(student_id="student-5", date=base + timedelta(days=i), total_minutes=10))
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-5/journey-stickers", headers=auth_headers)
    entry = next(s for s in response.json()["stickers"] if s["key"] == "streak_7")
    assert entry["current"] == 7
    assert entry["achieved"] is True


@pytest.mark.asyncio
async def test_growth_recordings_scoped_by_uploader_user_id(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Recordings are matched via Student.user_id (PracticeRecording.student_id stores User.id)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="student-user-6", role="student", email="s6@test.com")
    _add_owned_student(db_session, "student-6", user_id="student-user-6")
    db_session.add(PracticeRecording(section_id="sec-x", student_id="student-user-6", file_path="a.m4a"))
    db_session.add(PracticeRecording(section_id="sec-x", student_id="student-user-6", file_path="b.m4a"))
    # Recording uploaded by someone else must not be counted.
    db_session.add(PracticeRecording(section_id="sec-x", student_id="other-user", file_path="c.m4a"))
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-6/journey-stickers", headers=auth_headers)
    entry = next(s for s in response.json()["stickers"] if s["key"] == "growth_recordings_10")
    assert entry["current"] == 2


@pytest.mark.asyncio
async def test_growth_recordings_zero_when_student_has_no_linked_user(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """A student profile with no linked user account can't have uploaded recordings."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-7", user_id=None)
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-7/journey-stickers", headers=auth_headers)
    entry = next(s for s in response.json()["stickers"] if s["key"] == "growth_recordings_10")
    assert entry["current"] == 0


@pytest.mark.asyncio
async def test_other_students_data_is_not_counted(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Aggregation is strictly scoped to the requested student_id."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-a")
    _add_owned_student(db_session, "student-b")
    db_session.add(PracticeLog(student_id="student-b", date=date(2026, 1, 1), total_minutes=500))
    db_session.add(
        BoundVolume(
            child_profile_id="student-b",
            piece_id="piece-b",
            piece_name="곡b",
            volume_no=1,
            bound_date=date(2026, 1, 1),
        )
    )
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-a/journey-stickers", headers=auth_headers)
    stickers = {s["key"]: s for s in response.json()["stickers"]}
    assert stickers["practice_minutes_10h"]["current"] == 0
    assert stickers["journey_bound_1"]["current"] == 0


@pytest.mark.asyncio
async def test_other_teacher_cannot_read_journey_stickers(
    client: AsyncClient, create_test_user, db_session: AsyncSession
):
    """Ownership scoping matches the existing gamification endpoint (403 for non-owners)."""
    await create_test_user(user_id="test-user-id", role="teacher")
    await create_test_user(user_id="other-teacher-id", role="teacher", email="other-sticker@test.com")
    _add_owned_student(db_session, "owned-sticker-student")
    await db_session.flush()

    response = await client.get(
        "/api/v1/gamification/owned-sticker-student/journey-stickers",
        headers=_headers("other-teacher-id"),
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_journey_stickers_nonexistent_student_returns_404(client: AsyncClient, auth_headers, create_test_user):
    await create_test_user(user_id="test-user-id", role="teacher")

    response = await client.get("/api/v1/gamification/ghost-student/journey-stickers", headers=auth_headers)
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_journey_sticker_response_matches_frontend_contract_keys(
    client: AsyncClient, auth_headers, create_test_user, db_session: AsyncSession
):
    """Consumer-key assertion: FE JourneySticker.fromJson keys must exist on every entry."""
    await create_test_user(user_id="test-user-id", role="teacher")
    _add_owned_student(db_session, "student-contract")
    await db_session.flush()

    response = await client.get("/api/v1/gamification/student-contract/journey-stickers", headers=auth_headers)
    assert response.status_code == 200
    stickers = response.json()["stickers"]
    assert len(stickers) > 0
    required_keys = {"key", "family", "metric", "tier", "target", "current", "achieved", "unit"}
    for sticker in stickers:
        assert required_keys.issubset(sticker.keys())
