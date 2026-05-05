"""Parent endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_parent, get_current_user, get_db
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.lesson import LessonResponse
from app.schemas.parent import (
    ChildProfileCreate,
    ChildProfileResponse,
    ChildProfileUpdate,
    ChildTeacherConnectRequest,
    ParentChildRelationResponse,
    ParentChildRelationUpdate,
    ParentConnectChildRequest,
    ParentCreate,
    ParentInvitationCreate,
    ParentInvitationResponse,
    ParentNotificationSettingsResponse,
    ParentNotificationSettingsUpdate,
    ParentResponse,
    ParentUpdate,
    ParentVisibilitySettingsResponse,
    ParentVisibilitySettingsUpdate,
)
from app.schemas.practice import PracticeStatsResponse
from app.services.parent_service import ParentService

router = APIRouter()


@router.get(
    "",
    response_model=PaginatedResponse[ParentResponse],
    status_code=status.HTTP_200_OK,
    summary="List parent profiles",
)
async def list_parents(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> PaginatedResponse[ParentResponse]:
    """Return parent profiles visible to the current user."""
    service = ParentService(db)
    return await service.list_parents(current_user)


@router.post(
    "",
    response_model=ParentResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create parent profile",
)
async def create_parent(
    body: ParentCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentResponse:
    """Create a parent profile."""
    service = ParentService(db)
    return await service.create_parent(body, current_user)


@router.get(
    "/me",
    response_model=ParentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get parent profile",
)
async def get_parent_profile(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ParentResponse:
    """Return the parent profile for the current user."""
    service = ParentService(db)
    return await service.get_profile(current_user)


@router.put(
    "/me",
    response_model=ParentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update parent profile",
)
async def update_parent_profile(
    body: ParentUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ParentResponse:
    """Update the parent profile."""
    service = ParentService(db)
    return await service.update_profile(body, current_user)


@router.get(
    "/me/children",
    response_model=list[ParentChildRelationResponse],
    status_code=status.HTTP_200_OK,
    summary="List children",
)
async def list_children(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> list[ParentChildRelationResponse]:
    """Return a list of the parent's linked children."""
    service = ParentService(db)
    return await service.get_children(current_user)


