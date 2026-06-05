"""Tests for /academies/{id}/announcements — AC-M3 학원 공지 BE."""

from __future__ import annotations

from uuid import uuid4

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token

pytestmark = pytest.mark.asyncio

OWNER_USER_ID = "test-user-id"
OTHER_USER_ID = "other-user-id"


def _owner_headers(active_context: str | None = None, academy_id: str | None = None) -> dict[str, str]:
    payload: dict[str, str] = {"sub": OWNER_USER_ID, "role": "teacher"}
    if active_context:
        payload["active_context"] = active_context
    if academy_id:
        payload["academy_id"] = academy_id
    return {"Authorization": f"Bearer {create_access_token(data=payload)}"}


async def _create_academy(client: AsyncClient, create_test_user) -> str:
    await create_test_user(user_id=OWNER_USER_ID, role="teacher", name="김원장")
    resp = await client.post(
        "/api/v1/academies",
        headers=_owner_headers(),
        json={
            "slug": f"ann-{uuid4().hex[:8]}",
            "name": "공지 테스트",
            "also_register_as_teacher": True,
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


# ---------------------------------------------------------------------------
# POST /academies/{id}/announcements — 학원장 draft 생성
# ---------------------------------------------------------------------------


async def test_owner_creates_announcement_draft(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "휴원 안내",
            "body_markdown": "**다음 주 월요일 휴원합니다.**",
            "audience": "all",
            "channels": ["inapp"],
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["title"] == "휴원 안내"
    assert body["audience"] == "all"
    assert body["status"] == "draft"
    assert body["channels"] == ["inapp"]
    assert body["academy_id"] == academy_id
    assert body["author_user_id"] == OWNER_USER_ID


async def test_teacher_context_blocked_from_create(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """active_context=teacher → 학원장 전용 endpoint 차단 (§6.2)."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
        json={
            "title": "차단 시도",
            "body_markdown": "차단되어야 함",
            "audience": "all",
        },
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_non_owner_create_returns_403(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """학원 비멤버 → 403 (assert_owner)."""
    academy_id = await _create_academy(client, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="other@test.com")

    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=other_headers,
        json={"title": "차단", "body_markdown": "x", "audience": "all"},
    )
    assert response.status_code == 403


async def test_teacher_students_audience_requires_filter(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """audience=teacher_students 인데 audience_filter 없으면 400."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "강사별 안내",
            "body_markdown": "강사 X 의 학생들에게만",
            "audience": "teacher_students",
        },
    )
    assert response.status_code == 400


async def test_audience_filter_persists(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """audience_filter JSON 보존."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "강사 김선생 학생",
            "body_markdown": "강사별 공지",
            "audience": "teacher_students",
            "audience_filter": {"teacher_member_id": "tm-123"},
            "channels": ["inapp", "kakao"],
            "kakao_template_id": "TPL_GENERAL",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["audience_filter"] == {"teacher_member_id": "tm-123"}
    assert body["channels"] == ["inapp", "kakao"]
    assert body["kakao_template_id"] == "TPL_GENERAL"


# ---------------------------------------------------------------------------
# GET 목록 + 단건
# ---------------------------------------------------------------------------


async def test_member_lists_announcements(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    # 2건 생성
    for title in ["공지 1", "공지 2"]:
        await client.post(
            f"/api/v1/academies/{academy_id}/announcements",
            headers=_owner_headers(),
            json={"title": title, "body_markdown": "x", "audience": "all"},
        )

    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["total_count"] == 2
    titles = [a["title"] for a in body["announcements"]]
    assert "공지 1" in titles and "공지 2" in titles


async def test_non_member_list_returns_403(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="o@test.com")
    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=other_headers,
    )
    assert response.status_code == 403


async def test_get_announcement_detail(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    created = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={"title": "단건 조회", "body_markdown": "**굵게**", "audience": "all"},
    )
    announcement_id = created.json()["id"]

    response = await client.get(
        f"/api/v1/academies/announcements/{announcement_id}",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["id"] == announcement_id
    assert body["body_markdown"] == "**굵게**"


async def test_get_announcement_404_when_not_found(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/announcements/{uuid4()}",
        headers=_owner_headers(),
    )
    assert response.status_code == 404


async def test_teacher_member_can_list_but_not_create(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """학원 강사 멤버는 목록 조회 OK, 생성은 owner_context 가드로 차단."""
    academy_id = await _create_academy(client, create_test_user)
    # 학원장 1건 생성
    await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={"title": "공통", "body_markdown": "x", "audience": "all"},
    )

    # 같은 user 의 teacher 모드 (학원장 겸직 강사)
    teacher_headers = _owner_headers(active_context="teacher", academy_id=academy_id)

    # 목록 조회는 통과 (router-level 의존성 없음)
    list_resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=teacher_headers,
    )
    assert list_resp.status_code == 200
    assert list_resp.json()["total_count"] == 1

    # 생성은 차단 (endpoint-level require_owner_context)
    create_resp = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=teacher_headers,
        json={"title": "강사 시도", "body_markdown": "x", "audience": "all"},
    )
    assert create_resp.status_code == 403


# ---------------------------------------------------------------------------
# GET /announcements/audience-preview — 대상 수 미리보기 (§3.1)
# ---------------------------------------------------------------------------


async def _get_owner_teacher_member_id(db_session: AsyncSession, academy_id: str) -> str:
    """학원장 본인의 teacher AcademyMember.id."""
    from sqlalchemy import select as _select

    from app.models.academy import AcademyMember, AcademyMemberRole

    member_id = await db_session.scalar(
        _select(AcademyMember.id)
        .where(AcademyMember.academy_id == academy_id)
        .where(AcademyMember.user_id == OWNER_USER_ID)
        .where(AcademyMember.role == AcademyMemberRole.teacher)
    )
    assert member_id is not None
    return member_id


async def _seed_student(
    db_session: AsyncSession,
    *,
    academy_id: str,
    name: str,
    teacher_member_id: str | None,
    student_user_id: str | None = None,
    parent_user_id: str | None = None,
) -> None:
    """학생 직접 삽입 (lesson-app 연결 시뮬레이션)."""
    from datetime import UTC, datetime

    from app.models.academy import AcademyStudent, AcademyStudentStatus

    db_session.add(
        AcademyStudent(
            academy_id=academy_id,
            name=name,
            instrument="피아노",
            teacher_member_id=teacher_member_id,
            student_user_id=student_user_id,
            parent_user_id=parent_user_id,
            status=AcademyStudentStatus.matched if teacher_member_id else AcademyStudentStatus.waiting,
            registered_at=datetime.now(UTC),
            matched_at=datetime.now(UTC) if teacher_member_id else None,
        )
    )
    await db_session.flush()


async def test_audience_preview_all_aggregates_all_roles(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """audience=all → 강사 + 학부모 + 학생 합산."""
    academy_id = await _create_academy(client, create_test_user)
    member_id = await _get_owner_teacher_member_id(db_session, academy_id)
    # 학생 user 연결 1명
    await create_test_user(user_id="student-u", role="student", email="s@test.com")
    # 학부모 user 연결 1명
    await create_test_user(user_id="parent-u", role="parent", email="p@test.com")
    await _seed_student(
        db_session,
        academy_id=academy_id,
        name="가입 학생",
        teacher_member_id=member_id,
        student_user_id="student-u",
    )
    await _seed_student(
        db_session,
        academy_id=academy_id,
        name="학부모 가입 학생",
        teacher_member_id=member_id,
        parent_user_id="parent-u",
    )
    await db_session.commit()

    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview?audience=all",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["by_role"]["teacher"] == 1  # 학원장 본인 겸직 강사
    assert body["by_role"]["student"] == 1
    assert body["by_role"]["parent"] == 1
    assert body["target_count"] == 3


async def test_audience_preview_teachers_only(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview?audience=teachers",
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["target_count"] == 1
    assert body["by_role"] == {"teacher": 1, "parent": 0, "student": 0}


async def test_audience_preview_students_only(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _create_academy(client, create_test_user)
    member_id = await _get_owner_teacher_member_id(db_session, academy_id)
    await create_test_user(user_id="su-1", role="student", email="su1@test.com")
    await _seed_student(
        db_session,
        academy_id=academy_id,
        name="A",
        teacher_member_id=member_id,
        student_user_id="su-1",
    )
    # 가입 안 한 학생은 카운트 제외
    await _seed_student(db_session, academy_id=academy_id, name="B", teacher_member_id=member_id)
    await db_session.commit()

    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview?audience=students",
        headers=_owner_headers(),
    )
    body = response.json()
    assert body["target_count"] == 1
    assert body["by_role"]["student"] == 1


async def test_audience_preview_teacher_students_filter(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """audience=teacher_students + teacher_member_id 필터로 그 강사 매칭 학생만."""
    academy_id = await _create_academy(client, create_test_user)
    owner_teacher = await _get_owner_teacher_member_id(db_session, academy_id)

    # 강사 본인 매칭 학생 (가입한 student)
    await create_test_user(user_id="su-own", role="student", email="own@test.com")
    await _seed_student(
        db_session,
        academy_id=academy_id,
        name="본인 학생",
        teacher_member_id=owner_teacher,
        student_user_id="su-own",
    )
    # 다른 (가공의) 강사 매칭 학생
    await create_test_user(user_id="su-other", role="student", email="other@test.com")
    await _seed_student(
        db_session,
        academy_id=academy_id,
        name="타 강사 학생",
        teacher_member_id="other-tm-id",
        student_user_id="su-other",
    )
    await db_session.commit()

    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview",
        params={"audience": "teacher_students", "teacher_member_id": owner_teacher},
        headers=_owner_headers(),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["target_count"] == 1
    assert body["by_role"]["student"] == 1


async def test_audience_preview_teacher_students_missing_filter_400(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview?audience=teacher_students",
        headers=_owner_headers(),
    )
    assert response.status_code == 400


async def test_audience_preview_blocked_for_teacher_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """강사 모드 토큰 → 403 FORBIDDEN_TEACHER_SCOPE (require_owner_context)."""
    academy_id = await _create_academy(client, create_test_user)
    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview?audience=all",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
    )
    assert response.status_code == 403
    assert response.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_audience_preview_non_owner_403(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """학원 비멤버 → assert_owner 차단 403."""
    academy_id = await _create_academy(client, create_test_user)
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="o@test.com")
    other_headers = {"Authorization": f"Bearer {create_access_token(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    response = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview?audience=all",
        headers=other_headers,
    )
    assert response.status_code == 403



# ---------------------------------------------------------------------------
# GET /academies/{id}/announcements/audience-preview — 작성 미리보기
# ---------------------------------------------------------------------------


async def _add_students(db_session, academy_id, count_with_user, count_with_parent, status_value="active", teacher_member_id=None):
    """헬퍼: 학원 학생 N건 추가 (테스트 픽스처 단순화)."""
    from datetime import UTC, datetime

    from app.models.academy import AcademyStudent, AcademyStudentStatus

    enum_status = AcademyStudentStatus(status_value)
    for i in range(count_with_user):
        db_session.add(
            AcademyStudent(
                academy_id=academy_id,
                name=f"학생{i}",
                status=enum_status,
                student_user_id=f"stu-user-{academy_id[:6]}-{i}",
                teacher_member_id=teacher_member_id,
                registered_at=datetime.now(UTC),
            )
        )
    for i in range(count_with_parent):
        db_session.add(
            AcademyStudent(
                academy_id=academy_id,
                name=f"학부모자녀{i}",
                status=enum_status,
                parent_user_id=f"par-user-{academy_id[:6]}-{i}",
                teacher_member_id=teacher_member_id,
                registered_at=datetime.now(UTC),
            )
        )
    await db_session.commit()


async def test_audience_preview_all_returns_total_by_role(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    # owner + teacher 겸직이므로 강사 멤버 1명
    await _add_students(db_session, academy_id, count_with_user=3, count_with_parent=2)

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview",
        headers=_owner_headers(),
        params={"audience": "all"},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    assert data["target_count"] == 1 + 3 + 2  # teacher + student + parent
    assert data["by_role"] == {"teacher": 1, "parent": 2, "student": 3}


async def test_audience_preview_teachers_only(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    await _add_students(db_session, academy_id, count_with_user=3, count_with_parent=2)

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview",
        headers=_owner_headers(),
        params={"audience": "teachers"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["target_count"] == 1
    assert data["by_role"] == {"teacher": 1, "parent": 0, "student": 0}


async def test_audience_preview_students_filters_inactive_and_no_user(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    # active 3 + alumni 2 (제외) + parent only 1 (student_user_id NULL)
    await _add_students(db_session, academy_id, count_with_user=3, count_with_parent=0)
    await _add_students(db_session, academy_id, count_with_user=2, count_with_parent=0, status_value="alumni")
    await _add_students(db_session, academy_id, count_with_user=0, count_with_parent=1)

    resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview",
        headers=_owner_headers(),
        params={"audience": "students"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["target_count"] == 3
    assert data["by_role"]["student"] == 3


async def test_audience_preview_teacher_students_requires_filter(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _create_academy(client, create_test_user)
    resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview",
        headers=_owner_headers(),
        params={"audience": "teacher_students"},
    )
    assert resp.status_code == 400
    assert "teacher_member_id" in resp.text


async def test_audience_preview_blocked_in_teacher_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """audience-preview 는 owner_context 가드 — 학원장 겸직 강사 모드에서도 403."""
    academy_id = await _create_academy(client, create_test_user)
    teacher_headers = _owner_headers(active_context="teacher", academy_id=academy_id)
    resp = await client.get(
        f"/api/v1/academies/{academy_id}/announcements/audience-preview",
        headers=teacher_headers,
        params={"audience": "all"},
    )
    assert resp.status_code == 403
