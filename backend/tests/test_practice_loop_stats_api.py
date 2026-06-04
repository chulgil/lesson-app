"""Tests for practice loop stats endpoints (#512).

Spec: docs/specs/practice/youtube_loop_practice_spec.md §4/§5.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.practice import PracticeSection
from app.models.practice_loop_stats import PracticeLoopStats
from app.models.student import Student
from app.models.teacher import Teacher

pytestmark = pytest.mark.asyncio

TEACHER_USER_ID = "test-user-id"
TEACHER_PROFILE_ID = f"{TEACHER_USER_ID}-prof"
STUDENT_USER_ID = "test-student-id"


def _teacher_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": TEACHER_USER_ID, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _student_headers() -> dict[str, str]:
    token = create_access_token(data={"sub": STUDENT_USER_ID, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_student(
    db_session: AsyncSession,
    *,
    teacher_id: str = TEACHER_PROFILE_ID,
    with_user: bool = True,
    name: str = "Test Student",
) -> str:
    student_id = f"student-{uuid4()}"
    db_session.add(
        Student(
            id=student_id,
            user_id=STUDENT_USER_ID if with_user else None,
            teacher_id=teacher_id,
            name=name,
        )
    )
    await db_session.flush()
    return student_id


async def _seed_section(
    db_session: AsyncSession,
    *,
    repertoire_id: str | None = None,
    piece_name: str = "Etude No.1",
    section_name: str | None = "1악장",
) -> str:
    section_id = f"section-{uuid4()}"
    db_session.add(
        PracticeSection(
            id=section_id,
            repertoire_id=repertoire_id or f"rep-{uuid4()}",
            piece_name=piece_name,
            section_name=section_name,
            start_measure=1,
            end_measure=8,
        )
    )
    await db_session.flush()
    return section_id


# ---------------------------------------------------------------------------
# Student sync
# ---------------------------------------------------------------------------


async def test_student_sync_upserts_new_rows(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    await create_test_user(user_id=STUDENT_USER_ID, role="student", name="Test Student", email="s@test.com")
    student_id = await _seed_student(db_session)
    section_id = await _seed_section(db_session)
    await db_session.commit()

    now = datetime.now(UTC)
    response = await client.post(
        "/api/v1/students/me/practice-loop-stats/sync",
        headers=_student_headers(),
        json={
            "entries": [
                {
                    "section_id": section_id,
                    "repeat_count": 5,
                    "last_played_at": now.isoformat(),
                }
            ]
        },
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["upserted"] == 1
    assert body["skipped"] == 0
    assert body["rejected"] == 0

    row = await db_session.scalar(select(PracticeLoopStats).where(PracticeLoopStats.section_id == section_id))
    assert row is not None
    assert row.student_id == student_id
    assert row.teacher_id == TEACHER_PROFILE_ID
    assert row.repeat_count == 5


async def test_student_sync_is_idempotent_and_monotonic(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    await create_test_user(user_id=STUDENT_USER_ID, role="student", name="Test Student", email="s@test.com")
    await _seed_student(db_session)
    section_id = await _seed_section(db_session)
    await db_session.commit()

    earlier = datetime.now(UTC) - timedelta(hours=1)
    later = datetime.now(UTC)

    # First sync — 10 reps.
    await client.post(
        "/api/v1/students/me/practice-loop-stats/sync",
        headers=_student_headers(),
        json={
            "entries": [
                {
                    "section_id": section_id,
                    "repeat_count": 10,
                    "last_played_at": later.isoformat(),
                }
            ]
        },
    )

    # Second sync — same payload (replayed offline queue).
    response = await client.post(
        "/api/v1/students/me/practice-loop-stats/sync",
        headers=_student_headers(),
        json={
            "entries": [
                {
                    "section_id": section_id,
                    "repeat_count": 10,
                    "last_played_at": later.isoformat(),
                }
            ]
        },
    )
    assert response.json()["skipped"] == 1

    # Third sync — older payload with lower count. Server must not regress.
    response = await client.post(
        "/api/v1/students/me/practice-loop-stats/sync",
        headers=_student_headers(),
        json={
            "entries": [
                {
                    "section_id": section_id,
                    "repeat_count": 3,
                    "last_played_at": earlier.isoformat(),
                }
            ]
        },
    )
    assert response.json()["skipped"] == 1

    row = await db_session.scalar(select(PracticeLoopStats).where(PracticeLoopStats.section_id == section_id))
    assert row.repeat_count == 10


async def test_student_sync_rejects_unknown_section(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    await create_test_user(user_id=STUDENT_USER_ID, role="student", name="Test Student", email="s@test.com")
    await _seed_student(db_session)
    await db_session.commit()

    response = await client.post(
        "/api/v1/students/me/practice-loop-stats/sync",
        headers=_student_headers(),
        json={
            "entries": [
                {
                    "section_id": "ghost-section-id",
                    "repeat_count": 3,
                    "last_played_at": datetime.now(UTC).isoformat(),
                }
            ]
        },
    )
    assert response.status_code == 200
    assert response.json()["rejected"] == 1


async def test_student_sync_empty_payload(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    await create_test_user(user_id=STUDENT_USER_ID, role="student", name="Test Student", email="s@test.com")
    await _seed_student(db_session)
    await db_session.commit()

    response = await client.post(
        "/api/v1/students/me/practice-loop-stats/sync",
        headers=_student_headers(),
        json={"entries": []},
    )
    assert response.status_code == 200
    body = response.json()
    assert body == {"upserted": 0, "skipped": 0, "rejected": 0}


# ---------------------------------------------------------------------------
# Teacher reads
# ---------------------------------------------------------------------------


async def test_teacher_list_for_student_returns_rows_in_window(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)
    section_a = await _seed_section(db_session, piece_name="Etude A", section_name="1악장")
    section_b = await _seed_section(db_session, piece_name="Etude B", section_name="2악장")

    now = datetime.now(UTC)
    db_session.add_all(
        [
            PracticeLoopStats(
                id=f"loop-{uuid4()}",
                student_id=student_id,
                teacher_id=TEACHER_PROFILE_ID,
                section_id=section_a,
                repeat_count=12,
                last_played_at=now,
            ),
            PracticeLoopStats(
                id=f"loop-{uuid4()}",
                student_id=student_id,
                teacher_id=TEACHER_PROFILE_ID,
                section_id=section_b,
                repeat_count=4,
                last_played_at=now - timedelta(days=2),
            ),
            # Outside weekly window — must be filtered when window=weekly.
            PracticeLoopStats(
                id=f"loop-{uuid4()}",
                student_id=student_id,
                teacher_id=TEACHER_PROFILE_ID,
                section_id=await _seed_section(db_session, piece_name="Old"),
                repeat_count=99,
                last_played_at=now - timedelta(days=20),
            ),
        ]
    )
    await db_session.commit()

    response = await client.get(
        f"/api/v1/teachers/me/practice-loop-stats/students/{student_id}",
        headers=_teacher_headers(),
        params={"window": "weekly"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["student_id"] == student_id
    assert body["window"] == "weekly"
    assert body["total_repeats"] == 16  # 12 + 4
    assert len(body["rows"]) == 2
    # Ordered by repeat_count desc.
    assert body["rows"][0]["section_id"] == section_a
    assert body["rows"][0]["piece_name"] == "Etude A"
    assert body["rows"][0]["section_name"] == "1악장"


async def test_teacher_list_monthly_window_includes_older(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_id = await _seed_student(db_session)
    section = await _seed_section(db_session)

    db_session.add(
        PracticeLoopStats(
            id=f"loop-{uuid4()}",
            student_id=student_id,
            teacher_id=TEACHER_PROFILE_ID,
            section_id=section,
            repeat_count=50,
            last_played_at=datetime.now(UTC) - timedelta(days=20),
        )
    )
    await db_session.commit()

    response = await client.get(
        f"/api/v1/teachers/me/practice-loop-stats/students/{student_id}",
        headers=_teacher_headers(),
        params={"window": "monthly"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_repeats"] == 50
    assert len(body["rows"]) == 1


async def test_teacher_cannot_access_other_teachers_student(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    other_teacher_id = f"other-teacher-{uuid4()}"
    db_session.add(Teacher(id=other_teacher_id, user_id=f"other-user-{uuid4()}", instruments=[]))
    await db_session.flush()
    foreign_student_id = await _seed_student(db_session, teacher_id=other_teacher_id, with_user=False, name="Other")
    await db_session.commit()

    response = await client.get(
        f"/api/v1/teachers/me/practice-loop-stats/students/{foreign_student_id}",
        headers=_teacher_headers(),
    )
    assert response.status_code == 403


async def test_teacher_list_unknown_student_returns_404(
    client: AsyncClient,
    create_test_user,
) -> None:
    await create_test_user()
    response = await client.get(
        "/api/v1/teachers/me/practice-loop-stats/students/ghost-id",
        headers=_teacher_headers(),
    )
    assert response.status_code == 404


async def test_teacher_summary_groups_by_student(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    await create_test_user()
    student_a = await _seed_student(db_session, name="Alice")
    # Second student needs a unique user_id placeholder slot — null is fine.
    student_b_id = f"student-{uuid4()}"
    db_session.add(
        Student(
            id=student_b_id,
            user_id=None,
            teacher_id=TEACHER_PROFILE_ID,
            name="Bob",
        )
    )
    await db_session.flush()
    section_a = await _seed_section(db_session, piece_name="Sonata")
    section_b = await _seed_section(db_session, piece_name="Concerto")

    now = datetime.now(UTC)
    db_session.add_all(
        [
            PracticeLoopStats(
                id=f"loop-{uuid4()}",
                student_id=student_a,
                teacher_id=TEACHER_PROFILE_ID,
                section_id=section_a,
                repeat_count=20,
                last_played_at=now,
            ),
            PracticeLoopStats(
                id=f"loop-{uuid4()}",
                student_id=student_b_id,
                teacher_id=TEACHER_PROFILE_ID,
                section_id=section_b,
                repeat_count=7,
                last_played_at=now - timedelta(days=1),
            ),
        ]
    )
    await db_session.commit()

    response = await client.get(
        "/api/v1/teachers/me/practice-loop-stats/summary",
        headers=_teacher_headers(),
        params={"window": "weekly"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["teacher_id"] == TEACHER_PROFILE_ID
    # Sorted by total_repeats desc.
    assert [s["student_id"] for s in body["students"]] == [student_a, student_b_id]
    assert body["students"][0]["total_repeats"] == 20
    assert body["students"][0]["student_name"] == "Alice"
    assert body["students"][1]["total_repeats"] == 7