@router.post(
    "/me/children",
    response_model=ParentChildRelationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Link child via invite code",
)
async def connect_child(
    body: ParentConnectChildRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ParentChildRelationResponse:
    """Link a child to the parent using an invite code."""
    service = ParentService(db)
    return await service.connect_child(body.invite_code, current_user)


@router.get(
    "/{parent_id}/child-profiles",
    response_model=list[ChildProfileResponse],
    status_code=status.HTTP_200_OK,
    summary="List child profiles for a parent",
)
async def list_child_profiles(
    parent_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> list[ChildProfileResponse]:
    """Return child-profile shaped children for a parent."""
    service = ParentService(db)
    return await service.get_child_profiles(parent_id, current_user)


@router.post(
    "/child-profiles",
    response_model=ChildProfileResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create child profile",
)
async def create_child_profile(
    body: ChildProfileCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ChildProfileResponse:
    """Create a parent-owned child profile."""
    service = ParentService(db)
    return await service.create_child_profile(body, current_user)


@router.get(
    "/child-profiles/{child_id}",
    response_model=ChildProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get child profile",
)
async def get_child_profile(
    child_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ChildProfileResponse:
    """Return a child profile by child/student ID."""
    service = ParentService(db)
    return await service.get_child_profile(child_id, current_user)


@router.put(
    "/child-profiles/{child_id}",
    response_model=ChildProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Update child profile",
)
async def update_child_profile(
    child_id: str,
    body: ChildProfileUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ChildProfileResponse:
    """Update a parent-owned child profile."""
    service = ParentService(db)
    return await service.update_child_profile(child_id, body, current_user)


@router.delete(
    "/child-profiles/{child_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Soft-delete child profile",
)
async def delete_child_profile(
    child_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> None:
    """Soft-delete a parent-owned child profile."""
    service = ParentService(db)
    await service.delete_child_profile(child_id, current_user)


@router.post(
    "/child-profiles/{child_id}/teacher",
    response_model=ChildProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Connect teacher to child profile",
)
async def connect_teacher_to_child(
    child_id: str,
    body: ChildTeacherConnectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ChildProfileResponse:
    """Connect a teacher to a parent-owned child profile."""
    service = ParentService(db)
    return await service.connect_teacher_to_child(child_id, body, current_user)


@router.delete(
    "/child-profiles/{child_id}/teacher",
    response_model=ChildProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Disconnect teacher from child profile",
)
async def disconnect_teacher_from_child(
    child_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
) -> ChildProfileResponse:
    """Disconnect a teacher from a parent-owned child profile."""
    service = ParentService(db)
    return await service.disconnect_teacher_from_child(child_id, current_user)


@router.post(
    "/invitations",
    response_model=ParentInvitationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create parent invitation",
)
async def create_invitation(
    body: ParentInvitationCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentInvitationResponse:
    """Create a parent invitation."""
    service = ParentService(db)
    return await service.create_invitation(body, current_user)


@router.get(
    "/invitations",
    status_code=status.HTTP_200_OK,
    summary="Get or list parent invitations",
)
async def get_or_list_invitations(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    code: str | None = None,
    student_id: str | None = None,
    status_filter: str | None = None,
    status: str | None = None,
) -> ParentInvitationResponse | PaginatedResponse[ParentInvitationResponse]:
    """Return one invitation by code, or a filtered invitation list."""
    service = ParentService(db)
    result: ParentInvitationResponse | PaginatedResponse[ParentInvitationResponse] = (
        await service.get_or_list_invitations(
            current_user,
            code=code,
            student_id=student_id,
            status_filter=status_filter or status,
        )
    )
    return result


@router.patch(
    "/invitations/{invitation_id}/use",
    response_model=ParentInvitationResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark parent invitation used",
)
async def mark_invitation_used(
    invitation_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentInvitationResponse:
    """Mark a parent invitation as used."""
    service = ParentService(db)
    return await service.mark_invitation_used(invitation_id, current_user)


@router.get(
    "/relations",
    response_model=PaginatedResponse[ParentChildRelationResponse],
    status_code=status.HTTP_200_OK,
    summary="List parent-child relations",
)
async def list_relations(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> PaginatedResponse[ParentChildRelationResponse]:
    """Return relations for a student."""
    service = ParentService(db)
    return await service.get_relations_for_student(student_id, current_user)


@router.put(
    "/relations/{relation_id}",
    response_model=ParentChildRelationResponse,
    status_code=status.HTTP_200_OK,
    summary="Update parent-child relation",
)
async def update_relation(
    relation_id: str,
    body: ParentChildRelationUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentChildRelationResponse:
    """Update a parent-child relation."""
    service = ParentService(db)
    return await service.update_relation(relation_id, body, current_user)


@router.delete(
    "/relations/{relation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete parent-child relation",
)
async def delete_relation(
    relation_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a parent-child relation."""
    service = ParentService(db)
    await service.delete_relation(relation_id, current_user)


@router.get(
    "/notification-settings",
    response_model=ParentNotificationSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get parent notification settings",
)
async def get_parent_notification_settings(
    parent_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentNotificationSettingsResponse:
    """Return parent notification settings."""
    service = ParentService(db)
    return await service.get_parent_notification_settings(parent_id, current_user)


@router.put(
    "/notification-settings",
    response_model=ParentNotificationSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Save parent notification settings",
)
async def save_parent_notification_settings(
    body: ParentNotificationSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentNotificationSettingsResponse:
    """Create or update parent notification settings."""
    service = ParentService(db)
    return await service.save_parent_notification_settings(body, current_user)


@router.get(
    "/billing-target",
    response_model=ParentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get billing target parent",
)
async def get_billing_target_for_student(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentResponse:
    """Return the billing target parent for a student."""
    service = ParentService(db)
    return await service.get_billing_target_for_student(student_id, current_user)


@router.get(
    "/me/children/{student_id}/lessons",
    response_model=list[LessonResponse],
    status_code=status.HTTP_200_OK,
    summary="Child's lessons",
)
async def get_child_lessons(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
    date_from: str | None = None,
    date_to: str | None = None,
) -> list[LessonResponse]:
    """Return lessons for a linked child."""
    service = ParentService(db)
    return await service.get_child_lessons(
        student_id,
        current_user,
        date_from=date_from,
        date_to=date_to,
    )


@router.get(
    "/me/children/{student_id}/practice",
    response_model=PracticeStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Child's practice stats",
)
async def get_child_practice(
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_parent)],
    year: int | None = None,
    month: int | None = None,
) -> PracticeStatsResponse:
    """Return practice statistics for a linked child."""
    service = ParentService(db)
    return await service.get_child_practice(
        student_id,
        current_user,
        year=year,
        month=month,
    )


@router.get(
    "/visibility-settings",
    response_model=ParentVisibilitySettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get parent visibility settings",
)
async def get_visibility_settings(
    teacher_id: str,
    student_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentVisibilitySettingsResponse:
    """Return parent visibility settings for a teacher/student pair."""
    service = ParentService(db)
    return await service.get_visibility_settings(teacher_id, student_id, current_user)


@router.put(
    "/visibility-settings",
    response_model=ParentVisibilitySettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Save parent visibility settings",
)
async def save_visibility_settings(
    body: ParentVisibilitySettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentVisibilitySettingsResponse:
    """Create or update parent visibility settings."""
    service = ParentService(db)
    return await service.save_visibility_settings(body, current_user)


@router.get(
    "/{parent_id}",
    response_model=ParentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get parent profile by ID",
)
async def get_parent(
    parent_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ParentResponse:
    """Return a parent profile by ID."""
    service = ParentService(db)
    return await service.get_parent(parent_id, current_user)


@router.delete(
    "/{parent_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete parent profile",
)
async def delete_parent(
    parent_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a parent profile."""
    service = ParentService(db)
    await service.delete_parent(parent_id, current_user)
