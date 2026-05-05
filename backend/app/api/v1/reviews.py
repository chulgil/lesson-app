"""Teacher review endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.review import (
    TeacherReviewCreate,
    TeacherReviewResponse,
    TeacherReviewSummary,
    TeacherReviewUpdate,
)
from app.services.review_service import ReviewService

router = APIRouter()


@router.get(
    "/{teacher_id}",
    response_model=PaginatedResponse[TeacherReviewResponse],
    status_code=status.HTTP_200_OK,
    summary="List reviews for a teacher",
)
async def list_reviews(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
) -> PaginatedResponse[TeacherReviewResponse]:
    service = ReviewService(db)
    return await service.get_reviews(
        teacher_id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
    )


@router.get(
    "/{teacher_id}/summary",
    response_model=TeacherReviewSummary,
    status_code=status.HTTP_200_OK,
    summary="Get review summary for a teacher",
)
async def get_review_summary(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherReviewSummary:
    service = ReviewService(db)
    data = await service.get_review_summary(teacher_id)
    return TeacherReviewSummary.model_validate(data)


@router.post(
    "/",
    response_model=TeacherReviewResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a review",
)
async def create_review(
    body: TeacherReviewCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherReviewResponse:
    service = ReviewService(db)
    result: TeacherReviewResponse = await service.create_review(body.model_dump(), current_user)
    return result


@router.put(
    "/{review_id}",
    response_model=TeacherReviewResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a review",
)
async def update_review(
    review_id: str,
    body: TeacherReviewUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherReviewResponse:
    service = ReviewService(db)
    result: TeacherReviewResponse = await service.update_review(
        review_id, body.model_dump(exclude_none=True), current_user
    )
    return result


@router.delete(
    "/{review_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a review",
)
async def delete_review(
    review_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    service = ReviewService(db)
    await service.delete_review(review_id, current_user)
