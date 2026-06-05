"""Academy announcement endpoints — AC-M3.

Spec: docs/specs/web/academy/announcements_spec.md §2-§3.

POST   /academies/{academy_id}/announcements                  — 학원장 단방향 공지 draft 생성
GET    /academies/{academy_id}/announcements/audience-preview — 작성 미리보기 (대상 수, owner)
GET    /academies/{academy_id}/announcements                  — 학원 멤버 목록 조회
GET    /academies/announcements/{id}                          — 단건 조회

권한:
- POST + audience-preview: 학원장 + ``require_owner_context`` (context_toggle_spec §6.2)
- GET (목록/단건): 학원 멤버 — active_context 무관
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_owner_context
from app.core.deps import get_current_user, get_db
from app.models.academy_announcement import AcademyAnnouncementAudience as ModelAudience
from app.models.user import User
from app.schemas.academy_announcement import (
    AcademyAnnouncementAudience,
    AcademyAnnouncementAudiencePreviewResponse,
    AcademyAnnouncementCreate,
    AcademyAnnouncementListResponse,
    AcademyAnnouncementResponse,
    AudienceCountByRole,
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
    "/{academy_id}/announcements/audience-preview",
    response_model=AcademyAnnouncementAudiencePreviewResponse,
    status_code=status.HTTP_200_OK,
    summary="Preview target count by audience (owner only) — spec §3.1 대상 수 미리보기",
    dependencies=[Depends(require_owner_context)],
)
async def preview_announcement_audience(
    academy_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    audience: Annotated[AcademyAnnouncementAudience, Query()],
    teacher_member_id: Annotated[str | None, Query(max_length=36)] = None,
) -> AcademyAnnouncementAudiencePreviewResponse:
    """공지 작성 화면에서 대상 수를 미리 보여주는 헬퍼 (spec §3.1).

    teacher_member_id 쿼리는 audience=teacher_students 일 때 audience_filter
    로 들어간다.
    """
    audience_filter = {"teacher_member_id": teacher_member_id} if teacher_member_id else None
    service = AcademyAnnouncementService(db)
    result = await service.resolve_audience_count(
        academy_id=academy_id,
        by_user_id=current_user.id,
        audience=ModelAudience(audience.value),
        audience_filter=audience_filter,
    )
    return AcademyAnnouncementAudiencePreviewResponse(
        target_count=result["target_count"],
        by_role=AudienceCountByRole(**result["by_role"]),
    )


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


@router.post(
    "/announcements/{announcement_id}/send",
    response_model=AcademyAnnouncementResponse,
    status_code=status.HTTP_200_OK,
    summary="Send announcement (owner only) — draft → sent + recipient fanout",
    dependencies=[Depends(require_owner_context)],
)
async def send_academy_announcement(
    announcement_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AcademyAnnouncementResponse:
    """draft → sent. 대상자 enumerate + AcademyAnnouncementRecipient N행 생성.

    spec §4 발송 시퀀스 — 인앱은 즉시 마킹, 카톡/푸시 채널은 별도 큐 작업.
    """
    service = AcademyAnnouncementService(db)
    sent = await service.send_announcement(
        announcement_id=announcement_id,
        by_user_id=current_user.id,
    )
    return AcademyAnnouncementResponse.model_validate(sent)


@router.patch(
    "/announcements/{announcement_id}/recipients/me/read",
    status_code=status.HTTP_200_OK,
    summary="Mark announcement as read (recipient self, idempotent)",
)
async def mark_announcement_read(
    announcement_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> dict[str, object]:
    """수신자 본인이 공지를 열람한 시점을 기록 (spec §6.1 인앱 자동 마킹)."""
    service = AcademyAnnouncementService(db)
    recipient = await service.mark_read(
        announcement_id=announcement_id,
        user_id=current_user.id,
    )
    return {
        "announcement_id": recipient.announcement_id,
        "user_id": recipient.user_id,
        "read_at": recipient.read_at.isoformat() if recipient.read_at else None,
    }


__all__ = ["router"]
