"""Practice repertoire remote contract tests."""

from datetime import UTC, date, datetime

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_repertoire_archive_restore_and_permanent_delete(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Remote repertoire API supports archive, restore, and permanent delete."""
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"))
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/practice/repertoires",
        headers=auth_headers,
        json={"student_id": "student-001", "name": "Scales", "start_date": "2026-05-01"},
    )
    repertoire_id = create_response.json()["id"]

    archive_response = await client.patch(f"/api/v1/practice/repertoires/{repertoire_id}/archive", headers=auth_headers)
    assert archive_response.status_code == 200
    assert archive_response.json()["is_archived"] is True

    restore_response = await client.patch(f"/api/v1/practice/repertoires/{repertoire_id}/restore", headers=auth_headers)
    assert restore_response.status_code == 200
    assert restore_response.json()["is_archived"] is False

    delete_response = await client.delete(
        f"/api/v1/practice/repertoires/{repertoire_id}/permanent",
        headers=auth_headers,
    )
    assert delete_response.status_code == 204
    missing_response = await client.get(f"/api/v1/practice/repertoires/{repertoire_id}", headers=auth_headers)
    assert missing_response.status_code == 404


@pytest.mark.asyncio
async def test_section_helpers_update_order_daily_completion_and_counts(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Remote section helper endpoints persist order, daily completion, repeat, counts, and last practiced."""
    from app.models.practice import PracticeRepertoire, PracticeSection
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"))
    repertoire = PracticeRepertoire(id="rep-001", student_id="student-001", name="Etudes", start_date=date(2026, 5, 1))
    section_a = PracticeSection(id="section-a", repertoire_id="rep-001", piece_name="A", start_measure=1, end_measure=4)
    section_b = PracticeSection(id="section-b", repertoire_id="rep-001", piece_name="B", start_measure=5, end_measure=8)
    db_session.add_all([repertoire, section_a, section_b])
    await db_session.flush()

    detail_response = await client.get("/api/v1/practice/sections/section-a", headers=auth_headers)
    assert detail_response.status_code == 200
    assert detail_response.json()["id"] == "section-a"

    order_response = await client.put(
        "/api/v1/practice/repertoires/rep-001/section-orders",
        headers=auth_headers,
        json={"section_ids": ["section-b", "section-a"]},
    )
    assert order_response.status_code == 204

    daily_response = await client.patch(
        "/api/v1/practice/sections/section-a/daily-completion",
        headers=auth_headers,
        json={"date": "2026-05-05"},
    )
    assert daily_response.status_code == 200
    assert daily_response.json()["is_completed"] is True

    repeat_response = await client.patch("/api/v1/practice/sections/section-a/repeat", headers=auth_headers)
    assert repeat_response.status_code == 200
    assert repeat_response.json()["is_repeat"] is True

    count_response = await client.patch(
        "/api/v1/practice/sections/section-a/practice-count",
        headers=auth_headers,
        json={"practice_seconds": 180},
    )
    assert count_response.status_code == 200
    assert count_response.json()["practice_count"] == 1
    assert count_response.json()["total_practice_seconds"] == 180

    last_response = await client.patch("/api/v1/practice/sections/section-a/last-practiced-at", headers=auth_headers)
    assert last_response.status_code == 200
    assert last_response.json()["last_practiced_at"] is not None


@pytest.mark.asyncio
async def test_practice_note_crud_for_section(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Remote note API supports list, create, update, and delete."""
    from app.models.practice import PracticeRepertoire, PracticeSection
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"))
    repertoire = PracticeRepertoire(id="rep-001", student_id="student-001", name="Etudes", start_date=date(2026, 5, 1))
    section = PracticeSection(id="section-a", repertoire_id="rep-001", piece_name="A", start_measure=1, end_measure=4)
    db_session.add_all([repertoire, section])
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/practice/sections/section-a/notes",
        headers=auth_headers,
        json={"content": "Keep wrist relaxed"},
    )
    assert create_response.status_code == 201
    note_id = create_response.json()["id"]
    assert create_response.json()["content"] == "Keep wrist relaxed"

    list_response = await client.get("/api/v1/practice/sections/section-a/notes", headers=auth_headers)
    assert list_response.status_code == 200
    assert [item["id"] for item in list_response.json()] == [note_id]

    update_response = await client.put(
        f"/api/v1/practice/notes/{note_id}",
        headers=auth_headers,
        json={"content": "Relax wrist and thumb"},
    )
    assert update_response.status_code == 200
    assert update_response.json()["content"] == "Relax wrist and thumb"

    delete_response = await client.delete(f"/api/v1/practice/notes/{note_id}", headers=auth_headers)
    assert delete_response.status_code == 204
    empty_response = await client.get("/api/v1/practice/sections/section-a/notes", headers=auth_headers)
    assert empty_response.json() == []


@pytest.mark.asyncio
async def test_recording_metadata_helpers(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session,
):
    """Remote recording metadata helpers support create, representative, orphan list, and reassign."""
    from app.models.practice import PracticeRecording, PracticeRepertoire, PracticeSection
    from app.models.student import Student

    await create_test_user(user_id="test-user-id", role="teacher")
    db_session.add(Student(id="student-001", teacher_id="test-user-id-prof", name="Student", instrument="violin"))
    repertoire = PracticeRepertoire(id="rep-001", student_id="student-001", name="Etudes", start_date=date(2026, 5, 1))
    section_a = PracticeSection(id="section-a", repertoire_id="rep-001", piece_name="A", start_measure=1, end_measure=4)
    section_b = PracticeSection(id="section-b", repertoire_id="rep-001", piece_name="B", start_measure=5, end_measure=8)
    orphan = PracticeRecording(
        id="orphan-recording",
        section_id="missing-section",
        student_id="student-001",
        file_path="/tmp/orphan.m4a",
        duration_seconds=10,
        created_at=datetime.now(UTC),
    )
    db_session.add_all([repertoire, section_a, section_b, orphan])
    await db_session.flush()

    create_response = await client.post(
        "/api/v1/practice/recordings",
        headers=auth_headers,
        json={"section_id": "section-a", "file_path": "/tmp/a.m4a", "duration_seconds": 30, "bpm": 80},
    )
    assert create_response.status_code == 201
    recording_id = create_response.json()["id"]

    representative_response = await client.patch(
        "/api/v1/practice/sections/section-a/representative-recording",
        headers=auth_headers,
        json={"recording_id": recording_id},
    )
    assert representative_response.status_code == 200
    assert representative_response.json()["is_representative"] is True

    orphan_response = await client.get("/api/v1/practice/recordings/orphaned", headers=auth_headers)
    assert orphan_response.status_code == 200
    assert [item["id"] for item in orphan_response.json()] == ["orphan-recording"]

    reassign_response = await client.patch(
        "/api/v1/practice/recordings/orphan-recording/reassign",
        headers=auth_headers,
        json={"section_id": "section-b"},
    )
    assert reassign_response.status_code == 200
    assert reassign_response.json()["section_id"] == "section-b"
