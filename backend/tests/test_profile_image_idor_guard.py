"""Profile image IDOR guard tests (#408).

Before this guard, a teacher could pass any student_id as entity_id to the
upload/delete endpoint and overwrite that student's profile/background image —
including students belonging to other teachers (cross-tenant data tampering).

These tests pin the new ownership-check contract:
- Teacher may only modify images for students whose teacher_id matches.
- Student self may only modify images for their own student row (student.user_id).
- entity_type="teacher" remains a no-op against the current user only.
"""

from __future__ import annotations

import io

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.models.student import Student
from app.services import profile_image_service as profile_image_service_module


@pytest.fixture(autouse=True)
def _stub_object_storage(monkeypatch: pytest.MonkeyPatch) -> None:
    """Bypass real Vultr/S3 calls — tests only care about the auth gate."""

    async def _fake_upload(self, file_key: str, content: bytes, content_type: str | None) -> str:
        return f"/storage/{file_key}"

    async def _fake_delete(self, file_key: str) -> None:
        return None

    monkeypatch.setattr(
        profile_image_service_module.ProfileImageService,
        "_upload_to_storage",
        _fake_upload,
    )
    monkeypatch.setattr(
        profile_image_service_module.ProfileImageService,
        "_delete_from_storage",
        _fake_delete,
    )


def _image_bytes() -> tuple[str, bytes, str]:
    return "test.png", b"\x89PNG\r\n\x1a\n" + b"x" * 64, "image/png"


async def _make_student(
    db: AsyncSession, *, student_id: str, teacher_id: str | None, user_id: str | None = None
) -> Student:
    student = Student(
        id=student_id,
        teacher_id=teacher_id,
        user_id=user_id,
        name="Test Student",
        instrument="violin",
    )
    db.add(student)
    await db.flush()
    return student


def _auth_for(user_id: str, role: str = "teacher") -> dict[str, str]:
    token = create_access_token(data={"sub": user_id, "role": role})
    return {"Authorization": f"Bearer {token}"}


# ---------------------------------------------------------------------------
# Upload — cross-tenant access must be rejected
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_upload_to_other_teachers_student_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher_a = await create_test_user(user_id="teacher-a", role="teacher", email="a@test.com")
    teacher_b = await create_test_user(user_id="teacher-b", role="teacher", email="b@test.com")
    # student belongs to teacher B
    await _make_student(db_session, student_id="student-b1", teacher_id=f"{teacher_b.id}-prof")
    await db_session.commit()

    name, content, ctype = _image_bytes()
    response = await client.post(
        "/api/v1/profile-images/upload",
        files={"file": (name, io.BytesIO(content), ctype)},
        data={"image_type": "profile", "entity_type": "student", "entity_id": "student-b1"},
        headers=_auth_for(teacher_a.id),
    )

    assert response.status_code == 403, response.text

    # Verify student row was not modified
    refreshed = await db_session.scalar(select(Student).where(Student.id == "student-b1"))
    assert refreshed is not None
    assert refreshed.profile_image_url is None


@pytest.mark.asyncio
async def test_upload_to_own_student_succeeds(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher_a = await create_test_user(user_id="teacher-a-own", role="teacher", email="own@test.com")
    await _make_student(db_session, student_id="student-a1", teacher_id=f"{teacher_a.id}-prof")
    await db_session.commit()

    name, content, ctype = _image_bytes()
    response = await client.post(
        "/api/v1/profile-images/upload",
        files={"file": (name, io.BytesIO(content), ctype)},
        data={"image_type": "profile", "entity_type": "student", "entity_id": "student-a1"},
        headers=_auth_for(teacher_a.id),
    )

    assert response.status_code == 201, response.text


@pytest.mark.asyncio
async def test_upload_for_self_teacher_entity_succeeds(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher = await create_test_user(user_id="teacher-self", role="teacher", email="self@test.com")
    await db_session.commit()

    name, content, ctype = _image_bytes()
    response = await client.post(
        "/api/v1/profile-images/upload",
        files={"file": (name, io.BytesIO(content), ctype)},
        data={"image_type": "profile", "entity_type": "teacher"},
        headers=_auth_for(teacher.id),
    )

    assert response.status_code == 201, response.text


@pytest.mark.asyncio
async def test_upload_student_with_unknown_entity_id_returns_404(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher = await create_test_user(user_id="teacher-unknown", role="teacher", email="unk@test.com")
    await db_session.commit()

    name, content, ctype = _image_bytes()
    response = await client.post(
        "/api/v1/profile-images/upload",
        files={"file": (name, io.BytesIO(content), ctype)},
        data={"image_type": "profile", "entity_type": "student", "entity_id": "does-not-exist"},
        headers=_auth_for(teacher.id),
    )

    assert response.status_code in (403, 404), response.text


# ---------------------------------------------------------------------------
# Delete — cross-tenant access must be rejected
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_delete_other_teachers_student_image_returns_403(
    client: AsyncClient,
    db_session: AsyncSession,
    create_test_user,
) -> None:
    teacher_a = await create_test_user(user_id="del-a", role="teacher", email="dela@test.com")
    teacher_b = await create_test_user(user_id="del-b", role="teacher", email="delb@test.com")
    student = await _make_student(db_session, student_id="student-bd1", teacher_id=f"{teacher_b.id}-prof")
    student.profile_image_url = "https://example/preserve.png"
    await db_session.commit()

    response = await client.delete(
        "/api/v1/profile-images",
        params={"image_type": "profile", "entity_type": "student", "entity_id": "student-bd1"},
        headers=_auth_for(teacher_a.id),
    )

    assert response.status_code == 403, response.text

    refreshed = await db_session.scalar(select(Student).where(Student.id == "student-bd1"))
    assert refreshed is not None
    assert refreshed.profile_image_url == "https://example/preserve.png"
