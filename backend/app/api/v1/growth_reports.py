"""Child growth-report sharing endpoints (#1217, teacher-authenticated mint)."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_teacher_context
from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.share import GrowthReportShareRequest, GrowthReportShareResponse
from app.services.share_token_service import ShareTokenService

# 학원장 모드 JWT → 403 (성장 리포트 공유는 강사 권한). lesson_summaries.py 미러.
router = APIRouter(dependencies=[Depends(require_teacher_context)])


@router.post(
    "/{student_id}/share",
    response_model=GrowthReportShareResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create child growth-report share token",
)
async def create_growth_report_share(
    student_id: str,
    body: GrowthReportShareRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> GrowthReportShareResponse:
    """Issue a public share token for a teacher-owned child's growth report."""
    service = ShareTokenService(db)
    return await service.issue_growth_report_share(
        student_id=student_id,
        expires_in_hours=body.expires_in_hours,
        current_user=current_user,
    )
