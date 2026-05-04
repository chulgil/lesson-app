"""Manual teacher service."""

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.manual_teacher import ManualTeacher
from app.schemas.common import PaginatedResponse
from app.schemas.manual_teacher import (
    ManualTeacherCreate,
    ManualTeacherResponse,
    ManualTeacherUpdate,
)


class ManualTeacherService:
    """Manage user-owned manual teacher records."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_manual_teachers(
        self, user: Any, *, page: int, size: int, offset: int
    ) -> PaginatedResponse[ManualTeacherResponse]:
        query = select(ManualTeacher).where(ManualTeacher.owner_id == user.id)
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0
        result = await self.db.scalars(
            query.order_by(ManualTeacher.created_at.desc()).offset(offset).limit(size)
        )
        items = [ManualTeacherResponse.model_validate(item) for item in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_manual_teacher(self, teacher_id: str, user: Any) -> ManualTeacherResponse:
        teacher = await self._get_owned(teacher_id, user.id)
        return ManualTeacherResponse.model_validate(teacher)

    async def create_manual_teacher(
        self, data: ManualTeacherCreate, user: Any
    ) -> ManualTeacherResponse:
        payload = data.model_dump(exclude_none=True)
        teacher = ManualTeacher(owner_id=user.id, **payload)
        self.db.add(teacher)
        await self.db.flush()
        await self.db.refresh(teacher)
        return ManualTeacherResponse.model_validate(teacher)

    async def update_manual_teacher(
        self, teacher_id: str, data: ManualTeacherUpdate, user: Any
    ) -> ManualTeacherResponse:
        teacher = await self._get_owned(teacher_id, user.id)
        for key, value in data.model_dump(exclude_none=True).items():
            setattr(teacher, key, value)
        await self.db.flush()
        await self.db.refresh(teacher)
        return ManualTeacherResponse.model_validate(teacher)

    async def delete_manual_teacher(self, teacher_id: str, user: Any) -> None:
        teacher = await self._get_owned(teacher_id, user.id)
        await self.db.delete(teacher)
        await self.db.flush()

    async def _get_owned(self, teacher_id: str, owner_id: str) -> ManualTeacher:
        teacher = await self.db.get(ManualTeacher, teacher_id)
        if teacher is None or teacher.owner_id != owner_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Manual teacher not found")
        return teacher
