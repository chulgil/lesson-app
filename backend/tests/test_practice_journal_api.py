"""Practice journal endpoint tests (#872).

Coverage:
  - Mark upsert (student-self, monotonic upgrade, IDOR 403)
  - Guardian seal (active PCR, idempotent, stranger 403)
  - Self-endorsement (student-self, ref absent)
  - Teacher endorsement (active TSR + can_view_practice, assignment_ref required)
  - Ledger GET (student-self | guardian | teacher read access)
  - Volume list + bind (student-self, idempotent)
  - WIRE CONTRACT: response keys match FE .g.dart fromJson exactly
    (intensity / cheer_note / by / date / piece_name / bound_date),
    and old keys (mark_type / comment / by_type / title) are ABSENT.
"""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.parent import Parent, ParentChildRelation
from app.models.relationship import RelationStatus, TeacherStudentRelation
from app.models.student import Student

pytestmark = pytest.mark.asyncio

# ---------------------------------------------------------------------------
# IDs
# ---------------------------------------------------------------------------
_TEACHER_USER_ID = "pj-teacher-user"
_TEACHER_PROF_ID = "pj-teacher-user-prof"  # auto-created by create_test_user fixture
_STUDENT_USER_ID = "pj-student-user"
_STUDENT_PROF_ID = "pj-student-prof"
_PARENT_USER_ID = "pj-parent-user"
_PARENT_PROF_ID = "pj-parent-prof"
_STRANGER_USER_ID = "pj-stranger-user"


def _hdrs(user_id: str, role: str) -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


def student_hdrs() -> dict[str, str]:
    return _hdrs(_STUDENT_USER_ID, "student")


def teacher_hdrs() -> dict[str, str]:
    return _hdrs(_TEACHER_USER_ID, "teacher")


def parent_hdrs() -> dict[str, str]:
    return _hdrs(_PARENT_USER_ID, "parent")


def stranger_hdrs() -> dict[str, str]:
    return _hdrs(_STRANGER_USER_ID, "student")


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


async def _seed_base(db: AsyncSession, create_test_user) -> None:
    """Seed teacher + student + parent + active relations."""
    await create_test_user(user_id=_TEACHER_USER_ID, role="teacher", name="T", email="t@pj.test")
    await create_test_user(user_id=_STUDENT_USER_ID, role="student", name="S", email="s@pj.test")
    await create_test_user(user_id=_PARENT_USER_ID, role="parent", name="P", email="p@pj.test")
    await create_test_user(user_id=_STRANGER_USER_ID, role="student", name="X", email="x@pj.test")

    db.add_all(
        [
            Student(
                id=_STUDENT_PROF_ID,
                user_id=_STUDENT_USER_ID,
                teacher_id=_TEACHER_PROF_ID,
                name="S",
            ),
            TeacherStudentRelation(
                id=str(uuid4()),
                teacher_id=_TEACHER_PROF_ID,
                student_id=_STUDENT_PROF_ID,
                status=RelationStatus.active,
                can_view_practice=True,
            ),
            Parent(id=_PARENT_PROF_ID, user_id=_PARENT_USER_ID, name="P"),
            ParentChildRelation(
                id=str(uuid4()),
                parent_id=_PARENT_PROF_ID,
                student_id=_STUDENT_PROF_ID,
                status="active",
            ),
        ]
    )
    await db.flush()


# ===========================================================================
# Mark upsert
# ===========================================================================


async def test_student_can_upsert_short_mark(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={
            "child_profile_id": _STUDENT_PROF_ID,
            "date": "2026-06-01",
            "intensity": "short",
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    # WIRE CONTRACT: FE PracticeMark.fromJson reads date + intensity.
    assert data["date"] == "2026-06-01"
    assert data["intensity"] == "short"
    assert "mark_type" not in data  # old key must be gone
    assert "notes" not in data


async def test_mark_monotonic_upgrade_short_to_full(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-01", "intensity": "short"},
    )
    resp = await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-01", "intensity": "full"},
    )
    assert resp.status_code == 200
    assert resp.json()["intensity"] == "full"


async def test_mark_downgrade_is_noop(client: AsyncClient, db_session, create_test_user):
    """full -> short is silently ignored (monotonic)."""
    await _seed_base(db_session, create_test_user)

    await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-01", "intensity": "full"},
    )
    resp = await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-01", "intensity": "short"},
    )
    assert resp.status_code == 200
    assert resp.json()["intensity"] == "full"


