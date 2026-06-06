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


async def _add_students(
    db_session, academy_id, count_with_user, count_with_parent, status_value="active", teacher_member_id=None
):
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


async def test_audience_preview_teachers_only(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
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


# ---------------------------------------------------------------------------
# POST /announcements/{id}/send — fanout
# PATCH /announcements/{id}/recipients/me/read — 읽음
# ---------------------------------------------------------------------------


async def _seed_with_audience(db_session, client, create_test_user):
    """학원 + 강사 멤버 (owner 겸직) + 학생 3명 (가입 user id 채움) + 학부모 2명."""
    academy_id = await _create_academy(client, create_test_user)

    # 학생 user 3 + 학부모 user 2 등록
    for i in range(3):
        await create_test_user(user_id=f"stu-{i}", role="student", email=f"s{i}@t.com", name=f"학생{i}")
    for i in range(2):
        await create_test_user(user_id=f"par-{i}", role="parent", email=f"p{i}@t.com", name=f"부모{i}")

    await _add_students(db_session, academy_id, count_with_user=0, count_with_parent=0)
    # 정확한 user_id 지정으로 학생/학부모 4건 생성
    from datetime import UTC, datetime

    from app.models.academy import AcademyStudent, AcademyStudentStatus

    for i in range(3):
        db_session.add(
            AcademyStudent(
                academy_id=academy_id,
                name=f"학생레코드{i}",
                status=AcademyStudentStatus.active,
                student_user_id=f"stu-{i}",
                registered_at=datetime.now(UTC),
            )
        )
    for i in range(2):
        db_session.add(
            AcademyStudent(
                academy_id=academy_id,
                name=f"학부모자녀{i}",
                status=AcademyStudentStatus.active,
                parent_user_id=f"par-{i}",
                registered_at=datetime.now(UTC),
            )
        )
    await db_session.commit()
    return academy_id


async def _create_draft(client, academy_id, audience="all", title="t", body="b"):
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={"title": title, "body_markdown": body, "audience": audience},
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


async def test_send_announcement_fans_out_recipients(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="all")

    resp = await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    # teacher 1 (owner=teacher 겸직) + student 3 + parent 2 = 6
    assert body["status"] == "sent"
    assert body["target_count"] == 6
    assert body["delivered_count"] == 6  # inapp 채널 기본
    assert body["sent_at"] is not None


async def test_send_announcement_blocked_in_teacher_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id)

    teacher_headers = _owner_headers(active_context="teacher", academy_id=academy_id)
    resp = await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=teacher_headers,
    )
    assert resp.status_code == 403


async def test_send_announcement_conflict_if_already_sent(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="teachers")

    first = await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    assert first.status_code == 200

    second = await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    assert second.status_code == 409


async def test_mark_read_sets_read_at_and_increments_count(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="students")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    # 학생 본인 토큰
    stu_token = create_access_token(data={"sub": "stu-0", "role": "student"})
    resp = await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers={"Authorization": f"Bearer {stu_token}"},
    )
    assert resp.status_code == 200, resp.text
    assert resp.json()["read_at"] is not None

    # 공지 read_count 확인 (학원장이 통계 확인)
    detail = await client.get(
        f"/api/v1/academies/announcements/{ann_id}",
        headers=_owner_headers(),
    )
    assert detail.json()["read_count"] == 1


