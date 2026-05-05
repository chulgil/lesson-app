"""Teacher post service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.post import TeacherPostCreate, TeacherPostResponse
from app.services.teacher_id_resolver import resolve_teacher_id


class PostService:
    """Manage teacher and academy feed posts."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_posts(
        self,
        *,
        page: int,
        size: int,
        offset: int,
        author_id: str | None = None,
        author_ids: str | None = None,
    ) -> PaginatedResponse[TeacherPostResponse]:
        from app.models.post import TeacherPost

        query = select(TeacherPost)
        if author_id:
            query = query.where(TeacherPost.author_id == author_id)
        if author_ids:
            author_id_list = [item.strip() for item in author_ids.split(",") if item.strip()]
            if author_id_list:
                query = query.where(TeacherPost.author_id.in_(author_id_list))

        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0
        result = await self.db.scalars(
            query.order_by(TeacherPost.created_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(
            items=[TeacherPostResponse.model_validate(post) for post in result.all()],
            total=total,
            page=page,
            size=size,
        )

    async def create_post(self, body: TeacherPostCreate, current_user: Any) -> TeacherPostResponse:
        from app.models.post import TeacherPost

        teacher_id = await resolve_teacher_id(self.db, current_user.id)
        allowed_author_ids = {current_user.id, teacher_id}
        if body.author_id not in allowed_author_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot create a post for another author",
            )
        post = TeacherPost(**body.model_dump())
        self.db.add(post)
        await self.db.flush()
        await self.db.refresh(post)
        return TeacherPostResponse.model_validate(post)