async def test_mark_idor_403(client: AsyncClient, db_session, create_test_user):
    """A stranger cannot upsert a mark for another student."""
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/marks",
        headers=stranger_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-01", "intensity": "short"},
    )
    assert resp.status_code == 403


# ===========================================================================
# Guardian seal
# ===========================================================================


async def test_guardian_can_seal_week(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/seals",
        headers=parent_hdrs(),
        json={
            "child_profile_id": _STUDENT_PROF_ID,
            "week_start": "2026-06-04",  # Thursday — normalized to Monday 2026-06-01 by service
            "cheer_note": "잘했어!",
        },
    )
    assert resp.status_code == 200
    data = resp.json()
    # WIRE CONTRACT: FE GuardianSeal.fromJson reads week_start + guardian_user_id + cheer_note.
    assert data["guardian_user_id"] == _PARENT_USER_ID  # stamped from JWT, not body
    assert data["cheer_note"] == "잘했어!"
    assert "comment" not in data  # old key must be gone
    # normalized to Monday (2026-06-04 Thu → 2026-06-01 Mon)
    assert data["week_start"] == "2026-06-01"


async def test_seal_ignores_body_guardian_user_id(client: AsyncClient, db_session, create_test_user):
    """anti-IDOR: a body guardian_user_id is ignored; JWT identity is stamped."""
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/seals",
        headers=parent_hdrs(),
        json={
            "child_profile_id": _STUDENT_PROF_ID,
            "week_start": "2026-06-04",
            "guardian_user_id": "attacker-spoof-id",
        },
    )
    assert resp.status_code == 200
    assert resp.json()["guardian_user_id"] == _PARENT_USER_ID


async def test_seal_is_idempotent(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)
    payload = {"child_profile_id": _STUDENT_PROF_ID, "week_start": "2026-06-02", "cheer_note": "first"}
    r1 = await client.post("/api/v1/practice-journal/seals", headers=parent_hdrs(), json=payload)
    r2 = await client.post("/api/v1/practice-journal/seals", headers=parent_hdrs(), json=payload)
    assert r1.status_code == 200
    assert r2.status_code == 200
    # Same normalized week → same seal (cheer_note from first insert preserved).
    assert r1.json() == r2.json()


async def test_stranger_cannot_seal(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/seals",
        headers=stranger_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "week_start": "2026-06-02"},
    )
    assert resp.status_code == 403


# ===========================================================================
# Endorsement — self
# ===========================================================================


async def test_student_self_endorsement(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/endorsements/self",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "by": "self", "date": "2026-06-12", "note": "혼자 잘함"},
    )
    assert resp.status_code == 201
    data = resp.json()
    # WIRE CONTRACT: FE Endorsement.fromJson reads by + date + author_user_id + assignment_ref + note.
    assert data["by"] == "self"
    assert data["date"] == "2026-06-12"
    assert data["author_user_id"] == _STUDENT_USER_ID  # stamped from JWT
    assert data["assignment_ref"] is None
    assert data["note"] == "혼자 잘함"
    assert "by_type" not in data  # old key must be gone


async def test_self_endorsement_with_assignment_ref_is_422(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/endorsements/self",
        headers=student_hdrs(),
        json={
            "child_profile_id": _STUDENT_PROF_ID,
            "by": "self",
            "date": "2026-06-12",
            "assignment_ref": "piece-123",
            "note": "x",
        },
    )
    assert resp.status_code == 422


# ===========================================================================
# Endorsement — teacher
# ===========================================================================


