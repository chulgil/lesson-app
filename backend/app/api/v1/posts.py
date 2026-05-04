"""Teacher/academy post feed endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.post import TeacherPost
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.post import TeacherPostCreate, TeacherPostResponse
from app.services.teacher_id_resolver import resolve_teacher_id

router = APIRouter()


@router.get("", response_model=PaginatedResponse[TeacherPostResponse])
async def list_posts(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    author_id: str | None = None,
    author_ids: str | None = None,
) -> PaginatedResponse[TeacherPostResponse]:
    query = select(TeacherPost)
    if author_id:
        query = query.where(TeacherPost.author_id == author_id)
    if author_ids:
        author_id_list = [item.strip() for item in author_ids.split(",") if item.strip()]
        if author_id_list:
            query = query.where(TeacherPost.author_id.in_(author_id_list))

    total = await db.scalar(select(func.count()).select_from(query.subquery())) or 0
    result = await db.scalars(
        query.order_by(TeacherPost.created_at.desc()).offset(pagination["offset"]).limit(pagination["size"])
    )
    return PaginatedResponse.create(
        items=[TeacherPostResponse.model_validate(post) for post in result.all()],
        total=total,
        page=pagination["page"],
        size=pagination["size"],
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
    teacher_id = await resolve_teacher_id(db, current_user.id)
    allowed_author_ids = {current_user.id, teacher_id}
    if body.author_id not in allowed_author_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot create a post for another author",
        )
    post = TeacherPost(**body.model_dump())
    db.add(post)
    await db.flush()
    await db.refresh(post)
    return TeacherPostResponse.model_validate(post)
