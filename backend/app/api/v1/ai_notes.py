"""AI lesson notes endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.context_deps import require_teacher_context
from app.core.deps import get_current_teacher, get_db
from app.models.user import User
from app.schemas.ai_notes import AiNoteResponse
from app.services.ai_notes_service import AiNotesService

# AC-M2 권한 매트릭스: 학원장 모드 JWT → 403 (학생 노트 접근 차단).
router = APIRouter(dependencies=[Depends(require_teacher_context)])


@router.post(
    "/generate",
    response_model=AiNoteResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generate AI lesson notes from recording",
)
async def generate_ai_notes(
    file: Annotated[UploadFile, File(...)],
    lesson_id: Annotated[str, Form()],
    student_name: Annotated[str | None, Form()] = None,
    instrument: Annotated[str | None, Form()] = None,
    level: Annotated[str | None, Form()] = None,
    pieces: Annotated[str | None, Form()] = None,
    *,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> AiNoteResponse:
    """Upload a lesson recording and generate structured notes.

    Pipeline: Audio → Whisper STT → GPT-4o-mini → Structured Notes

    - file: M4A audio recording (max 50MB)
    - lesson_id: ID of the lesson to attach notes to
    - pieces: comma-separated list of piece names (optional)
    """
    pieces_list = [p.strip() for p in pieces.split(",")] if pieces else []

    service = AiNotesService(db)
    return await service.generate_from_upload(
        file=file,
        lesson_id=lesson_id,
        student_name=student_name,
        instrument=instrument,
        level=level,
        pieces=pieces_list,
        current_user=current_user,
    )


@router.get(
    "/{lesson_id}",
    response_model=AiNoteResponse | None,
    status_code=status.HTTP_200_OK,
    summary="Get AI notes for a lesson",
)
async def get_ai_notes(
    lesson_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> AiNoteResponse | None:
    """Return existing AI-generated notes for a lesson."""
    service = AiNotesService(db)
    return await service.get_by_lesson_id(lesson_id, current_user)
