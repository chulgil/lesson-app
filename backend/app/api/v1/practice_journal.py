"""Practice journal endpoints (#872).

6 endpoints, 3 auth principals:
  Student   — upsert_mark, self-endorse, list/bind volumes
  Guardian  — seal week
  Teacher   — teacher-endorse

Ledger (GET) is accessible to student-self | guardian | teacher (assert_can_read).

No DB queries in this router (arch contract).  All ownership checks are in
PracticeJournalService which raises PermissionError / ValueError / RuntimeError.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_student, get_current_teacher, get_db
from app.core.deps import get_current_user as _get_current_user
from app.models.user import User
from app.schemas.practice_journal import (
    BindVolumeRequest,
    BoundVolumeResponse,
    EndorsementRequest,
    EndorsementResponse,
    GuardianSealRequest,
    GuardianSealResponse,
    LedgerResponse,
    MarkUpsertRequest,
    PracticeMarkResponse,
)
from app.services.practice_journal_service import PracticeJournalService

router = APIRouter()

# ---------------------------------------------------------------------------
# 1. Ledger — read access (student-self | guardian | teacher)
# ---------------------------------------------------------------------------


@router.get(
    "/ledger",
    response_model=LedgerResponse,
    status_code=status.HTTP_200_OK,
    summary="Monthly practice ledger (student-self | guardian | teacher)",
)
async def get_ledger(
    child_profile_id: Annotated[str, Query(description="Student.id")],
    year: Annotated[int, Query(ge=2020, le=2100)],
    month: Annotated[int, Query(ge=1, le=12)],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(_get_current_user)],
) -> LedgerResponse:
    svc = PracticeJournalService(db)
    try:
        await svc.assert_can_read(child_profile_id, current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    return await svc.get_ledger(child_profile_id, year, month)


# ---------------------------------------------------------------------------
# 2. Mark upsert — student-self only
# ---------------------------------------------------------------------------


@router.post(
    "/marks",
    response_model=PracticeMarkResponse,
    status_code=status.HTTP_200_OK,
    summary="Upsert a daily practice mark (student-self only)",
)
async def upsert_mark(
    body: MarkUpsertRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> PracticeMarkResponse:
    svc = PracticeJournalService(db)
    try:
        await svc.assert_is_student_self(body.child_profile_id, current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    return await svc.upsert_mark(body)


# ---------------------------------------------------------------------------
# 3. Guardian seal — guardian only
# ---------------------------------------------------------------------------


@router.post(
    "/seals",
    response_model=GuardianSealResponse,
    status_code=status.HTTP_200_OK,
    summary="Apply a weekly guardian seal (guardian only, idempotent)",
)
async def add_seal(
    body: GuardianSealRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(_get_current_user)],
) -> GuardianSealResponse:
    svc = PracticeJournalService(db)
    try:
        await svc.assert_is_guardian(body.child_profile_id, current_user.id)
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    return await svc.add_seal(body, guardian_user_id=current_user.id)


# ---------------------------------------------------------------------------
# 4. Self-endorsement — student-self only
# ---------------------------------------------------------------------------


@router.post(
    "/endorsements/self",
    response_model=EndorsementResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Self endorsement by student",
)
async def add_self_endorsement(
    body: EndorsementRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> EndorsementResponse:
    if body.by != "self":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Use /endorsements/teacher for teacher endorsements",
        )
    svc = PracticeJournalService(db)
    try:
        await svc.assert_is_student_self(body.child_profile_id, current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    try:
        return await svc.add_endorsement(body, author_user_id=current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc


# ---------------------------------------------------------------------------
# 5. Teacher endorsement — teacher only
# ---------------------------------------------------------------------------


@router.post(
    "/endorsements/teacher",
    response_model=EndorsementResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Teacher endorsement",
)
async def add_teacher_endorsement(
    body: EndorsementRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> EndorsementResponse:
    if body.by != "teacher":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Use /endorsements/self for self endorsements",
        )
    svc = PracticeJournalService(db)
    try:
        await svc.assert_is_teacher_of(body.child_profile_id, current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    try:
        return await svc.add_endorsement(body, author_user_id=current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc


# ---------------------------------------------------------------------------
# 6. Volumes — student-self (list + bind)
# ---------------------------------------------------------------------------


@router.get(
    "/volumes",
    response_model=list[BoundVolumeResponse],
    status_code=status.HTTP_200_OK,
    summary="List bound volumes for a student (student-self | guardian | teacher)",
)
async def list_volumes(
    child_profile_id: Annotated[str, Query(description="Student.id")],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(_get_current_user)],
) -> list[BoundVolumeResponse]:
    svc = PracticeJournalService(db)
    try:
        await svc.assert_can_read(child_profile_id, current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    return await svc.list_volumes(child_profile_id)


@router.post(
    "/volumes",
    response_model=BoundVolumeResponse,
    status_code=status.HTTP_200_OK,
    summary="Bind a completed piece into a volume (student-self only, idempotent)",
)
async def bind_volume(
    body: BindVolumeRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> BoundVolumeResponse:
    svc = PracticeJournalService(db)
    try:
        await svc.assert_is_student_self(body.child_profile_id, current_user.id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    try:
        return await svc.bind_volume(body)
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc


__all__ = ["router"]
