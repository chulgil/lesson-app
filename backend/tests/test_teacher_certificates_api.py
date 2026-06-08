"""Teacher certificate CRUD — spec teacher_registration.md §3.

Phase 21 — 모델은 있으나 router endpoint 가 없던 P0 해결.
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_teacher_submits_certificate_and_lists_pending(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,  # noqa: ARG001
) -> None:
    """제출 시 status = pending. 본인 list 에 표시."""
    await create_test_user(user_id="test-user-id", role="teacher")

    # 1) 제출.
    response = await client.post(
        "/api/v1/teachers/me/certificates",
        headers=auth_headers,
        json={
            "type": "musicTeacher",
            "name": "음악교사 자격증 2급",
            "issuing_body": "교육부",
            "certificate_number": "2026-00123",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "pending"
    assert body["name"] == "음악교사 자격증 2급"
    assert body["submitted_at"] is not None
    cert_id = body["id"]

    # 2) list — 본인 자격증 1건 보임.
    list_response = await client.get("/api/v1/teachers/me/certificates", headers=auth_headers)
    assert list_response.status_code == 200
    items = list_response.json()
    assert len(items) == 1
    assert items[0]["id"] == cert_id


@pytest.mark.asyncio
async def test_teacher_resubmits_rejected_certificate(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """rejected 자격증을 PATCH 로 재제출 — status 가 pending 으로 reset."""
    from app.models.teacher import CertificateStatus, Teacher, TeacherCertificate

    await create_test_user(user_id="test-user-id", role="teacher")

    # rejected 자격증을 직접 DB 에 삽입.
    from sqlalchemy import select

    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    cert = TeacherCertificate(
        teacher_id=teacher.id,
        type="degree",
        name="학사 학위증",
        status=CertificateStatus.rejected,
        rejection_reason="이미지 흐림",
    )
    db_session.add(cert)
    await db_session.flush()

    response = await client.patch(
        f"/api/v1/teachers/me/certificates/{cert.id}",
        headers=auth_headers,
        json={"name": "학사 학위증 (재제출)", "image_url": "https://cdn.example.com/cert.png"},
    )
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "pending"
    assert body["name"] == "학사 학위증 (재제출)"
    assert body["rejection_reason"] is None


@pytest.mark.asyncio
async def test_teacher_cannot_edit_approved_certificate(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """approved 자격증은 PATCH 차단 (409). 변조 방지."""
    from sqlalchemy import select

    from app.models.teacher import CertificateStatus, Teacher, TeacherCertificate

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    cert = TeacherCertificate(
        teacher_id=teacher.id,
        type="conservatory",
        name="음악원 졸업증",
        status=CertificateStatus.approved,
    )
    db_session.add(cert)
    await db_session.flush()

    response = await client.patch(
        f"/api/v1/teachers/me/certificates/{cert.id}",
        headers=auth_headers,
        json={"name": "변조 시도"},
    )
    assert response.status_code == 409


@pytest.mark.asyncio
async def test_teacher_deletes_own_certificate(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """본인 자격증 삭제 — approved 도 self-revoke 가능."""
    from sqlalchemy import select

    from app.models.teacher import CertificateStatus, Teacher, TeacherCertificate

    await create_test_user(user_id="test-user-id", role="teacher")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    cert = TeacherCertificate(
        teacher_id=teacher.id,
        type="other",
        name="기타 자격증",
        status=CertificateStatus.approved,
    )
    db_session.add(cert)
    await db_session.flush()

    response = await client.delete(f"/api/v1/teachers/me/certificates/{cert.id}", headers=auth_headers)
    assert response.status_code == 204

    list_response = await client.get("/api/v1/teachers/me/certificates", headers=auth_headers)
    assert list_response.status_code == 200
    assert list_response.json() == []


@pytest.mark.asyncio
async def test_unknown_certificate_type_returns_422(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,  # noqa: ARG001
) -> None:
    """Unknown enum 값은 service 에서 명시적 422."""
    await create_test_user(user_id="test-user-id", role="teacher")
    response = await client.post(
        "/api/v1/teachers/me/certificates",
        headers=auth_headers,
        json={"type": "not_a_real_type", "name": "X"},
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_fee_range_filter_in_search(
    client: AsyncClient,
    auth_headers,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """spec §4.2 — feeRange query 필터 동작."""
    from sqlalchemy import select

    from app.models.teacher import Teacher

    await create_test_user(user_id="test-user-id", role="teacher", name="현재 강사")
    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "test-user-id"))
    teacher.fee_min = 50000
    teacher.fee_max = 80000
    await db_session.flush()

    # 본인 강사가 검색에 보이도록 — 비싼 fee_min 으로 필터해서 제외 확인.
    response = await client.get(
        "/api/v1/teachers",
        headers=auth_headers,
        params={"fee_min": 100000},  # 강사의 fee_max(80000) 보다 큼 → 제외.
    )
    assert response.status_code == 200
    ids = [t["id"] for t in response.json()["items"]]
    assert teacher.id not in ids

    # 매칭 범위로 조회 → 포함.
    response = await client.get(
        "/api/v1/teachers",
        headers=auth_headers,
        params={"fee_min": 40000, "fee_max": 90000},
    )
    assert response.status_code == 200
    ids = [t["id"] for t in response.json()["items"]]
    assert teacher.id in ids