async def test_read_by_me_reflects_recipient_read_state(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """member-recipient(owner=teacher 겸직) read_by_me: 읽기 전 false → 마킹 후 true.
    per-announcement 격리: 읽지 않은 다른 공지는 false 유지."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    # audience="all" 이면 owner(teacher 겸직)도 수신자가 된다.
    ann_id = await _create_draft(client, academy_id, audience="all")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    # 읽기 전 — read_by_me=false (상세)
    before = await client.get(
        f"/api/v1/academies/announcements/{ann_id}", headers=_owner_headers()
    )
    assert before.json()["read_by_me"] is False

    # 읽음 마킹
    marked = await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers=_owner_headers(),
    )
    assert marked.status_code == 200, marked.text

    # 읽음 후 — read_by_me=true (상세 + 목록 양쪽)
    after = await client.get(
        f"/api/v1/academies/announcements/{ann_id}", headers=_owner_headers()
    )
    assert after.json()["read_by_me"] is True
    listed = await client.get(
        f"/api/v1/academies/{academy_id}/announcements", headers=_owner_headers()
    )
    target = next(a for a in listed.json()["announcements"] if a["id"] == ann_id)
    assert target["read_by_me"] is True

    # per-announcement 격리 — 읽지 않은 다른 공지는 false
    other_id = await _create_draft(client, academy_id, audience="all", title="t2")
    await client.post(
        f"/api/v1/academies/announcements/{other_id}/send", headers=_owner_headers()
    )
    other = await client.get(
        f"/api/v1/academies/announcements/{other_id}", headers=_owner_headers()
    )
    assert other.json()["read_by_me"] is False


async def test_mark_read_idempotent(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="students")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    stu_token = create_access_token(data={"sub": "stu-0", "role": "student"})
    headers = {"Authorization": f"Bearer {stu_token}"}

    first = await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers=headers,
    )
    second = await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers=headers,
    )
    assert first.json()["read_at"] == second.json()["read_at"]

    # read_count 는 1 (중복 증가 안 함) — 학원장이 통계 확인
    detail = await client.get(
        f"/api/v1/academies/announcements/{ann_id}",
        headers=_owner_headers(),
    )
    assert detail.json()["read_count"] == 1


async def test_mark_read_non_recipient_returns_404(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="teachers")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    stu_token = create_access_token(data={"sub": "stu-0", "role": "student"})
    resp = await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers={"Authorization": f"Bearer {stu_token}"},
    )
    assert resp.status_code == 404


# ---------------------------------------------------------------------------
# GET /announcements/{id}/stats — §7 읽음 통계
# ---------------------------------------------------------------------------


async def test_stats_returns_zeroes_for_unsent(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """draft 상태(recipient 0) → 모든 카운트 0."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="all")

    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(),
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["target_count"] == 0
    assert body["read_count"] == 0
    assert body["read_rate"] == 0.0
    assert body["unread_users"] == []
    # by_role 키 3종 모두 존재
    assert set(body["by_role"].keys()) == {"teacher", "parent", "student"}


async def test_stats_after_send_and_one_read(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """발송 + 학생 1명 read → 통계 정확성 + unread_users 나머지."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="all")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    # 학생 1명만 read
    from app.core.security import create_access_token as _cat

    stu_token = _cat(data={"sub": "stu-0", "role": "student"})
    read_resp = await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers={"Authorization": f"Bearer {stu_token}"},
    )
    assert read_resp.status_code == 200

    stats = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(),
    )
    assert stats.status_code == 200, stats.text
    body = stats.json()
    # all = 강사 1 + 학생 3 + 학부모 2 = 6
    assert body["target_count"] == 6
    assert body["read_count"] == 1
    assert body["read_rate"] == round(1 / 6, 4)
    # by_role
    assert body["by_role"]["teacher"]["target"] == 1
    assert body["by_role"]["teacher"]["read"] == 0
    assert body["by_role"]["student"]["target"] == 3
    assert body["by_role"]["student"]["read"] == 1
    assert body["by_role"]["student"]["rate"] == round(1 / 3, 4)
    assert body["by_role"]["parent"]["target"] == 2
    assert body["by_role"]["parent"]["read"] == 0
    # unread_users — 강사 1 + 학생 2 + 학부모 2 = 5
    assert len(body["unread_users"]) == 5
    unread_user_ids = {u["user_id"] for u in body["unread_users"]}
    assert "stu-0" not in unread_user_ids  # 읽은 학생은 제외


async def test_stats_blocked_in_teacher_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    """강사 모드 토큰 → 403 FORBIDDEN_TEACHER_SCOPE (require_owner_context)."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="teachers")
    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(active_context="teacher", academy_id=academy_id),
    )
    assert resp.status_code == 403
    assert resp.json()["detail"]["error"] == "FORBIDDEN_TEACHER_SCOPE"


async def test_stats_non_owner_returns_403(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    """비owner → assert_owner 차단 403."""
    from app.core.security import create_access_token as _cat

    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="all")
    await create_test_user(user_id=OTHER_USER_ID, role="teacher", email="oth@test.com")
    other_headers = {"Authorization": f"Bearer {_cat(data={'sub': OTHER_USER_ID, 'role': 'teacher'})}"}
    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=other_headers,
    )
    assert resp.status_code == 403


async def test_stats_404_when_not_found(client: AsyncClient, db_session: AsyncSession, create_test_user) -> None:
    await _seed_with_audience(db_session, client, create_test_user)
    resp = await client.get(
        f"/api/v1/academies/announcements/{uuid4()}/stats",
        headers=_owner_headers(),
    )
    assert resp.status_code == 404


# ---------------------------------------------------------------------------
# GET /announcements/{id}/stats — §7 통계 (학원장)
# ---------------------------------------------------------------------------


async def test_stats_returns_zero_when_draft(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="all")

    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(),
    )
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["target_count"] == 0
    assert body["read_count"] == 0
    assert body["read_rate"] == 0.0
    assert body["unread_users"] == []


