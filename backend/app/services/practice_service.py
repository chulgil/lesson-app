"""Practice service – repertoires, sections, goals, stats."""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.practice import (
    DailyStat,
    PracticeGoalResponse,
    PracticeGoalUpdate,
    PracticePieceCreate,
    PracticePieceResponse,
    PracticePieceUpdate,
    PracticeStatsResponse,
    PracticeStreakResponse,
    RecordingMetadataCreate,
    RecordingReassignUpdate,
    RecordingResponse,
    RepertoireCreate,
    RepertoireResponse,
    RepertoireUpdate,
    RepresentativeRecordingUpdate,
    SectionCompleteRequest,
    SectionCreate,
    SectionNoteCreate,
    SectionNoteResponse,
    SectionNoteUpdate,
    SectionOrderUpdate,
    SectionPracticeCountUpdate,
    SectionResponse,
    SectionUpdate,
    StudentPieceProgressUpdate,
    StudentPieceRepertoireResponse,
)


class PracticeService:
    """Handle practice repertoires, sections, goals, and statistics."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Piece library
    # ------------------------------------------------------------------

    async def create_piece(self, data: PracticePieceCreate, current_user: Any) -> PracticePieceResponse:
        """Create a teacher-owned practice piece."""
        from app.models.practice import PracticePiece

        teacher_id = await self._teacher_profile_id(current_user)
        piece = PracticePiece(
            owner_teacher_id=teacher_id,
            title=data.title,
            composer=data.composer,
            opus=data.opus,
            movement=data.movement,
            difficulty=data.difficulty,
            notes=data.notes,
        )
        self.db.add(piece)
        await self.db.flush()
        await self.db.refresh(piece)
        return self._piece_response(piece)

    async def list_pieces(self, current_user: Any) -> list[PracticePieceResponse]:
        """List practice pieces visible to the current user."""
        from app.models.practice import PracticePiece

        query = select(PracticePiece).order_by(PracticePiece.created_at.desc())
        if self._role(current_user) == "teacher":
            query = query.where(PracticePiece.owner_teacher_id == await self._teacher_profile_id(current_user))
        result = await self.db.scalars(query)
        return [self._piece_response(piece) for piece in result.all()]

    async def search_pieces(self, query_text: str, current_user: Any) -> list[PracticePieceResponse]:
        """Search visible pieces by title or composer."""
        from app.models.practice import PracticePiece

        pattern = f"%{query_text}%"
        query = select(PracticePiece).where(
            (PracticePiece.title.ilike(pattern)) | (PracticePiece.composer.ilike(pattern))
        )
        if self._role(current_user) == "teacher":
            query = query.where(PracticePiece.owner_teacher_id == await self._teacher_profile_id(current_user))
        result = await self.db.scalars(query.order_by(PracticePiece.created_at.desc()))
        return [self._piece_response(piece) for piece in result.all()]

    async def get_piece(self, piece_id: str, current_user: Any) -> PracticePieceResponse:
        """Return a practice piece."""
        piece = await self._get_piece_for_user(piece_id, current_user)
        return self._piece_response(piece)

    async def update_piece(
        self,
        piece_id: str,
        data: PracticePieceUpdate,
        current_user: Any,
    ) -> PracticePieceResponse:
        """Update a teacher-owned practice piece."""
        piece = await self._get_piece_for_teacher(piece_id, current_user)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(piece, key, value)
        await self.db.flush()
        await self.db.refresh(piece)
        return self._piece_response(piece)

    async def delete_piece(self, piece_id: str, current_user: Any) -> None:
        """Delete a teacher-owned practice piece."""
        piece = await self._get_piece_for_teacher(piece_id, current_user)
        await self.db.delete(piece)
        await self.db.flush()

    async def get_student_piece_repertoire(
        self,
        student_id: str,
        current_user: Any,
    ) -> StudentPieceRepertoireResponse:
        """Return assigned pieces split into current and completed buckets."""
        from app.models.practice import PracticePiece, StudentPracticePiece

        await self._assert_can_read_student(student_id, current_user)
        rows = await self.db.execute(
            select(PracticePiece, StudentPracticePiece)
            .join(StudentPracticePiece, StudentPracticePiece.piece_id == PracticePiece.id)
            .where(StudentPracticePiece.student_id == student_id)
            .order_by(StudentPracticePiece.created_at.desc())
        )
        current: list[PracticePieceResponse] = []
        completed: list[PracticePieceResponse] = []
        for piece, assignment in rows.all():
            response = self._piece_response(piece, assignment)
            if response.progress == "completed":
                completed.append(response)
            else:
                current.append(response)
        return StudentPieceRepertoireResponse(
            student_id=student_id,
            current_pieces=current,
            completed_pieces=completed,
        )

    async def assign_piece_to_student(self, student_id: str, piece_id: str, current_user: Any) -> PracticePieceResponse:
        """Assign a piece to a student."""
        from app.models.practice import StudentPracticePiece

        await self._assert_can_manage_student(student_id, current_user)
        piece = await self._get_piece_for_teacher(piece_id, current_user)
        assignment = await self.db.scalar(
            select(StudentPracticePiece).where(
                StudentPracticePiece.student_id == student_id,
                StudentPracticePiece.piece_id == piece_id,
            )
        )
        if assignment is None:
            assignment = StudentPracticePiece(student_id=student_id, piece_id=piece_id)
            self.db.add(assignment)
            await self.db.flush()
            await self.db.refresh(assignment)
        return self._piece_response(piece, assignment)

    async def remove_piece_from_student(self, student_id: str, piece_id: str, current_user: Any) -> None:
        """Remove an assigned piece from a student."""
        from app.models.practice import StudentPracticePiece

        await self._assert_can_manage_student(student_id, current_user)
        assignment = await self.db.scalar(
            select(StudentPracticePiece).where(
                StudentPracticePiece.student_id == student_id,
                StudentPracticePiece.piece_id == piece_id,
            )
        )
        if assignment is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student piece assignment not found")
        await self.db.delete(assignment)
        await self.db.flush()

    async def update_student_piece_progress(
        self,
        student_id: str,
        piece_id: str,
        data: StudentPieceProgressUpdate,
        current_user: Any,
    ) -> PracticePieceResponse:
        """Update progress for a student's assigned piece."""
        from datetime import datetime

        from app.models.practice import PieceProgress, PracticePiece, StudentPracticePiece

        await self._assert_can_manage_student(student_id, current_user)
        row = await self.db.execute(
            select(PracticePiece, StudentPracticePiece)
            .join(StudentPracticePiece, StudentPracticePiece.piece_id == PracticePiece.id)
            .where(
                StudentPracticePiece.student_id == student_id,
                StudentPracticePiece.piece_id == piece_id,
            )
        )
        result = row.first()
        if result is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student piece assignment not found")
        piece, assignment = result
        assignment.progress = PieceProgress(data.progress)
        assignment.progress_percentage = self._progress_percentage(data.progress)
        now = datetime.now(UTC)
        if data.progress != "notStarted" and assignment.started_at is None:
            assignment.started_at = now
        if data.progress == "completed":
            assignment.completed_at = now
        elif assignment.completed_at is not None:
            assignment.completed_at = None
        await self.db.flush()
        await self.db.refresh(assignment)
        return self._piece_response(piece, assignment)

    # ------------------------------------------------------------------
    # Repertoires
    # ------------------------------------------------------------------

    async def get_all_repertoires(
        self,
        *,
        user: Any,
        page: int,
        size: int,
        offset: int,
        student_id: str | None = None,
        include_archived: bool = False,
        date: str | None = None,
    ) -> PaginatedResponse[RepertoireResponse]:
        """List repertoires with filters."""
        from app.models.practice import PracticeRepertoire

        query = select(PracticeRepertoire)
        if student_id:
            query = query.where(PracticeRepertoire.student_id == student_id)
        if not include_archived:
            query = query.where(PracticeRepertoire.is_archived == False)  # noqa: E712

        count_query = select(func.count()).select_from(query.subquery())
        total = await self.db.scalar(count_query) or 0

        result = await self.db.scalars(query.offset(offset).limit(size))
        items = [RepertoireResponse.model_validate(r) for r in result.all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def create_repertoire(self, data: RepertoireCreate, current_user: Any) -> RepertoireResponse:
        """Create a repertoire with optional inline sections."""
        from app.models.practice import PracticeRepertoire, PracticeSection

        repertoire = PracticeRepertoire(
            student_id=data.student_id,
            name=data.name,
            start_date=data.start_date or date.today(),
            end_date=data.end_date,
        )
        self.db.add(repertoire)
        await self.db.flush()

        # Create inline sections
        for i, sec_data in enumerate(data.sections):
            section = PracticeSection(
                repertoire_id=repertoire.id,
                piece_name=sec_data.piece_name or "Untitled",
                range_type=sec_data.range_type or "full",
                start_measure=sec_data.start_measure or 1,
                end_measure=sec_data.end_measure or 1,
                is_repeat=sec_data.is_repeat,
                sort_order=i,
            )
            self.db.add(section)

        await self.db.flush()
        await self.db.refresh(repertoire)
        return RepertoireResponse.model_validate(repertoire)

    async def get_repertoires_by_date(
        self, target_date: date, student_id: str | None, current_user: Any
    ) -> list[RepertoireResponse]:
        """Return repertoires active on a specific date."""
        from app.models.practice import PracticeRepertoire

        query = select(PracticeRepertoire).where(
            PracticeRepertoire.is_archived == False,  # noqa: E712
            PracticeRepertoire.start_date <= target_date,
        )
        if student_id:
            query = query.where(PracticeRepertoire.student_id == student_id)

        # end_date can be null (ongoing)
        query = query.where(
            (PracticeRepertoire.end_date >= target_date) | (PracticeRepertoire.end_date == None)  # noqa: E711
        )

        result = await self.db.scalars(query)
        return [RepertoireResponse.model_validate(r) for r in result.all()]

    async def get_repertoire_by_id(self, repertoire_id: str, current_user: Any) -> RepertoireResponse:
        """Return a single repertoire with sections."""
        from app.models.practice import PracticeRepertoire

        rep = await self.db.get(PracticeRepertoire, repertoire_id)
        if rep is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")
        return RepertoireResponse.model_validate(rep)

    async def update_repertoire(
        self, repertoire_id: str, data: RepertoireUpdate, current_user: Any
    ) -> RepertoireResponse:
        """Update repertoire fields."""
        from app.models.practice import PracticeRepertoire

        rep = await self.db.get(PracticeRepertoire, repertoire_id)
        if rep is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(rep, key, value)
        await self.db.flush()
        await self.db.refresh(rep)
        return RepertoireResponse.model_validate(rep)

    async def delete_repertoire(self, repertoire_id: str, current_user: Any) -> None:
        """Archive a repertoire."""
        from app.models.practice import PracticeRepertoire

        rep = await self.db.get(PracticeRepertoire, repertoire_id)
        if rep is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")
        rep.is_archived = True
        await self.db.flush()

    async def archive_repertoire(self, repertoire_id: str, current_user: Any) -> RepertoireResponse:
        """Archive a repertoire and return it."""
        rep = await self._get_repertoire_for_user(repertoire_id, current_user, manage=True)
        rep.is_archived = True
        await self.db.flush()
        await self.db.refresh(rep)
        return RepertoireResponse.model_validate(rep)

    async def restore_repertoire(self, repertoire_id: str, current_user: Any) -> RepertoireResponse:
        """Restore an archived repertoire."""
        rep = await self._get_repertoire_for_user(repertoire_id, current_user, manage=True)
        rep.is_archived = False
        rep.archived_at = None
        await self.db.flush()
        await self.db.refresh(rep)
        return RepertoireResponse.model_validate(rep)

    async def permanently_delete_repertoire(self, repertoire_id: str, current_user: Any) -> None:
        """Permanently delete a repertoire and dependent practice rows."""
        from app.models.practice import DailyPracticeStatus, PracticeNote, PracticeRecording, PracticeSection

        rep = await self._get_repertoire_for_user(repertoire_id, current_user, manage=True)
        section_ids = list(
            (
                await self.db.scalars(
                    select(PracticeSection.id).where(PracticeSection.repertoire_id == repertoire_id)
                )
            ).all()
        )
        if section_ids:
            for model, column in [
                (PracticeNote, PracticeNote.section_id),
                (DailyPracticeStatus, DailyPracticeStatus.section_id),
                (PracticeRecording, PracticeRecording.section_id),
                (PracticeSection, PracticeSection.id),
            ]:
                rows = await self.db.scalars(select(model).where(column.in_(section_ids)))
                for row in rows.all():
                    await self.db.delete(row)
        await self.db.delete(rep)
        await self.db.flush()

    # ------------------------------------------------------------------
    # Sections
    # ------------------------------------------------------------------

    async def create_section(self, data: SectionCreate, current_user: Any) -> SectionResponse:
        """Add a section to a repertoire."""
        from app.models.practice import PracticeSection

        section = PracticeSection(
            repertoire_id=data.repertoire_id,
            piece_name=data.piece_name or "Untitled",
            range_type=data.range_type or "full",
            start_measure=data.start_measure or 1,
            end_measure=data.end_measure or 1,
            is_repeat=data.is_repeat,
        )
        self.db.add(section)
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def update_section(
        self, section_id: str, data: SectionUpdate, current_user: Any
    ) -> SectionResponse:
        """Update a section."""
        from app.models.practice import PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(section, key, value)
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def get_section(self, section_id: str, current_user: Any) -> SectionResponse:
        """Return section detail."""
        section = await self._get_section_for_user(section_id, current_user)
        return SectionResponse.model_validate(section)

    async def delete_section(self, section_id: str, current_user: Any) -> None:
        """Delete a section."""
        from app.models.practice import PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")
        await self.db.delete(section)
        await self.db.flush()

    async def toggle_section_complete(
        self, section_id: str, data: SectionCompleteRequest, current_user: Any
    ) -> SectionResponse:
        """Toggle section completion for a given date."""
        from app.models.practice import DailyPracticeStatus, PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")

        # Update or create daily status
        existing = await self.db.scalar(
            select(DailyPracticeStatus).where(
                DailyPracticeStatus.section_id == section_id,
                DailyPracticeStatus.date == data.date,
            )
        )
        if existing:
            existing.is_completed = data.is_completed
        else:
            daily = DailyPracticeStatus(
                section_id=section_id,
                date=data.date,
                is_completed=data.is_completed,
            )
            self.db.add(daily)

        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def toggle_daily_completion(self, section_id: str, target_date: date, current_user: Any) -> SectionResponse:
        """Toggle per-day section completion."""
        from app.models.practice import DailyPracticeStatus

        section = await self._get_section_for_user(section_id, current_user, manage=True)
        existing = await self.db.scalar(
            select(DailyPracticeStatus).where(
                DailyPracticeStatus.section_id == section_id,
                DailyPracticeStatus.date == target_date,
            )
        )
        if existing is None:
            self.db.add(
                DailyPracticeStatus(
                    section_id=section_id,
                    date=target_date,
                    is_completed=True,
                    completed_at=datetime.now(UTC),
                )
            )
            section.is_completed = True
        else:
            existing.is_completed = not existing.is_completed
            existing.completed_at = datetime.now(UTC) if existing.is_completed else None
            section.is_completed = existing.is_completed
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def toggle_section_repeat(self, section_id: str, current_user: Any) -> SectionResponse:
        """Toggle section repeat flag."""
        section = await self._get_section_for_user(section_id, current_user, manage=True)
        section.is_repeat = not section.is_repeat
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def increment_practice_count(
        self,
        section_id: str,
        data: SectionPracticeCountUpdate,
        current_user: Any,
    ) -> SectionResponse:
        """Increment practice count and seconds for a section."""
        section = await self._get_section_for_user(section_id, current_user, manage=True)
        section.practice_count += 1
        section.total_practice_seconds += data.practice_seconds
        section.last_practiced_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def update_last_practiced_at(self, section_id: str, current_user: Any) -> SectionResponse:
        """Set last_practiced_at to now."""
        section = await self._get_section_for_user(section_id, current_user, manage=True)
        section.last_practiced_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(section)
        return SectionResponse.model_validate(section)

    async def update_section_orders(
        self,
        repertoire_id: str,
        data: SectionOrderUpdate,
        current_user: Any,
    ) -> None:
        """Persist section sort order for a repertoire."""
        from app.models.practice import PracticeSection

        await self._get_repertoire_for_user(repertoire_id, current_user, manage=True)
        sections = await self.db.scalars(
            select(PracticeSection).where(
                PracticeSection.repertoire_id == repertoire_id,
                PracticeSection.id.in_(data.section_ids),
            )
        )
        by_id = {section.id: section for section in sections.all()}
        for index, section_id in enumerate(data.section_ids):
            if section_id in by_id:
                by_id[section_id].sort_order = index
        await self.db.flush()

    async def add_section_note(
        self, section_id: str, data: SectionNoteCreate, current_user: Any
    ) -> SectionNoteResponse:
        """Add a practice note to a section."""
        from app.models.practice import PracticeNote

        await self._get_section_for_user(section_id, current_user, manage=True)
        note = PracticeNote(
            section_id=section_id,
            content=data.content,
        )
        self.db.add(note)
        await self.db.flush()
        await self.db.refresh(note)
        return SectionNoteResponse.model_validate(note)

    async def get_section_notes(self, section_id: str, current_user: Any) -> list[SectionNoteResponse]:
        """Return notes for a section."""
        from app.models.practice import PracticeNote

        await self._get_section_for_user(section_id, current_user)
        notes = await self.db.scalars(
            select(PracticeNote).where(PracticeNote.section_id == section_id).order_by(PracticeNote.created_at.desc())
        )
        return [SectionNoteResponse.model_validate(note) for note in notes.all()]

    async def update_note(
        self,
        note_id: str,
        data: SectionNoteUpdate,
        current_user: Any,
    ) -> SectionNoteResponse:
        """Update a practice note."""
        note = await self._get_note_for_user(note_id, current_user, manage=True)
        note.content = data.content
        await self.db.flush()
        await self.db.refresh(note)
        return SectionNoteResponse.model_validate(note)

    async def delete_note(self, note_id: str, current_user: Any) -> None:
        """Delete a practice note."""
        note = await self._get_note_for_user(note_id, current_user, manage=True)
        await self.db.delete(note)
        await self.db.flush()

    async def create_recording_metadata(
        self,
        data: RecordingMetadataCreate,
        current_user: Any,
    ) -> RecordingResponse:
        """Create recording metadata without object storage upload."""
        from app.models.practice import PracticeRecording

        section = await self._get_section_for_user(data.section_id, current_user, manage=True)
        student_id = await self._student_id_for_section(section.id)
        recording = PracticeRecording(
            section_id=section.id,
            student_id=student_id,
            file_path=data.file_path,
            file_key=data.file_path,
            file_url=data.file_path,
            duration_seconds=data.duration_seconds,
            bpm=data.bpm,
        )
        self.db.add(recording)
        await self.db.flush()
        await self.db.refresh(recording)
        return RecordingResponse.model_validate(recording)

    async def set_section_representative_recording(
        self,
        section_id: str,
        data: RepresentativeRecordingUpdate,
        current_user: Any,
    ) -> RecordingResponse:
        """Set representative recording for a section."""
        from app.models.practice import PracticeRecording

        await self._get_section_for_user(section_id, current_user, manage=True)
        recording = await self.db.get(PracticeRecording, data.recording_id)
        if recording is None or recording.section_id != section_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")
        existing = await self.db.scalars(
            select(PracticeRecording).where(
                PracticeRecording.section_id == section_id,
                PracticeRecording.is_representative == True,  # noqa: E712
            )
        )
        for other in existing.all():
            other.is_representative = False
        recording.is_representative = True
        await self.db.flush()
        await self.db.refresh(recording)
        return RecordingResponse.model_validate(recording)

    async def get_orphaned_recordings(self, current_user: Any) -> list[RecordingResponse]:
        """Return visible recordings whose section no longer exists."""
        from app.models.practice import PracticeRecording, PracticeSection

        recordings = await self.db.scalars(select(PracticeRecording).order_by(PracticeRecording.created_at.desc()))
        section_ids = set((await self.db.scalars(select(PracticeSection.id))).all())
        visible: list[RecordingResponse] = []
        for recording in recordings.all():
            if recording.section_id in section_ids:
                continue
            if await self._can_read_student(recording.student_id, current_user):
                visible.append(RecordingResponse.model_validate(recording))
        return visible

    async def reassign_recording(
        self,
        recording_id: str,
        data: RecordingReassignUpdate,
        current_user: Any,
    ) -> RecordingResponse:
        """Reassign a recording to another section."""
        from app.models.practice import PracticeRecording

        target_section = await self._get_section_for_user(data.section_id, current_user, manage=True)
        recording = await self.db.get(PracticeRecording, recording_id)
        if recording is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recording not found")
        if not await self._can_read_student(recording.student_id, current_user):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        recording.section_id = target_section.id
        recording.student_id = await self._student_id_for_section(target_section.id)
        await self.db.flush()
        await self.db.refresh(recording)
        return RecordingResponse.model_validate(recording)

    # ------------------------------------------------------------------
    # Goals
    # ------------------------------------------------------------------

    async def get_goals(self, student_id: str | None, current_user: Any) -> PracticeGoalResponse:
        """Get practice goals for a student."""
        from app.models.practice import PracticeGoal

        sid = student_id or current_user.id
        goal = await self.db.scalar(
            select(PracticeGoal).where(PracticeGoal.student_id == sid)
        )
        if goal is None:
            return PracticeGoalResponse(student_id=sid)
        return PracticeGoalResponse.model_validate(goal)

    async def set_goals(self, data: PracticeGoalUpdate, current_user: Any) -> PracticeGoalResponse:
        """Create or update practice goals."""
        from app.models.practice import PracticeGoal

        existing = await self.db.scalar(
            select(PracticeGoal).where(PracticeGoal.student_id == data.student_id)
        )
        if existing:
            update_data = data.model_dump(exclude_unset=True, exclude={"student_id"})
            for key, value in update_data.items():
                setattr(existing, key, value)
        else:
            existing = PracticeGoal(
                student_id=data.student_id,
                daily_time_minutes=data.daily_time_minutes,
                daily_section_count=data.daily_section_count,
                weekly_time_minutes=data.weekly_time_minutes,
                weekly_day_count=data.weekly_day_count,
            )
            self.db.add(existing)

        await self.db.flush()
        await self.db.refresh(existing)
        return PracticeGoalResponse.model_validate(existing)

    # ------------------------------------------------------------------
    # Streak & Stats
    # ------------------------------------------------------------------

    async def get_streak(self, student_id: str | None, current_user: Any) -> PracticeStreakResponse:
        """Get current and longest streak."""
        from app.models.practice import PracticeStreak

        sid = student_id or current_user.id
        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )
        if streak is None:
            return PracticeStreakResponse()
        return PracticeStreakResponse.model_validate(streak)

    async def update_streak(self, student_id: str | None, current_user: Any) -> PracticeStreakResponse:
        """Ensure a streak row exists and return it."""
        from app.models.practice import PracticeStreak

        sid = student_id or current_user.id
        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )
        if streak is None:
            streak = PracticeStreak(student_id=sid)
            self.db.add(streak)
            await self.db.flush()
            await self.db.refresh(streak)
        return PracticeStreakResponse.model_validate(streak)

    async def record_practice(self, student_id: str | None, current_user: Any) -> PracticeStreakResponse:
        """Record today's practice and update the streak counters."""
        from app.models.practice import PracticeStreak

        sid = student_id or current_user.id
        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )
        if streak is None:
            streak = PracticeStreak(student_id=sid)
            self.db.add(streak)

        today = date.today()
        if streak.last_practice_date == today:
            await self.db.flush()
            await self.db.refresh(streak)
            return PracticeStreakResponse.model_validate(streak)

        if streak.last_practice_date == today - timedelta(days=1):
            streak.current_streak += 1
        else:
            streak.current_streak = 1

        streak.longest_streak = max(streak.longest_streak, streak.current_streak)
        streak.last_practice_date = today
        streak.total_practice_days += 1
        await self.db.flush()
        await self.db.refresh(streak)
        return PracticeStreakResponse.model_validate(streak)

    async def get_stats(
        self, student_id: str | None, year: int | None, month: int | None, current_user: Any
    ) -> PracticeStatsResponse:
        """Get monthly practice statistics from DailyPracticeStatus."""
        from datetime import date as date_cls

        from app.models.practice import DailyPracticeStatus, PracticeRepertoire, PracticeSection, PracticeStreak

        sid = student_id or current_user.id
        today = date_cls.today()
        target_year = year or today.year
        target_month = month or today.month

        first_day = date_cls(target_year, target_month, 1)
        if target_month == 12:
            last_day = date_cls(target_year + 1, 1, 1)
        else:
            last_day = date_cls(target_year, target_month + 1, 1)

        section_ids_query = (
            select(PracticeSection.id)
            .join(PracticeRepertoire, PracticeSection.repertoire_id == PracticeRepertoire.id)
            .where(PracticeRepertoire.student_id == sid)
        )

        statuses = await self.db.scalars(
            select(DailyPracticeStatus).where(
                DailyPracticeStatus.section_id.in_(section_ids_query),
                DailyPracticeStatus.date >= first_day,
                DailyPracticeStatus.date < last_day,
            )
        )
        all_statuses = statuses.all()

        daily_map: dict[str, DailyStat] = {}
        completed_sections = 0
        for s in all_statuses:
            day_key = s.date.isoformat()
            if day_key not in daily_map:
                daily_map[day_key] = DailyStat()
            if s.is_completed:
                daily_map[day_key].sections_completed += 1
                completed_sections += 1

        total_minutes_result = await self.db.scalar(
            select(func.coalesce(func.sum(PracticeSection.total_practice_seconds), 0))
            .where(
                PracticeSection.repertoire_id.in_(
                    select(PracticeRepertoire.id).where(PracticeRepertoire.student_id == sid)
                )
            )
        )
        total_minutes = (total_minutes_result or 0) // 60

        streak = await self.db.scalar(
            select(PracticeStreak).where(PracticeStreak.student_id == sid)
        )

        return PracticeStatsResponse(
            total_practice_minutes=total_minutes,
            total_practice_days=len(daily_map),
            completed_sections=completed_sections,
            current_streak=streak.current_streak if streak else 0,
            longest_streak=streak.longest_streak if streak else 0,
            daily_stats=daily_map,
        )

    # ------------------------------------------------------------------
    # Access and mapping helpers
    # ------------------------------------------------------------------

    async def _get_repertoire_for_user(self, repertoire_id: str, current_user: Any, *, manage: bool = False) -> Any:
        from app.models.practice import PracticeRepertoire

        repertoire = await self.db.get(PracticeRepertoire, repertoire_id)
        if repertoire is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")
        if manage:
            await self._assert_can_manage_student(repertoire.student_id, current_user)
        else:
            await self._assert_can_read_student(repertoire.student_id, current_user)
        return repertoire

    async def _get_section_for_user(self, section_id: str, current_user: Any, *, manage: bool = False) -> Any:
        from app.models.practice import PracticeRepertoire, PracticeSection

        section = await self.db.get(PracticeSection, section_id)
        if section is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")
        student_id = await self.db.scalar(
            select(PracticeRepertoire.student_id).where(PracticeRepertoire.id == section.repertoire_id)
        )
        if student_id is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Repertoire not found")
        if manage:
            await self._assert_can_manage_student(student_id, current_user)
        else:
            await self._assert_can_read_student(student_id, current_user)
        return section

    async def _get_note_for_user(self, note_id: str, current_user: Any, *, manage: bool = False) -> Any:
        from app.models.practice import PracticeNote

        note = await self.db.get(PracticeNote, note_id)
        if note is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Practice note not found")
        await self._get_section_for_user(note.section_id, current_user, manage=manage)
        return note

    async def _student_id_for_section(self, section_id: str) -> str:
        from app.models.practice import PracticeRepertoire, PracticeSection

        student_id = await self.db.scalar(
            select(PracticeRepertoire.student_id)
            .join(PracticeSection, PracticeSection.repertoire_id == PracticeRepertoire.id)
            .where(PracticeSection.id == section_id)
        )
        if student_id is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Section not found")
        return student_id

    async def _can_read_student(self, student_id: str | None, current_user: Any) -> bool:
        if student_id is None:
            return False
        try:
            await self._assert_can_read_student(student_id, current_user)
        except HTTPException:
            return False
        return True

    async def _get_piece_for_user(self, piece_id: str, current_user: Any) -> Any:
        from app.models.practice import PracticePiece

        piece = await self.db.get(PracticePiece, piece_id)
        if piece is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Piece not found")
        if (
            self._role(current_user) == "teacher"
            and piece.owner_teacher_id != await self._teacher_profile_id(current_user)
        ):
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")
        return piece

    async def _get_piece_for_teacher(self, piece_id: str, current_user: Any) -> Any:
        if self._role(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access required")
        return await self._get_piece_for_user(piece_id, current_user)

    async def _assert_can_read_student(self, student_id: str, current_user: Any) -> None:
        role = self._role(current_user)
        if role == "teacher":
            await self._assert_can_manage_student(student_id, current_user)
            return
        if role == "student" and student_id in await self._student_identifiers(current_user):
            return
        if role == "parent" and student_id in await self._parent_child_student_ids(current_user):
            return
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _assert_can_manage_student(self, student_id: str, current_user: Any) -> None:
        from app.models.student import Student

        if self._role(current_user) != "teacher":
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Teacher access required")
        teacher_id = await self._teacher_profile_id(current_user)
        owner = await self.db.scalar(
            select(Student.id).where(
                Student.id == student_id,
                Student.teacher_id == teacher_id,
            )
        )
        if owner is None:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

    async def _teacher_profile_id(self, current_user: Any) -> str:
        from app.services.teacher_id_resolver import resolve_teacher_id

        return await resolve_teacher_id(self.db, current_user.id)

    async def _student_identifiers(self, user: Any) -> list[str]:
        from app.models.student import Student

        identifiers = [user.id]
        result = await self.db.scalars(select(Student.id).where(Student.user_id == user.id))
        for student_id in result.all():
            if student_id not in identifiers:
                identifiers.append(student_id)
        return identifiers

    async def _parent_child_student_ids(self, user: Any) -> list[str]:
        from app.models.parent import Parent, ParentChildRelation, ParentChildRelationStatus

        parent_id = await self.db.scalar(select(Parent.id).where(Parent.user_id == user.id))
        if parent_id is None:
            return []
        result = await self.db.scalars(
            select(ParentChildRelation.student_id).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        return list(result.all())

    def _piece_response(self, piece: Any, assignment: Any | None = None) -> PracticePieceResponse:
        progress = (
            getattr(assignment.progress, "value", assignment.progress)
            if assignment is not None
            else "notStarted"
        )
        percentage = (assignment.progress_percentage / 100) if assignment is not None else 0.0
        return PracticePieceResponse(
            id=piece.id,
            title=piece.title,
            composer=piece.composer,
            opus=piece.opus,
            movement=piece.movement,
            difficulty=piece.difficulty,
            progress=progress,
            progress_percentage=percentage,
            notes=piece.notes,
            started_at=assignment.started_at if assignment is not None else None,
            completed_at=assignment.completed_at if assignment is not None else None,
            created_at=piece.created_at,
            updated_at=piece.updated_at,
        )

    @staticmethod
    def _progress_percentage(progress: str) -> int:
        return {
            "notStarted": 0,
            "inProgress": 40,
            "polishing": 80,
            "completed": 100,
        }[progress]

    def _role(self, current_user: Any) -> str | None:
        return getattr(getattr(current_user, "role", None), "value", None)
