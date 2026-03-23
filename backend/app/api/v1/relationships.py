"""Relationship and follow endpoints."""

from __future__ import annotations

from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import BaseModel, ConfigDict
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.services.relationship_service import RelationshipService

router = APIRouter()


# ---------------------------------------------------------------------------
# Inline schemas (relationship-specific, small enough to keep here)
# ---------------------------------------------------------------------------


class InviteRequest(BaseModel):
    """Send an invitation to a student."""

    student_id: str
    method: str = "sms"


class ConnectRequest(BaseModel):
    """Accept an invitation via code."""

    invite_code: str


class RelationshipStatusUpdate(BaseModel):
    """Change relationship status with optional metadata."""

    status: str
    # Optional fields for subscription/booking tracking
    subscription_id: str | None = None
    booking_id: str | None = None
    # Optional fields for schedule recording
    last_lesson_day: str | None = None
    last_lesson_time: str | None = None
    last_lesson_duration: int | None = None


class RelationshipResponse(BaseModel):
    """Relationship representation."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    teacher_id: str | None = None
    student_id: str | None = None
    status: str | None = None
    invite_code: str | None = None
    connected_at: datetime | None = None
    disconnected_at: datetime | None = None

    # Subscription tracking
    active_subscription_id: str | None = None
    last_subscription_expired_at: datetime | None = None
    expired_until: datetime | None = None

    # Trial tracking
    trial_booking_id: str | None = None

    # Lesson tracking
    total_lesson_count: int = 0
    last_lesson_at: datetime | None = None

    # Registration type
    is_manually_registered: bool = False
    is_app_connected: bool = False
    app_connected_at: datetime | None = None

    # Schedule restoration
    last_lesson_day: str | None = None
    last_lesson_time: str | None = None
    last_lesson_duration: int | None = None
    schedule_recorded_at: datetime | None = None

    # Termination
    terminated_by: str | None = None
    termination_reason: str | None = None

    created_at: datetime | None = None


class FollowRequest(BaseModel):
    """Follow a user."""

    following_id: str
    target_type: str = "teacher"


class FollowResponse(BaseModel):
    """Follow record."""

    model_config = ConfigDict(from_attributes=True)

    id: str
    follower_id: str
    following_id: str
    target_type: str | None = None
    created_at: datetime | None = None


# ---------------------------------------------------------------------------
# Relationships
# ---------------------------------------------------------------------------


@router.post(
    "/relationships/invite",
    response_model=RelationshipResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Invite student (teacher only)",
)
async def invite_student(
    body: InviteRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> RelationshipResponse:
    """Send an invitation to connect with a student."""
    service = RelationshipService(db)
    return await service.invite(body.student_id, body.method, current_user)


@router.post(
    "/relationships/connect",
    response_model=RelationshipResponse,
    status_code=status.HTTP_200_OK,
    summary="Accept invite (student)",
)
async def connect_with_teacher(
    body: ConnectRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RelationshipResponse:
    """Accept an invitation via invite code."""
    service = RelationshipService(db)
    return await service.connect(body.invite_code, current_user)


@router.get(
    "/relationships/{relationship_id}",
    response_model=RelationshipResponse,
    status_code=status.HTTP_200_OK,
    summary="Get relationship by ID",
)
async def get_relationship(
    relationship_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RelationshipResponse:
    """Return a single relationship by ID."""
    service = RelationshipService(db)
    return await service.get_by_id(relationship_id, current_user)


@router.get(
    "/relationships",
    response_model=PaginatedResponse[RelationshipResponse],
    status_code=status.HTTP_200_OK,
    summary="List my relationships",
)
async def list_relationships(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[RelationshipResponse]:
    """List all relationships for the current user."""
    service = RelationshipService(db)
    return await service.get_all(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.patch(
    "/relationships/{relationship_id}/status",
    response_model=RelationshipResponse,
    status_code=status.HTTP_200_OK,
    summary="Change relationship status",
)
async def update_relationship_status(
    relationship_id: str,
    body: RelationshipStatusUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RelationshipResponse:
    """Change the status of a relationship (e.g. disconnect)."""
    service = RelationshipService(db)
    return await service.update_status(
        relationship_id, body.status, current_user,
        subscription_id=body.subscription_id,
        booking_id=body.booking_id,
        last_lesson_day=body.last_lesson_day,
        last_lesson_time=body.last_lesson_time,
        last_lesson_duration=body.last_lesson_duration,
    )


# ---------------------------------------------------------------------------
# Follows
# ---------------------------------------------------------------------------


@router.post(
    "/follows",
    response_model=FollowResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Follow",
)
async def follow(
    body: FollowRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> FollowResponse:
    """Follow a teacher or other user."""
    service = RelationshipService(db)
    return await service.follow(body.following_id, body.target_type, current_user)


@router.delete(
    "/follows/{follow_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Unfollow",
)
async def unfollow(
    follow_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Unfollow."""
    service = RelationshipService(db)
    await service.unfollow(follow_id, current_user)
