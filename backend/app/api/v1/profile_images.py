"""Profile image upload endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.profile_image import ProfileImageDeleteResponse, ProfileImageUploadResponse
from app.services.profile_image_service import ProfileImageService

router = APIRouter()


@router.post(
    "/upload",
    response_model=ProfileImageUploadResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Upload profile or background image",
)
async def upload_image(
    file: Annotated[UploadFile, File(...)],
    image_type: Annotated[str, Form()] = "profile",
    entity_type: Annotated[str, Form()] = "teacher",
    entity_id: Annotated[str | None, Form()] = None,
    *,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ProfileImageUploadResponse:
    """Upload a profile or background image.

    - image_type: "profile" (1:1) or "background" (16:9)
    - entity_type: "teacher" or "student"
    - entity_id: student ID (for student images); defaults to current user ID
    """
    service = ProfileImageService()
    result = await service.upload(
        file=file,
        image_type=image_type,
        user_id=current_user.id,
        entity_type=entity_type,
        entity_id=entity_id,
    )

    # Update the user's profile image URL in the database
    if image_type == "profile":
        await _update_profile_image(db, current_user, entity_type, entity_id, result.image_url)
    elif image_type == "background":
        await _update_background_image(db, current_user, entity_type, entity_id, result.image_url)

    await db.commit()
    return result


@router.delete(
    "",
    response_model=ProfileImageDeleteResponse,
    status_code=status.HTTP_200_OK,
    summary="Delete profile or background image",
)
async def delete_image(
    image_type: str = "profile",
    entity_type: str = "teacher",
    entity_id: str | None = None,
    *,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> ProfileImageDeleteResponse:
    """Delete a profile or background image and reset to default."""
    if image_type == "profile":
        await _update_profile_image(db, current_user, entity_type, entity_id, None)
    elif image_type == "background":
        await _update_background_image(db, current_user, entity_type, entity_id, None)

    await db.commit()
    return ProfileImageDeleteResponse()


async def _update_profile_image(
    db: AsyncSession, current_user: User, entity_type: str,
    entity_id: str | None, image_url: str | None,
) -> None:
    """Update profile_image_url in the appropriate table."""
    if entity_type == "teacher":
        from app.models.user import User as UserModel
        user = await db.get(UserModel, current_user.id)
        if user:
            user.profile_image_url = image_url
            await db.flush()
    elif entity_type == "student" and entity_id:
        from app.models.student import Student
        student = await db.get(Student, entity_id)
        if student:
            student.profile_image_url = image_url
            await db.flush()


async def _update_background_image(
    db: AsyncSession, current_user: User, entity_type: str,
    entity_id: str | None, image_url: str | None,
) -> None:
    """Update background_image_url in the appropriate table."""
    if entity_type == "teacher":
        from sqlalchemy import select
        from app.models.teacher import Teacher
        teacher = await db.scalar(
            select(Teacher).where(Teacher.user_id == current_user.id)
        )
        if teacher:
            teacher.background_image = image_url
            await db.flush()
    elif entity_type == "student" and entity_id:
        from app.models.student import Student
        student = await db.get(Student, entity_id)
        if student:
            student.background_image_url = image_url
            await db.flush()
