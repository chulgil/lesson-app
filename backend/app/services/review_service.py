"""Teacher review service."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse


class ReviewService:
    """Handle teacher reviews."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_reviews(
        self,
        teacher_id: str,
        *,
        page: int,
        size: int,
        offset: int,
    ) -> PaginatedResponse:
        """List reviews for a teacher."""
        from app.models.review import TeacherReview

        query = select(TeacherReview).where(
            TeacherReview.teacher_id == teacher_id,
            TeacherReview.is_active.is_(True),
        )
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0

        result = await self.db.scalars(query.order_by(TeacherReview.created_at.desc()).offset(offset).limit(size))
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def create_review(self, data: dict, current_user: Any) -> Any:
        """Create a review."""
        from app.models.review import TeacherReview

        review = TeacherReview(
            teacher_id=data["teacher_id"],
            teacher_name="",  # will be filled by caller
            student_id=current_user.id,
            student_name=current_user.name,
            author_type="student" if current_user.role == "student" else "parent",
            author_id=current_user.id,
            author_name=current_user.name,
            rating=data["rating"],
            content=data.get("content"),
            tags=data.get("tags", []),
            visibility=data.get("visibility", "public"),
            is_anonymous=data.get("is_anonymous", False),
            is_verified=await self._has_completed_lesson(data["teacher_id"], current_user.id),
        )
        self.db.add(review)
        await self.db.flush()
        await self.db.refresh(review)
        return review

    async def _has_completed_lesson(self, teacher_id: str, student_id: str) -> bool:
        """Whether student_id has a completed Lesson with teacher_id (verified-reviewer signal)."""
        from app.models.lesson import Lesson, LessonStatus
        from app.services.teacher_id_resolver import try_resolve_teacher_id

        resolved_teacher_id = await try_resolve_teacher_id(self.db, teacher_id)
        if resolved_teacher_id is None:
            return False

        completed_lesson_id = await self.db.scalar(
            select(Lesson.id).where(
                Lesson.teacher_id == resolved_teacher_id,
                Lesson.student_id == student_id,
                Lesson.status == LessonStatus.completed,
            )
        )
        return completed_lesson_id is not None

    async def update_review(self, review_id: str, data: dict, current_user: Any) -> Any:
        """Update a review."""
        from app.models.review import TeacherReview

        review = await self.db.get(TeacherReview, review_id)
        if review is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")
        if review.author_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your review")
        for key, value in data.items():
            if value is not None:
                setattr(review, key, value)
        await self.db.flush()
        await self.db.refresh(review)
        return review

    async def delete_review(self, review_id: str, current_user: Any) -> None:
        """Soft-delete a review."""
        from app.models.review import TeacherReview

        review = await self.db.get(TeacherReview, review_id)
        if review is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")
        if review.author_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your review")
        review.is_active = False
        await self.db.flush()

    async def get_review_summary(self, teacher_id: str) -> dict[str, Any]:
        """Get aggregated review stats."""
        from app.models.review import TeacherReview

        base = select(TeacherReview).where(
            TeacherReview.teacher_id == teacher_id,
            TeacherReview.is_active.is_(True),
        )

        total = await self.db.scalar(select(func.count()).select_from(base.subquery())) or 0
        avg = (
            await self.db.scalar(
                select(func.avg(TeacherReview.rating)).where(
                    TeacherReview.teacher_id == teacher_id,
                    TeacherReview.is_active.is_(True),
                )
            )
            or 0.0
        )
        student_count = (
            await self.db.scalar(
                select(func.count()).where(
                    TeacherReview.teacher_id == teacher_id,
                    TeacherReview.is_active.is_(True),
                    TeacherReview.author_type == "student",
                )
            )
            or 0
        )
        parent_count = (
            await self.db.scalar(
                select(func.count()).where(
                    TeacherReview.teacher_id == teacher_id,
                    TeacherReview.is_active.is_(True),
                    TeacherReview.author_type == "parent",
                )
            )
            or 0
        )

        return {
            "teacher_id": teacher_id,
            "average_rating": round(float(avg), 1),
            "total_reviews": total,
            "student_reviews": student_count,
            "parent_reviews": parent_count,
            "rating_distribution": {},
        }