async def test_stats_after_send_has_target_and_unread(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="all")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(),
    )
    body = resp.json()
    # 강사 1 + 학생 3 + 학부모 2 = 6명
    assert body["target_count"] == 6
    assert body["read_count"] == 0
    # 모두 미열람
    assert len(body["unread_users"]) == 6
    # by_role 분해
    assert body["by_role"]["teacher"]["target"] == 1
    assert body["by_role"]["student"]["target"] == 3
    assert body["by_role"]["parent"]["target"] == 2


async def test_stats_partial_read_rate(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="students")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    # 학생 3명 중 1명만 읽음
    stu_token = create_access_token(data={"sub": "stu-0", "role": "student"})
    await client.patch(
        f"/api/v1/academies/announcements/{ann_id}/recipients/me/read",
        headers={"Authorization": f"Bearer {stu_token}"},
    )

    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["target_count"] == 3
    assert body["read_count"] == 1
    # 1/3 → 0.3333
    assert abs(body["read_rate"] - 0.3333) < 0.001
    assert body["by_role"]["student"]["target"] == 3
    assert body["by_role"]["student"]["read"] == 1
    # 미열람 = 2명
    assert len(body["unread_users"]) == 2
    assert all(u["role"] == "student" for u in body["unread_users"])


async def test_stats_unread_users_has_user_id_and_role(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="parents")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=_owner_headers(),
    )
    body = resp.json()
    unread_ids = {u["user_id"] for u in body["unread_users"]}
    assert unread_ids == {"par-0", "par-1"}
    assert all(u["role"] == "parent" for u in body["unread_users"])


