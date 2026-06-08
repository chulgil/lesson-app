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
    service = ProfileImageService(db)
    result = await service.upload(
        file=file,
        image_type=image_type,
        user_id=current_user.id,
        entity_type=entity_type,
        entity_id=entity_id,
    )

    # Update the user's profile image URL in the database
    if image_type == "profile":
        await service.update_profile_image(
            current_user_id=current_user.id,
            entity_type=entity_type,
            entity_id=entity_id,
            image_url=result.image_url,
        )
    elif image_type == "background":
        await service.update_background_image(
            current_user_id=current_user.id,
            entity_type=entity_type,
            entity_id=entity_id,
            image_url=result.image_url,
        )

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
    service = ProfileImageService(db)
    if image_type == "profile":
        await service.update_profile_image(
            current_user_id=current_user.id,
            entity_type=entity_type,
            entity_id=entity_id,
            image_url=None,
        )
    elif image_type == "background":
        await service.update_background_image(
            current_user_id=current_user.id,
            entity_type=entity_type,
            entity_id=entity_id,
            image_url=None,
        )
    else:
        # 알 수 없는 image_type 은 silently 200 으로 응답하지 않고 명시적 422.
        from fastapi import HTTPException

        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Unknown image_type: {image_type}",
        )

    return ProfileImageDeleteResponse()
