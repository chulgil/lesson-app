"""Academy announcement endpoints — AC-M3.

Spec: docs/specs/web/academy/announcements_spec.md §2-§3.

POST   /academies/{academy_id}/announcements   — 학원장 단방향 공지 draft 생성
GET    /academies/{academy_id}/announcements   — 학원 멤버 목록 조회
GET    /academies/announcements/{id}           — 단건 조회

권한:
- POST: 학원장 + ``require_owner_context`` (context_toggle_spec §6.2 차단 매트릭스)
- GET (목록/단건): 학원 멤버 — active_context 무관
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_owner_context
from app.core.deps import get_current_user, get_db
from app.models.user import User
from app.schemas.academy_announcement import (
    AcademyAnnouncementCreate,
    AcademyAnnouncementListResponse,
    AcademyAnnouncementResponse,
)
from app.services.academy_announcement_service import AcademyAnnouncementService

router = APIRouter()


@router.post(
    "/{academy_id}/announcements",
    response_model=AcademyAnnouncementResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create academy announcement (owner only, draft state)",
    dependencies=[Depends(require_owner_context)],
)
async def create_academy_announcement(
    academy_id: str,
    body: AcademyAnnouncementCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyAnnouncementResponse:
    service = AcademyAnnouncementService(db)
    announcement = await service.create_draft(
        academy_id=academy_id,
        by_user_id=current_user.id,
        body=body,
    )
    return AcademyAnnouncementResponse.model_validate(announcement)


@router.get(
    "/{academy_id}/announcements",
    response_model=AcademyAnnouncementListResponse,
    status_code=status.HTTP_200_OK,
    summary="List academy announcements (members only)",
)
async def list_academy_announcements(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyAnnouncementListResponse:
    service = AcademyAnnouncementService(db)
    announcements, total = await service.list_for_academy(
        academy_id=academy_id,
        by_user_id=current_user.id,
    )
    return AcademyAnnouncementListResponse(
        announcements=[AcademyAnnouncementResponse.model_validate(a) for a in announcements],
        total_count=total,
    )


@router.get(
    "/announcements/{announcement_id}",
    response_model=AcademyAnnouncementResponse,
    status_code=status.HTTP_200_OK,
    summary="Get academy announcement detail (members only)",
)
async def get_academy_announcement(
    announcement_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyAnnouncementResponse:
    service = AcademyAnnouncementService(db)
    announcement = await service.get_announcement(
        announcement_id=announcement_id,
        by_user_id=current_user.id,
    )
    return AcademyAnnouncementResponse.model_validate(announcement)


__all__ = ["router"]
