"""User profile endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.user import (
    LocaleUpdate,
    OnboardingProgressResponse,
    OnboardingProgressUpdate,
    OnboardingQuestListResponse,
    RoleUpdate,
    SupportedLocalesResponse,
    UserResponse,
    UserUpdate,
)
from app.services.user_service import UserService

router = APIRouter()


@router.get(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my profile",
)
async def get_my_profile(
    current_user: Annotated[User, Depends(get_current_user)],
) -> UserResponse:
    """Return the current user's profile."""
    return UserResponse.model_validate(current_user)


@router.put(
    "/me",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Update my profile",
)
async def update_my_profile(
    body: UserUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    """Update the current user's profile fields."""
    service = UserService(db)
    user = await service.update_profile(current_user.id, body)
    return UserResponse.model_validate(user)


@router.put(
    "/me/role",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Set role (onboarding)",
)
async def update_my_role(
    body: RoleUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    """Set the user's role during onboarding."""
    service = UserService(db)
    user = await service.update_role(current_user.id, body.role)
    return UserResponse.model_validate(user)


@router.put(
    "/me/locale",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Update locale settings",
)
async def update_my_locale(
    body: LocaleUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    """Update locale / country / timezone / currency."""
    service = UserService(db)
    user = await service.update_locale(current_user.id, body)
    return UserResponse.model_validate(user)


@router.patch(
    "/me/onboarding-complete",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark onboarding as completed",
)
async def complete_onboarding(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    """Mark the current user's onboarding as completed."""
    service = UserService(db)
    user = await service.complete_onboarding(current_user.id)
    return UserResponse.model_validate(user)


@router.patch(
    "/me/quest-celebrated",
    response_model=UserResponse,
    status_code=status.HTTP_200_OK,
    summary="Mark 11/11 quest celebration card shown",
)
async def mark_quest_celebrated(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UserResponse:
    """#608 Job 7 — Idempotently flip ``quest_celebrated_at`` on first dismiss/action.

    Subsequent calls (e.g. duplicate taps) do not modify the column so the
    celebration card remains a one-shot UI surface.
    """
    service = UserService(db)
    user = await service.mark_quest_celebrated(current_user.id)
    return UserResponse.model_validate(user)


@router.get(
    "/me/onboarding-progress",
    response_model=OnboardingProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Get onboarding progress",
)
async def get_onboarding_progress(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> OnboardingProgressResponse:
    """Return onboarding quest v2 progress for the current user."""
    service = UserService(db)
    return await service.get_onboarding_progress(current_user)


@router.patch(
    "/me/onboarding-progress",
    response_model=OnboardingProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Update onboarding progress",
)
async def update_onboarding_progress(
    body: OnboardingProgressUpdate,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> OnboardingProgressResponse:
    """Patch onboarding quest v2 progress fields."""
    service = UserService(db)
    return await service.update_onboarding_progress(current_user, body)


@router.get(
    "/me/quests",
    response_model=OnboardingQuestListResponse,
    status_code=status.HTTP_200_OK,
    summary="List onboarding quests",
)
async def get_onboarding_quests(
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> OnboardingQuestListResponse:
    """Return role-specific onboarding quests for the current user."""
    service = UserService(db)
    return await service.get_onboarding_quests(current_user)


@router.post(
    "/me/quests/{quest_id}/complete",
    response_model=OnboardingProgressResponse,
    status_code=status.HTTP_200_OK,
    summary="Complete onboarding quest",
)
async def complete_onboarding_quest(
    quest_id: str,
    current_user: Annotated[User, Depends(get_current_user)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> OnboardingProgressResponse:
    """Mark an onboarding quest complete for the current user."""
    service = UserService(db)
    return await service.complete_onboarding_quest(current_user, quest_id)


@router.get(
    "/supported-locales",
    response_model=SupportedLocalesResponse,
    status_code=status.HTTP_200_OK,
    summary="List supported locales",
)
async def get_supported_locales() -> SupportedLocalesResponse:
    """Return the list of locales the application supports."""
    return UserService.get_supported_locales()
