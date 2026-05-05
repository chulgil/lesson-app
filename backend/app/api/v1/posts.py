"""Teacher/academy post feed endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.post import TeacherPostCreate, TeacherPostResponse
from app.services.post_service import PostService

router = APIRouter()


@router.get(
    "",
    response_model=PaginatedResponse[TeacherPostResponse],
    status_code=status.HTTP_200_OK,
)
async def list_posts(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    author_id: str | None = None,
    author_ids: str | None = None,
) -> PaginatedResponse[TeacherPostResponse]:
    service = PostService(db)
    return await service.list_posts(
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        author_id=author_id,
        author_ids=author_ids,
    )


@router.post(
    "",
    response_model=TeacherPostResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_post(
    body: TeacherPostCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherPostResponse:
    service = PostService(db)
    return await service.create_post(body, current_user)
