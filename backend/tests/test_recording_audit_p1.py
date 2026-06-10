"""Phase 43 (2026-06-10 audit) — Recording 도메인 P1 4건 regression.

1. upload role gate (student only) + section ownership IDOR 차단.
2. write 액션 (delete/share/set_representative) parent 403.
3. share 가 shared_at 컬럼 갱신.
4. RecordingResponse 에 title 필드 노출.
"""

from __future__ import annotations

import io
from datetime import date as _date

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token


def _student_headers(user_id: str = "student-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "student"})
    return {"Authorization": f"Bearer {token}"}


def _teacher_headers(user_id: str = "teacher-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "teacher"})
    return {"Authorization": f"Bearer {token}"}


def _parent_headers(user_id: str = "parent-user-id") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": "parent"})
    return {"Authorization": f"Bearer {token}"}


async def _seed_student_section(
    db_session: AsyncSession,
    *,
    student_user_id: str = "student-user-id",
) -> str:
    """학생 → repertoire → section 풀세팅. 반환: section_id."""
    from app.models.practice import PracticeRepertoire, PracticeSection, RangeType

    repertoire = PracticeRepertoire(
        student_id=student_user_id,
        name="레퍼토리",
        start_date=_date(2126, 7, 1),
    )
    db_session.add(repertoire)
    await db_session.flush()
    section = PracticeSection(
        repertoire_id=repertoire.id,
        piece_name="피스",
        range_type=RangeType.full,
    )
    db_session.add(section)
    await db_session.flush()
    return section.id


async def _seed_recording(
    db_session: AsyncSession,
    *,
    section_id: str,
    student_id: str,
    title: str | None = None,
) -> str:
    """기존 PracticeRecording 직접 생성. 반환: recording.id."""
    from app.models.practice import PracticeRecording

    rec = PracticeRecording(
        section_id=section_id,
        student_id=student_id,
        file_path="recordings/test.m4a",
        file_url="https://example.com/test.m4a",
        file_key="recordings/test.m4a",
        duration_seconds=60,
        title=title,
    )
    db_session.add(rec)
    await db_session.flush()
    return rec.id


async def _setup_users(create_test_user) -> None:
    await create_test_user(user_id="student-user-id", role="student", name="학생", email="s@test.com")
    await create_test_user(user_id="teacher-user-id", role="teacher", name="선생", email="t@test.com")
    await create_test_user(user_id="parent-user-id", role="parent", name="학부모", email="p@test.com")


@pytest.mark.asyncio
async def test_recording_response_includes_title_and_shared_at(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #3 #4 — title 필드 + shared_at 응답 노출."""
    await _setup_users(create_test_user)
    section_id = await _seed_student_section(db_session)
    rec_id = await _seed_recording(db_session, section_id=section_id, student_id="student-user-id", title="첫 연습")
    await db_session.commit()

    response = await client.get(
        f"/api/v1/recordings/{rec_id}",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert body["title"] == "첫 연습"
    # shared_at 키 응답에 존재.
    assert "shared_at" in body
    assert body["shared_at"] is None


@pytest.mark.asyncio
async def test_teacher_upload_rejected_with_403(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #1 — student role 외 업로드 403."""
    await _setup_users(create_test_user)
    section_id = await _seed_student_section(db_session)
    await db_session.commit()

    files = {"file": ("test.m4a", io.BytesIO(b"fake-audio"), "audio/m4a")}
    response = await client.post(
        "/api/v1/recordings/upload",
        headers=_teacher_headers(),
        files=files,
        data={"section_id": section_id, "duration_seconds": "30"},
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_upload_to_others_section_rejected_with_403(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #1 — 자기 소유 아닌 section_id 첨부 시 IDOR 차단 (403)."""
    await _setup_users(create_test_user)
    # 다른 학생의 section.
    section_id = await _seed_student_section(db_session, student_user_id="other-student-user-id")
    await db_session.commit()

    files = {"file": ("test.m4a", io.BytesIO(b"fake-audio"), "audio/m4a")}
    response = await client.post(
        "/api/v1/recordings/upload",
        headers=_student_headers(),
        files=files,
        data={"section_id": section_id, "duration_seconds": "30"},
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_parent_cannot_delete_recording(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #2 — 학부모는 delete 시도 403 (read 가능해도 write 차단)."""
    from app.models.parent import (
        Parent,
        ParentChildRelation,
        ParentChildRelationStatus,
        ParentVisibilitySettings,
    )
    from app.models.student import Student

    await _setup_users(create_test_user)
    db_session.add(
        Student(
            id="student-user-id",
            user_id="student-user-id",
            name="자녀",
            instrument="violin",
            teacher_id="teacher-user-id-prof",
        )
    )
    await db_session.flush()
    section_id = await _seed_student_section(db_session)
    rec_id = await _seed_recording(db_session, section_id=section_id, student_id="student-user-id")
    db_session.add_all(
        [
            Parent(id="parent-profile-id", user_id="parent-user-id", name="학부모"),
            ParentChildRelation(
                parent_id="parent-profile-id",
                student_id="student-user-id",
                status=ParentChildRelationStatus.active,
            ),
            ParentVisibilitySettings(
                teacher_id="teacher-user-id-prof",
                student_id="student-user-id",
                can_view_recordings=True,
            ),
        ]
    )
    await db_session.flush()
    await db_session.commit()

    response = await client.delete(
        f"/api/v1/recordings/{rec_id}",
        headers=_parent_headers(),
    )

    assert response.status_code == 403, response.text


@pytest.mark.asyncio
async def test_share_updates_shared_at_column(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
):
    """P1 #3 — share 호출 시 DB shared_at 갱신."""
    from app.models.practice import PracticeRecording

    await _setup_users(create_test_user)
    section_id = await _seed_student_section(db_session)
    rec_id = await _seed_recording(db_session, section_id=section_id, student_id="student-user-id")
    await db_session.commit()

    response = await client.post(
        f"/api/v1/recordings/{rec_id}/share",
        headers=_student_headers(),
    )

    assert response.status_code == 200, response.text
    body = response.json()
    assert "shared_at" in body
    assert body["shared_at"] is not None
    db_session.expire_all()
    rec = await db_session.get(PracticeRecording, rec_id)
    assert rec.shared_at is not None
