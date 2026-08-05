"""Regression test: RelationshipService.connect() must only let the actually
invited student activate their own teacher-student relation via invite_code.

Bug: connect() accepted ``current_user`` but never checked it against the
relation's student_id — any authenticated user (any role) who knew/guessed an
invite_code could flip an unrelated relation from trialBooked -> active.
"""

from __future__ import annotations

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.relationship import RelationStatus, TeacherStudentRelation
from app.models.student import Student
from app.services.relationship_service import RelationshipService


async def _create_student(db_session: AsyncSession, *, student_id: str, teacher_id: str, user_id: str) -> Student:
    student = Student(id=student_id, teacher_id=teacher_id, user_id=user_id, name="Test Student", instrument="violin")
    db_session.add(student)
    await db_session.flush()
    return student


@pytest.mark.asyncio
async def test_connect_rejects_user_who_is_not_the_invited_student(db_session: AsyncSession, create_test_user) -> None:
    teacher = await create_test_user(user_id="teacher-connect", role="teacher", email="teacher-connect@test.com")
    invited_student_user = await create_test_user(user_id="student-invited", role="student", email="invited@test.com")
    intruder_user = await create_test_user(user_id="student-intruder", role="student", email="intruder@test.com")

    teacher_profile_id = f"{teacher.id}-prof"
    invited_student = await _create_student(
        db_session, student_id="student-profile-invited", teacher_id=teacher_profile_id, user_id=invited_student_user.id
    )
    await _create_student(
        db_session, student_id="student-profile-intruder", teacher_id=teacher_profile_id, user_id=intruder_user.id
    )

    relation = TeacherStudentRelation(
        teacher_id=teacher_profile_id,
        student_id=invited_student.id,
        invite_code="ABC123",
        status=RelationStatus.trialBooked,
    )
    db_session.add(relation)
    await db_session.flush()

    service = RelationshipService(db_session)

    with pytest.raises(HTTPException) as exc_info:
        await service.connect("ABC123", intruder_user)
    assert exc_info.value.status_code == 404

    await db_session.refresh(relation)
    assert relation.status == RelationStatus.trialBooked


@pytest.mark.asyncio
async def test_connect_allows_the_actually_invited_student(db_session: AsyncSession, create_test_user) -> None:
    teacher = await create_test_user(user_id="teacher-connect-2", role="teacher", email="teacher-connect-2@test.com")
    invited_student_user = await create_test_user(
        user_id="student-invited-2", role="student", email="invited-2@test.com"
    )

    teacher_profile_id = f"{teacher.id}-prof"
    invited_student = await _create_student(
        db_session,
        student_id="student-profile-invited-2",
        teacher_id=teacher_profile_id,
        user_id=invited_student_user.id,
    )

    relation = TeacherStudentRelation(
        teacher_id=teacher_profile_id,
        student_id=invited_student.id,
        invite_code="XYZ789",
        status=RelationStatus.trialBooked,
    )
    db_session.add(relation)
    await db_session.flush()

    service = RelationshipService(db_session)
    result = await service.connect("XYZ789", invited_student_user)
    assert result.status == RelationStatus.active
