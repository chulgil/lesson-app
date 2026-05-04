"""Practice endpoints: repertoires, sections, goals, stats."""

from __future__ import annotations

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse, SuccessResponse
from app.schemas.practice import (
    PracticeGoalResponse,
    PracticeGoalUpdate,
    PracticeStatsResponse,
    PracticeStreakResponse,
    RepertoireCreate,
    RepertoireResponse,
    RepertoireUpdate,
    SectionCompleteRequest,
    SectionCreate,
    SectionNoteCreate,
    SectionResponse,
    SectionUpdate,
)
from app.services.practice_service import PracticeService

router = APIRouter()


# ---------------------------------------------------------------------------
# Repertoires
# ---------------------------------------------------------------------------


@router.get(
    "/repertoires",
    response_model=PaginatedResponse[RepertoireResponse],
    status_code=status.HTTP_200_OK,
    summary="List repertoires",
)
async def list_repertoires(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    pagination: Annotated[dict, Depends(get_pagination)],
    student_id: str | None = None,
    include_archived: bool = False,
    repertoire_date: str | None = None,
) -> PaginatedResponse[RepertoireResponse]:
    """List repertoires for a student."""
    service = PracticeService(db)
    return await service.get_all_repertoires(
        user=current_user,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        student_id=student_id,
        include_archived=include_archived,
        date=repertoire_date,
    )


@router.post(
    "/repertoires",
    response_model=RepertoireResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create repertoire",
)
async def create_repertoire(
    body: RepertoireCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepertoireResponse:
    """Create a new repertoire (optionally with inline sections)."""
    service = PracticeService(db)
    return await service.create_repertoire(body, current_user)


@router.get(
    "/repertoires/date/{repertoire_date}",
    response_model=list[RepertoireResponse],
    status_code=status.HTTP_200_OK,
    summary="Repertoires active on a date",
)
async def get_repertoires_by_date(
    repertoire_date: date,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
) -> list[RepertoireResponse]:
    """Return repertoires active on a specific date."""
    service = PracticeService(db)
    return await service.get_repertoires_by_date(repertoire_date, student_id, current_user)


@router.get(
    "/repertoires/{repertoire_id}",
    response_model=RepertoireResponse,
    status_code=status.HTTP_200_OK,
    summary="Get repertoire detail",
)
async def get_repertoire(
    repertoire_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepertoireResponse:
    """Return a repertoire with its sections."""
    service = PracticeService(db)
    return await service.get_repertoire_by_id(repertoire_id, current_user)


@router.put(
    "/repertoires/{repertoire_id}",
    response_model=RepertoireResponse,
    status_code=status.HTTP_200_OK,
    summary="Update repertoire",
)
async def update_repertoire(
    repertoire_id: str,
    body: RepertoireUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RepertoireResponse:
    """Update repertoire fields."""
    service = PracticeService(db)
    return await service.update_repertoire(repertoire_id, body, current_user)


@router.delete(
    "/repertoires/{repertoire_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Archive repertoire",
)
async def delete_repertoire(
    repertoire_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Archive (soft-delete) a repertoire."""
    service = PracticeService(db)
    await service.delete_repertoire(repertoire_id, current_user)


# ---------------------------------------------------------------------------
# Sections
# ---------------------------------------------------------------------------


@router.post(
    "/sections",
    response_model=SectionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add section to repertoire",
)
async def create_section(
    body: SectionCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SectionResponse:
    """Add a new section to a repertoire."""
    service = PracticeService(db)
    return await service.create_section(body, current_user)


@router.put(
    "/sections/{section_id}",
    response_model=SectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Update section",
)
async def update_section(
    section_id: str,
    body: SectionUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SectionResponse:
    """Update section fields."""
    service = PracticeService(db)
    return await service.update_section(section_id, body, current_user)


@router.delete(
    "/sections/{section_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete section",
)
async def delete_section(
    section_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    """Delete a section."""
    service = PracticeService(db)
    await service.delete_section(section_id, current_user)


@router.patch(
    "/sections/{section_id}/complete",
    response_model=SectionResponse,
    status_code=status.HTTP_200_OK,
    summary="Toggle section completion",
)
async def toggle_section_complete(
    section_id: str,
    body: SectionCompleteRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SectionResponse:
    """Mark / unmark a section as completed for a specific date."""
    service = PracticeService(db)
    return await service.toggle_section_complete(section_id, body, current_user)


@router.post(
    "/sections/{section_id}/notes",
    response_model=SuccessResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add practice note",
)
async def add_section_note(
    section_id: str,
    body: SectionNoteCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> SuccessResponse:
    """Add a practice note to a section."""
    service = PracticeService(db)
    await service.add_section_note(section_id, body, current_user)
    return SuccessResponse(message="Note added")


# ---------------------------------------------------------------------------
# Goals, streak, stats
# ---------------------------------------------------------------------------


@router.get(
    "/goals",
    response_model=PracticeGoalResponse,
    status_code=status.HTTP_200_OK,
    summary="Get practice goals",
)
async def get_goals(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
) -> PracticeGoalResponse:
    """Get practice goal settings for a student."""
    service = PracticeService(db)
    return await service.get_goals(student_id, current_user)


@router.put(
    "/goals",
    response_model=PracticeGoalResponse,
    status_code=status.HTTP_200_OK,
    summary="Set practice goals",
)
async def set_goals(
    body: PracticeGoalUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> PracticeGoalResponse:
    """Create or update practice goals."""
    service = PracticeService(db)
    return await service.set_goals(body, current_user)


@router.get(
    "/streak",
    response_model=PracticeStreakResponse,
    status_code=status.HTTP_200_OK,
    summary="Get practice streak",
)
async def get_streak(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
) -> PracticeStreakResponse:
    """Get current and longest practice streak."""
    service = PracticeService(db)
    return await service.get_streak(student_id, current_user)


@router.put(
    "/streak",
    response_model=PracticeStreakResponse,
    status_code=status.HTTP_200_OK,
    summary="Update practice streak",
)
async def update_streak(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
) -> PracticeStreakResponse:
    """Ensure the streak record exists and return it."""
    service = PracticeService(db)
    return await service.update_streak(student_id, current_user)


@router.post(
    "/streak/record",
    response_model=PracticeStreakResponse,
    status_code=status.HTTP_200_OK,
    summary="Record practice streak",
)
async def record_practice(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
) -> PracticeStreakResponse:
    """Record today's practice and update streak counters."""
    service = PracticeService(db)
    return await service.record_practice(student_id, current_user)


@router.get(
    "/stats",
    response_model=PracticeStatsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get practice statistics",
)
async def get_stats(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    student_id: str | None = None,
    year: int | None = None,
    month: int | None = None,
) -> PracticeStatsResponse:
    """Get monthly practice statistics."""
    service = PracticeService(db)
    return await service.get_stats(student_id, year, month, current_user)