async def test_teacher_endorsement_requires_assignment_ref(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/endorsements/teacher",
        headers=teacher_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "by": "teacher", "date": "2026-06-12", "note": "x"},
    )
    assert resp.status_code == 422


async def test_teacher_endorsement_ok(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/endorsements/teacher",
        headers=teacher_hdrs(),
        json={
            "child_profile_id": _STUDENT_PROF_ID,
            "by": "teacher",
            "date": "2026-06-12",
            "assignment_ref": "assign_42",
            "note": "Good job",
        },
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["by"] == "teacher"
    assert data["date"] == "2026-06-12"
    assert data["author_user_id"] == _TEACHER_USER_ID  # stamped from JWT
    assert data["assignment_ref"] == "assign_42"
    assert data["note"] == "Good job"


async def test_teacher_without_can_view_practice_is_403(client: AsyncClient, db_session, create_test_user):
    """Teacher exists but can_view_practice=False → 403."""
    await _seed_base(db_session, create_test_user)

    # Add another teacher with view disabled
    # create_test_user(role="teacher") auto-creates Teacher(id=f"{uid}-prof")
    other_teacher_uid = "pj-t2-user"
    other_teacher_pid = "pj-t2-user-prof"
    await create_test_user(user_id=other_teacher_uid, role="teacher", name="T2", email="t2@pj.test")
    db_session.add(
        TeacherStudentRelation(
            id=str(uuid4()),
            teacher_id=other_teacher_pid,
            student_id=_STUDENT_PROF_ID,
            status=RelationStatus.active,
            can_view_practice=False,
        )
    )
    await db_session.flush()

    resp = await client.post(
        "/api/v1/practice-journal/endorsements/teacher",
        headers=_hdrs(other_teacher_uid, "teacher"),
        json={
            "child_profile_id": _STUDENT_PROF_ID,
            "by": "teacher",
            "date": "2026-06-12",
            "assignment_ref": "assign_xyz",
            "note": "hi",
        },
    )
    assert resp.status_code == 403


# ===========================================================================
# Ledger GET — access control
# ===========================================================================


async def test_student_can_read_own_ledger(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.get(
        "/api/v1/practice-journal/ledger",
        headers=student_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID, "year": 2026, "month": 6},
    )
    assert resp.status_code == 200
    data = resp.json()
    # WIRE CONTRACT: FE PracticeLedger.fromJson reads child_profile_id, year, month, marks[], seals[], endorsements[].
    assert data["child_profile_id"] == _STUDENT_PROF_ID
    assert data["year"] == 2026
    assert data["month"] == 6
    assert data["marks"] == []
    assert data["seals"] == []
    assert data["endorsements"] == []
    assert "entries" not in data  # old shape must be gone


async def test_guardian_can_read_ledger(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.get(
        "/api/v1/practice-journal/ledger",
        headers=parent_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID, "year": 2026, "month": 6},
    )
    assert resp.status_code == 200


async def test_teacher_can_read_ledger(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.get(
        "/api/v1/practice-journal/ledger",
        headers=teacher_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID, "year": 2026, "month": 6},
    )
    assert resp.status_code == 200


async def test_stranger_cannot_read_ledger(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.get(
        "/api/v1/practice-journal/ledger",
        headers=stranger_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID, "year": 2026, "month": 6},
    )
    assert resp.status_code == 403


async def test_ledger_includes_marks_and_seals(client: AsyncClient, db_session, create_test_user):
    """End-to-end: mark + seal + endorsement show up in the ledger lists with FE keys."""
    await _seed_base(db_session, create_test_user)

    await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-10", "intensity": "full"},
    )
    await client.post(
        "/api/v1/practice-journal/seals",
        headers=parent_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "week_start": "2026-06-08"},
    )
    await client.post(
        "/api/v1/practice-journal/endorsements/self",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "by": "self", "date": "2026-06-10", "note": "good"},
    )

    resp = await client.get(
        "/api/v1/practice-journal/ledger",
        headers=student_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID, "year": 2026, "month": 6},
    )
    data = resp.json()
    assert len(data["marks"]) == 1
    # Nested mark object carries the FE keys, not the old ones.
    assert data["marks"][0]["intensity"] == "full"
    assert data["marks"][0]["date"] == "2026-06-10"
    assert "mark_type" not in data["marks"][0]
    assert len(data["seals"]) == 1
    assert data["seals"][0]["week_start"] == "2026-06-08"
    assert len(data["endorsements"]) == 1
    assert data["endorsements"][0]["by"] == "self"
    assert data["endorsements"][0]["date"] == "2026-06-10"
    assert "by_type" not in data["endorsements"][0]


