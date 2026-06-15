"""Makeup credit endpoints (#432 Make-up Bank).

Spec: docs/specs/subscription/makeup_credit_spec.md §8.1.
FE contract: frontend/lib/features/subscription/data/repositories/remote_makeup_credit_repository.dart.

Two router objects exported — student-side and teacher-side — because the
URL prefixes differ (`/students/me/...` vs `/teachers/me/...`).
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_student, get_current_teacher, get_db
from app.models.makeup_credit import MakeupCreditReason as ModelReason
from app.models.user import User
from app.schemas.makeup_credit import (
    MakeupCreditGrantRequest,
    MakeupCreditListResponse,
    MakeupCreditResponse,
)
from app.services.makeup_credit_service import MakeupCreditService
from app.services.student_id_resolver import resolve_student_id
from app.services.teacher_id_resolver import resolve_teacher_id

student_router = APIRouter()
teacher_router = APIRouter()


# ----------------------------------------------------------------------
# Student-side: /students/me/makeup-credits
# ----------------------------------------------------------------------


@student_router.get(
    "",
    response_model=MakeupCreditListResponse,
    status_code=status.HTTP_200_OK,
    summary="List the signed-in student's active makeup credits",
)
async def list_my_makeup_credits(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_student)],
) -> MakeupCreditListResponse:
    """Spec §8.1 — student-side view. Active (unused + not expired) only."""
    student_id = await resolve_student_id(db, current_user.id)
    service = MakeupCreditService(db)
    credits = await service.list_active_credits(student_id=student_id)
    return MakeupCreditListResponse(
        credits=[MakeupCreditResponse.model_validate(c) for c in credits],
    )


# ----------------------------------------------------------------------
# Teacher-side: /teachers/me/makeup-credits
# ----------------------------------------------------------------------


@teacher_router.get(
    "",
    response_model=MakeupCreditListResponse,
    status_code=status.HTTP_200_OK,
    summary="List credits the teacher issued for one student",
)
async def list_teacher_credits_for_student(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    student_id: Annotated[str, Query(description="Filter to one student's credits")],
) -> MakeupCreditListResponse:
    """Spec §8.1 — teacher management view. All statuses for the given student."""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = MakeupCreditService(db)
    all_for_student = await service.list_by_student(student_id)
    scoped = [c for c in all_for_student if c.teacher_id == teacher_id]
    return MakeupCreditListResponse(
        credits=[MakeupCreditResponse.model_validate(c) for c in scoped],
    )


@teacher_router.post(
    "",
    response_model=MakeupCreditResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Teacher manual grant of a makeup credit (§4.4 safety net)",
)
async def grant_makeup_credit(
    body: MakeupCreditGrantRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> MakeupCreditResponse:
    """Spec §4.4 — manual grant. Default 30-day expiry from service."""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = MakeupCreditService(db)

    # Issue #741: verify the target student belongs to this teacher. The DB
    # query lives in the service layer (routers must not query directly).
    try:
        await service.assert_student_belongs_to_teacher(body.student_id, teacher_id)
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc

    credit = await service.accrue(
        student_id=body.student_id,
        teacher_id=teacher_id,
        reason=ModelReason.manualGrant,
        source_subscription_id=body.source_subscription_id,
        # reason_note (free-form audit text) is intentionally dropped today —
        # no column in MakeupCredit model. Future: persist on a separate
        # audit log if the §9.2 management UI surfaces it.
    )
    return MakeupCreditResponse.model_validate(credit)


@teacher_router.delete(
    "/{credit_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Revoke an unused makeup credit (cleanup of a mistaken grant)",
)
async def revoke_makeup_credit(
    credit_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    """Spec §8.1 — teacher revoke. 409 if already used."""
    teacher_id = await resolve_teacher_id(db, current_user.id)
    service = MakeupCreditService(db)
    try:
        await service.revoke_credit(credit_id=credit_id, teacher_id=teacher_id)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except PermissionError as exc:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(exc)) from exc
    except RuntimeError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc


__all__ = ["student_router", "teacher_router"]