async def test_stats_blocked_in_teacher_context(
    client: AsyncClient, db_session: AsyncSession, create_test_user
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    ann_id = await _create_draft(client, academy_id, audience="teachers")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    teacher_headers = _owner_headers(active_context="teacher", academy_id=academy_id)
    resp = await client.get(
        f"/api/v1/academies/announcements/{ann_id}/stats",
        headers=teacher_headers,
    )
    assert resp.status_code == 403


# ---------------------------------------------------------------------------
# §4 카카오 알림톡 채널 wiring
# ---------------------------------------------------------------------------


async def _set_user_phones(db_session, owner_phone: str | None = None, stu_phones: dict | None = None, par_phones: dict | None = None):
    """헬퍼: User.phone 컬럼을 직접 갱신 (테스트 환경에서 단순화)."""
    from sqlalchemy import update

    from app.models.user import User as UserModel

    if owner_phone is not None:
        await db_session.execute(update(UserModel).where(UserModel.id == OWNER_USER_ID).values(phone=owner_phone))
    for uid, phone in (stu_phones or {}).items():
        await db_session.execute(update(UserModel).where(UserModel.id == uid).values(phone=phone))
    for uid, phone in (par_phones or {}).items():
        await db_session.execute(update(UserModel).where(UserModel.id == uid).values(phone=phone))
    await db_session.commit()


async def _create_kakao_draft(client, academy_id, audience="all"):
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "휴원 안내",
            "body_markdown": "다음 주 월요일 휴원합니다.",
            "audience": audience,
            "channels": ["inapp", "kakao"],
            "kakao_template_id": "closure_notice_v1",
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["id"]


async def test_send_kakao_calls_alimtalk_for_users_with_phone(
    client: AsyncClient, db_session: AsyncSession, create_test_user, monkeypatch
) -> None:
    """kakao 채널 활성 시 User.phone 있는 수신자에게 알림톡 호출."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    # 학생 3 중 2명만 phone, 학부모 2 중 1명만 phone
    await _set_user_phones(
        db_session,
        owner_phone="010-9000-0000",
        stu_phones={"stu-0": "010-1111-1111", "stu-1": "010-2222-2222"},
        par_phones={"par-0": "010-3333-3333"},
    )

    from app.services import alimtalk_service as alim_module

    sent_messages: list[tuple[str, str]] = []

    class _RecordingMock:
        async def send(self, *, template_id: str, recipient_phone: str, variables: dict):
            sent_messages.append((template_id, recipient_phone))
            from app.core.alimtalk_client import AlimTalkResult
            return AlimTalkResult(success=True, message_id=f"mock-{len(sent_messages)}")

    monkeypatch.setattr(alim_module, "_shared_mock_client", _RecordingMock())
    # ALIMTALK_USE_MOCK 가 true 라고 가정 (테스트 기본 settings)

    ann_id = await _create_kakao_draft(client, academy_id, audience="all")
    resp = await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    assert resp.status_code == 200, resp.text

    # 학원장(owner=teacher 겸직) 010-9000 + 학생 010-1111, 010-2222 + 학부모 010-3333 = 4건
    phones = sorted(p for _, p in sent_messages)
    assert phones == ["010-1111-1111", "010-2222-2222", "010-3333-3333", "010-9000-0000"]
    assert all(t == "closure_notice_v1" for t, _ in sent_messages)


async def test_send_kakao_marks_recipient_kakao_delivered(
    client: AsyncClient, db_session: AsyncSession, create_test_user, monkeypatch
) -> None:
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    await _set_user_phones(db_session, stu_phones={"stu-0": "010-1111-1111"})

    from app.services import alimtalk_service as alim_module
    from app.core.alimtalk_client import AlimTalkResult

    class _AlwaysOk:
        async def send(self, **_):
            return AlimTalkResult(success=True, message_id="ok")

    monkeypatch.setattr(alim_module, "_shared_mock_client", _AlwaysOk())

    ann_id = await _create_kakao_draft(client, academy_id, audience="students")
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )

    # recipient row 의 kakao_delivered 확인
    from sqlalchemy import select

    from app.models.academy_announcement import AcademyAnnouncementRecipient

    rows = (
        await db_session.execute(
            select(AcademyAnnouncementRecipient).where(
                AcademyAnnouncementRecipient.announcement_id == ann_id
            )
        )
    ).scalars().all()
    # phone 있는 stu-0 만 True
    by_uid = {r.user_id: r.kakao_delivered for r in rows}
    assert by_uid["stu-0"] is True
    assert by_uid["stu-1"] is False
    assert by_uid["stu-2"] is False


async def test_send_without_kakao_template_id_skips_alimtalk(
    client: AsyncClient, db_session: AsyncSession, create_test_user, monkeypatch
) -> None:
    """channels 에 kakao 가 있어도 kakao_template_id 없으면 알림톡 호출 안 함."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    await _set_user_phones(db_session, stu_phones={"stu-0": "010-1111-1111"})

    from app.services import alimtalk_service as alim_module
    from app.core.alimtalk_client import AlimTalkResult

    sent: list = []

    class _Record:
        async def send(self, **kw):
            sent.append(kw)
            return AlimTalkResult(success=True)

    monkeypatch.setattr(alim_module, "_shared_mock_client", _Record())

    # kakao_template_id 없이 작성
    resp = await client.post(
        f"/api/v1/academies/{academy_id}/announcements",
        headers=_owner_headers(),
        json={
            "title": "공지",
            "body_markdown": "본문",
            "audience": "students",
            "channels": ["inapp", "kakao"],
        },
    )
    ann_id = resp.json()["id"]
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    assert sent == []


async def test_send_kakao_failure_does_not_break_fanout(
    client: AsyncClient, db_session: AsyncSession, create_test_user, monkeypatch
) -> None:
    """알림톡 발송 실패 시 recipient.kakao_delivered=False, inapp / status 는 정상."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    await _set_user_phones(db_session, stu_phones={"stu-0": "010-1111-1111"})

    from app.services import alimtalk_service as alim_module
    from app.core.alimtalk_client import AlimTalkResult

    class _AlwaysFail:
        async def send(self, **_):
            return AlimTalkResult(success=False, error="carrier 503")

    monkeypatch.setattr(alim_module, "_shared_mock_client", _AlwaysFail())

    ann_id = await _create_kakao_draft(client, academy_id, audience="students")
    resp = await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    body = resp.json()
    assert body["status"] == "sent"  # status 전이는 정상
    assert body["target_count"] == 3
    assert body["delivered_count"] == 3  # inapp 활성 → inapp 기준

    from sqlalchemy import select

    from app.models.academy_announcement import AcademyAnnouncementRecipient

    rows = (
        await db_session.execute(
            select(AcademyAnnouncementRecipient).where(
                AcademyAnnouncementRecipient.announcement_id == ann_id
            )
        )
    ).scalars().all()
    assert all(r.kakao_delivered is False for r in rows)
    assert all(r.inapp_delivered is True for r in rows)


async def test_send_inapp_only_skips_kakao_entirely(
    client: AsyncClient, db_session: AsyncSession, create_test_user, monkeypatch
) -> None:
    """channels=[inapp] 만 있으면 알림톡 호출 0건."""
    academy_id = await _seed_with_audience(db_session, client, create_test_user)
    await _set_user_phones(db_session, stu_phones={"stu-0": "010-1111-1111"})

    from app.services import alimtalk_service as alim_module
    from app.core.alimtalk_client import AlimTalkResult

    sent: list = []

    class _Record:
        async def send(self, **kw):
            sent.append(kw)
            return AlimTalkResult(success=True)

    monkeypatch.setattr(alim_module, "_shared_mock_client", _Record())

    ann_id = await _create_draft(client, academy_id, audience="students")  # channels 기본 inapp
    await client.post(
        f"/api/v1/academies/announcements/{ann_id}/send",
        headers=_owner_headers(),
    )
    assert sent == []