# ===========================================================================
# Volumes
# ===========================================================================


async def test_bind_and_list_volume(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    piece_id = str(uuid4())
    resp = await client.post(
        "/api/v1/practice-journal/volumes",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "piece_id": piece_id, "piece_name": "Bach Minuet"},
    )
    assert resp.status_code == 200
    data = resp.json()
    # WIRE CONTRACT: FE BoundVolume.fromJson reads
    # child_profile_id, piece_id, piece_name, volume_no, bound_date.
    assert data["child_profile_id"] == _STUDENT_PROF_ID
    assert data["piece_id"] == piece_id
    assert data["piece_name"] == "Bach Minuet"
    assert data["volume_no"] == 1
    assert "bound_date" in data  # NOT NULL date, FE-required
    assert "title" not in data  # old key must be gone

    list_resp = await client.get(
        "/api/v1/practice-journal/volumes",
        headers=student_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID},
    )
    assert list_resp.status_code == 200
    volumes = list_resp.json()
    assert len(volumes) == 1
    assert volumes[0]["piece_id"] == piece_id
    assert volumes[0]["piece_name"] == "Bach Minuet"


async def test_bind_volume_is_idempotent(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    piece_id = str(uuid4())
    payload = {"child_profile_id": _STUDENT_PROF_ID, "piece_id": piece_id, "piece_name": "Twinkle"}
    r1 = await client.post("/api/v1/practice-journal/volumes", headers=student_hdrs(), json=payload)
    r2 = await client.post("/api/v1/practice-journal/volumes", headers=student_hdrs(), json=payload)
    assert r1.status_code == 200
    assert r2.status_code == 200
    # Same piece → same volume (no second row).
    assert r1.json() == r2.json()

    list_resp = await client.get(
        "/api/v1/practice-journal/volumes",
        headers=student_hdrs(),
        params={"child_profile_id": _STUDENT_PROF_ID},
    )
    assert len(list_resp.json()) == 1


async def test_volume_numbers_increment(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    for i in range(3):
        r = await client.post(
            "/api/v1/practice-journal/volumes",
            headers=student_hdrs(),
            json={"child_profile_id": _STUDENT_PROF_ID, "piece_id": str(uuid4()), "piece_name": f"P{i}"},
        )
        assert r.json()["volume_no"] == i + 1


async def test_stranger_cannot_bind_volume(client: AsyncClient, db_session, create_test_user):
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/volumes",
        headers=stranger_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "piece_id": str(uuid4()), "piece_name": "P"},
    )
    assert resp.status_code == 403


# ===========================================================================
# Snake_case wire-shape contract
# ===========================================================================


async def test_response_keys_are_snake_case(client: AsyncClient, db_session, create_test_user):
    """All response keys must be snake_case (NOT camelCase)."""
    await _seed_base(db_session, create_test_user)

    resp = await client.post(
        "/api/v1/practice-journal/marks",
        headers=student_hdrs(),
        json={"child_profile_id": _STUDENT_PROF_ID, "date": "2026-06-15", "intensity": "short"},
    )
    keys = set(resp.json().keys())
    camel_keys = {k for k in keys if any(c.isupper() for c in k)}
    assert camel_keys == set(), f"CamelCase keys found: {camel_keys}"
