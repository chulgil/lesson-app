"""Academy endpoints — AC-M1 그룹 A.

Spec: docs/specs/web/academy/README.md (AC-M1) + docs/specs/academy/academy_master.md.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import ActiveContext, record_access_denial, require_owner_context
from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.academy import (
    AcademyCreate,
    AcademyInviteAcceptRequest,
    AcademyInviteCreate,
    AcademyInviteCreatedResponse,
    AcademyInviteListResponse,
    AcademyInvitePreview,
    AcademyInviteRejectRequest,
    AcademyInviteResponse,
    AcademyInviteState,
    AcademyMemberConsentUpdate,
    AcademyMemberListResponse,
    AcademyMemberResponse,
    AcademyMemberRole,
    AcademyResponse,
    AcademyStudentCreate,
    AcademyStudentListResponse,
    AcademyStudentResponse,
    AcademyStudentStatus,
    AcademyStudentUpdate,
    AcademyUpdate,
)
from app.services.academy_service import AcademyService

router = APIRouter()
public_router = APIRouter()


# ---------------------------------------------------------------------------
# Academy (authed)
# ---------------------------------------------------------------------------


@router.post(
    "",
    response_model=AcademyResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create an academy (current user becomes owner)",
)
async def create_academy(
    body: AcademyCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyResponse:
    service = AcademyService(db)
    academy = await service.create_academy(owner_user_id=current_user.id, body=body)
    return AcademyResponse.model_validate(academy)


@router.get(
    "/me",
    response_model=list[AcademyResponse],
    status_code=status.HTTP_200_OK,
    summary="List academies the current user belongs to",
)
async def list_my_academies(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[AcademyResponse]:
    service = AcademyService(db)
    academies = await service.list_academies_for_user(current_user.id)
    return [AcademyResponse.model_validate(a) for a in academies]


@router.get(
    "/{academy_id}",
    response_model=AcademyResponse,
    status_code=status.HTTP_200_OK,
    summary="Get academy detail (members only)",
)
async def get_academy(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyResponse:
    service = AcademyService(db)
    academy = await service.get_academy(academy_id)
    # 멤버 권한 검사 — list_academies_for_user 로 확인.
    my_academies = await service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    return AcademyResponse.model_validate(academy)


@router.patch(
    "/{academy_id}",
    response_model=AcademyResponse,
    status_code=status.HTTP_200_OK,
    summary="Update academy (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def update_academy(
    academy_id: str,
    body: AcademyUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyResponse:
    service = AcademyService(db)
    await service.assert_owner(academy_id, current_user.id)
    academy = await service.update_academy(academy_id=academy_id, body=body)
    return AcademyResponse.model_validate(academy)


# ---------------------------------------------------------------------------
# Members
# ---------------------------------------------------------------------------


@router.get(
    "/{academy_id}/members",
    response_model=AcademyMemberListResponse,
    status_code=status.HTTP_200_OK,
    summary="List academy members",
)
async def list_academy_members(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    role: Annotated[AcademyMemberRole | None, Query()] = None,
    include_revoked: Annotated[bool, Query()] = False,
) -> AcademyMemberListResponse:
    service = AcademyService(db)
    # 멤버 권한 검사.
    my_academies = await service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    members, total = await service.list_members(academy_id=academy_id, role=role, include_revoked=include_revoked)
    return AcademyMemberListResponse(
        members=[AcademyMemberResponse.model_validate(m) for m in members],
        total_count=total,
    )


@router.patch(
    "/members/{member_id}/consent",
    response_model=AcademyMemberResponse,
    status_code=status.HTTP_200_OK,
    summary="Update own public page consent",
)
async def update_member_consent(
    member_id: str,
    body: AcademyMemberConsentUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyMemberResponse:
    service = AcademyService(db)
    member = await service.update_consent(
        member_id=member_id,
        by_user_id=current_user.id,
        public_page_consent=body.public_page_consent,
    )
    return AcademyMemberResponse.model_validate(member)


@router.post(
    "/members/{member_id}/revoke",
    response_model=AcademyMemberResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke a member's access (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def revoke_member(
    member_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyMemberResponse:
    service = AcademyService(db)
    member = await service.revoke_member_access(member_id=member_id, by_user_id=current_user.id)
    return AcademyMemberResponse.model_validate(member)


# ---------------------------------------------------------------------------
# Students
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/students",
    response_model=AcademyStudentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a student (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def create_student(
    academy_id: str,
    body: AcademyStudentCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyStudentResponse:
    service = AcademyService(db)
    student = await service.create_student(academy_id=academy_id, by_user_id=current_user.id, body=body)
    return AcademyStudentResponse.model_validate(student)


@router.get(
    "/{academy_id}/students",
    response_model=AcademyStudentListResponse,
    status_code=status.HTTP_200_OK,
    summary="List academy students",
)
async def list_students(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    context: ActiveContext,
    status_filter: Annotated[AcademyStudentStatus | None, Query(alias="status")] = None,
) -> AcademyStudentListResponse:
    service = AcademyService(db)
    my_academies = await service.list_academies_for_user(current_user.id)
    if not any(a.id == academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    # AC-M2 §6.2: 강사 모드 격리 — 본인 매칭 학생만 반환.
    active_context, _, _ = context
    teacher_user_id_filter = current_user.id if active_context == "teacher" else None
    students, total = await service.list_students(
        academy_id=academy_id,
        status_filter=status_filter,
        teacher_user_id_filter=teacher_user_id_filter,
    )
    return AcademyStudentListResponse(
        students=[AcademyStudentResponse.model_validate(s) for s in students],
        total_count=total,
    )


@router.get(
    "/students/{student_id}",
    response_model=AcademyStudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get student detail (members only)",
)
async def get_student(
    student_id: str,
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    context: ActiveContext,
) -> AcademyStudentResponse:
    service = AcademyService(db)
    student = await service.get_student(student_id)
    my_academies = await service.list_academies_for_user(current_user.id)
    if not any(a.id == student.academy_id for a in my_academies):
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not a member")
    # AC-M2 §6.2: 강사 모드 + 본인 매칭이 아닌 학생 → 403 FORBIDDEN_NOT_YOUR_STUDENT + audit (§9).
    active_context, _, _ = context
    if active_context == "teacher":
        member_id = await service.get_teacher_member_id_for_user(academy_id=student.academy_id, user_id=current_user.id)
        if member_id is None or student.teacher_member_id != member_id:
            from fastapi import HTTPException

            audit_id = await record_access_denial(
                db=db,
                request=request,
                user_id=current_user.id,
                active_context=active_context,
                academy_id=student.academy_id,
                denial_code="FORBIDDEN_NOT_YOUR_STUDENT",
                target_resource_id=student.id,
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error": "FORBIDDEN_NOT_YOUR_STUDENT",
                    "message": "본인이 담당하지 않는 학생입니다.",
                    "audit_id": audit_id,
                    "remediation": "학원장에게 매칭을 요청하거나, 학원장 모드로 전환 후 다시 시도하세요.",
                },
            )
    return AcademyStudentResponse.model_validate(student)


@router.patch(
    "/students/{student_id}",
    response_model=AcademyStudentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update student (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def update_student(
    student_id: str,
    body: AcademyStudentUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyStudentResponse:
    service = AcademyService(db)
    student = await service.update_student(student_id=student_id, by_user_id=current_user.id, body=body)
    return AcademyStudentResponse.model_validate(student)


# ---------------------------------------------------------------------------
# Invites (authed: owner CRUD)
# ---------------------------------------------------------------------------


@router.post(
    "/{academy_id}/invites",
    response_model=AcademyInviteCreatedResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Issue a teacher invite (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def create_invite(
    academy_id: str,
    body: AcademyInviteCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyInviteCreatedResponse:
    service = AcademyService(db)
    invite, raw_token = await service.create_invite(academy_id=academy_id, by_user_id=current_user.id, body=body)
    base = AcademyInviteResponse.model_validate(invite).model_dump()
    return AcademyInviteCreatedResponse(
        **base,
        token=raw_token,
        share_url=f"/academy/accept?token={raw_token}",
    )


@router.get(
    "/{academy_id}/invites",
    response_model=AcademyInviteListResponse,
    status_code=status.HTTP_200_OK,
    summary="List invites (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def list_invites(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    state_filter: Annotated[AcademyInviteState | None, Query(alias="state")] = None,
) -> AcademyInviteListResponse:
    service = AcademyService(db)
    await service.assert_owner(academy_id, current_user.id)
    invites, total = await service.list_invites(academy_id=academy_id, state_filter=state_filter)
    return AcademyInviteListResponse(
        invites=[AcademyInviteResponse.model_validate(i) for i in invites],
        total_count=total,
    )


@router.post(
    "/invites/{invite_id}/revoke",
    response_model=AcademyInviteResponse,
    status_code=status.HTTP_200_OK,
    summary="Revoke a pending invite (owner only)",
    dependencies=[Depends(require_owner_context)],
)
async def revoke_invite(
    invite_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyInviteResponse:
    service = AcademyService(db)
    invite = await service.revoke_invite(invite_id=invite_id, by_user_id=current_user.id)
    return AcademyInviteResponse.model_validate(invite)


@router.post(
    "/invites/accept",
    response_model=AcademyMemberResponse,
    status_code=status.HTTP_200_OK,
    summary="Accept an invite by token (authed user)",
)
async def accept_invite(
    body: AcademyInviteAcceptRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    token: Annotated[str, Query(min_length=1)],
) -> AcademyMemberResponse:
    service = AcademyService(db)
    member = await service.accept_invite(
        raw_token=token,
        by_user_id=current_user.id,
        public_page_consent=body.public_page_consent,
    )
    return AcademyMemberResponse.model_validate(member)


@router.post(
    "/invites/decline",
    response_model=AcademyInviteResponse,
    status_code=status.HTTP_200_OK,
    summary="Decline an invite by token",
)
async def decline_invite(
    body: AcademyInviteRejectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    token: Annotated[str, Query(min_length=1)],
) -> AcademyInviteResponse:
    service = AcademyService(db)
    invite = await service.decline_invite(raw_token=token, reason=body.reason)
    return AcademyInviteResponse.model_validate(invite)


# ---------------------------------------------------------------------------
# Public invite preview (no auth) — mounted under /public/academies/invites
# ---------------------------------------------------------------------------


@public_router.get(
    "/{token}/preview",
    response_model=AcademyInvitePreview,
    status_code=status.HTTP_200_OK,
    summary="Public invite preview by token (no auth)",
)
async def public_invite_preview(
    token: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AcademyInvitePreview:
    service = AcademyService(db)
    return await service.get_preview_by_token(token)


__all__ = ["public_router", "router"]
