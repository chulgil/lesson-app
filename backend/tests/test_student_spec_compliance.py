"""Student journey spec compliance — Phase 22.

검증 대상:
- LessonRequestCreate / Response 에 ``preferred_location_type`` 필드 (spec §18)
- 학생용 ``GET /announcements/visible`` — 본인 활성 선생님 announcement 본문 조회
"""

from __future__ import annotations

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession


@pytest.mark.asyncio
async def test_lesson_request_preserves_preferred_location_type(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,  # noqa: ARG001
) -> None:
    """spec §18 — preferred_location_type 필드가 응답에 그대로 보존."""
    from app.core.security import create_access_token

    await create_test_user(user_id="teacher-loc", role="teacher")
    await create_test_user(user_id="student-loc", role="student", email="student-loc@test.com", name="장소학생")
    student_token = create_access_token(data={"sub": "student-loc", "role": "student"})

    response = await client.post(
        "/api/v1/schedule/lesson-requests",
        headers={"Authorization": f"Bearer {student_token}"},
        json={
            "teacher_id": "teacher-loc",
            "request_type": "regular",
            "instrument": "piano",
            "goal": "hobby",
            "experience_level": "beginner",
            "preferred_duration": 60,
            "preferred_location_type": "teacherStudio",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["preferred_location_type"] == "teacherStudio"


@pytest.mark.asyncio
async def test_student_views_active_teachers_announcements(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,
) -> None:
    """학생은 본인 활성 선생님의 announcement 본문을 직접 조회 가능."""
    from sqlalchemy import select

    from app.core.security import create_access_token
    from app.models.relationship import RelationStatus, TeacherStudentRelation
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.models.teacher_announcement import TeacherAnnouncement, TeacherAnnouncementType

    await create_test_user(user_id="teacher-anno", role="teacher", name="공지 선생님")
    await create_test_user(user_id="student-anno", role="student", email="student-anno@test.com", name="공지 학생")

    teacher = await db_session.scalar(select(Teacher).where(Teacher.user_id == "teacher-anno"))
    student = Student(user_id="student-anno", teacher_id=teacher.id, name="공지 학생", instrument="piano")
    db_session.add(student)
    await db_session.flush()

    db_session.add(
        TeacherStudentRelation(
            teacher_id=teacher.id,
            student_id=student.id,
            status=RelationStatus.active,
        )
    )
    db_session.add(
        TeacherAnnouncement(
            teacher_id=teacher.id,
            type=TeacherAnnouncementType.general,
            message="이번 주 수업 노트 안내드립니다",
            notified_count=1,
        )
    )
    await db_session.flush()

    student_token = create_access_token(data={"sub": "student-anno", "role": "student"})
    response = await client.get(
        "/api/v1/announcements/visible",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    items = response.json()
    assert len(items) == 1
    assert items[0]["message"] == "이번 주 수업 노트 안내드립니다"
    assert items[0]["teacher_id"] == teacher.id


@pytest.mark.asyncio
async def test_student_with_no_relations_sees_empty_announcements(
    client: AsyncClient,
    create_test_user,
    db_session: AsyncSession,  # noqa: ARG001
) -> None:
    """연결된 선생님이 없는 학생은 빈 리스트 — 다른 사람 공지 leak 차단."""
    from app.core.security import create_access_token

    await create_test_user(user_id="student-empty", role="student", email="student-empty@test.com", name="외톨이")
    student_token = create_access_token(data={"sub": "student-empty", "role": "student"})

    response = await client.get(
        "/api/v1/announcements/visible",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    assert response.json() == []
