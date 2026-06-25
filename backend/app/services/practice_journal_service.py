"""Practice journal service (#872).

Ownership / access control:
  - assert_can_read:       student-self | guardian (active PCR) |
                           teacher (active TSR + can_view_practice)
  - assert_is_student_self: authenticated user owns the student profile
  - assert_is_guardian:    authenticated user is an active guardian of the student
  - assert_is_teacher_of:  authenticated user is an active teacher of the student

All assert_* methods raise PermissionError or ValueError — callers (router) convert
to 403 / 404.  No DB queries inside the router (arch contract).

WIRE CONTRACT: response models mirror the FE .g.dart authoritative keys
(intensity, cheer_note, by, date, piece_name, bound_date).  The ledger returns
full marks/seals/endorsements lists (NOT a flattened day summary).
"""

from __future__ import annotations

import datetime

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.parent import ParentChildRelation, ParentChildRelationStatus
from app.models.practice_journal import (
    BoundVolume,
    Endorsement,
    GuardianSeal,
    PracticeMark,
)
from app.models.relationship import RelationStatus, TeacherStudentRelation
from app.models.student import Student
from app.models.teacher import Teacher
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


class PracticeJournalService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    # ------------------------------------------------------------------
    # Access control
    # ------------------------------------------------------------------

    async def _student_id_for_user(self, user_id: str) -> str | None:
        """Return Student.id for the given user, or None."""
        return await self._db.scalar(select(Student.id).where(Student.user_id == user_id))

    async def assert_is_student_self(self, child_profile_id: str, user_id: str) -> None:
        """Raise PermissionError if user_id does not own child_profile_id."""
        student = await self._db.get(Student, child_profile_id)
        if student is None:
            raise ValueError(f"Student {child_profile_id} not found")
        if student.user_id != user_id:
            raise PermissionError("Not the student owner")

    async def assert_is_guardian(self, child_profile_id: str, user_id: str) -> None:
        """Raise PermissionError if user_id is not an active guardian."""
        from app.models.parent import Parent

        parent_id = await self._db.scalar(select(Parent.id).where(Parent.user_id == user_id))
        if parent_id is None:
            raise PermissionError("No parent profile for this user")

        pcr = await self._db.scalar(
            select(ParentChildRelation).where(
                ParentChildRelation.parent_id == parent_id,
                ParentChildRelation.student_id == child_profile_id,
                ParentChildRelation.status == ParentChildRelationStatus.active,
            )
        )
        if pcr is None:
            raise PermissionError("Not an active guardian of this student")

    async def _teacher_id_for_user(self, user_id: str) -> str | None:
        return await self._db.scalar(select(Teacher.id).where(Teacher.user_id == user_id))

    async def assert_is_teacher_of(self, child_profile_id: str, user_id: str) -> str:
        """Raise PermissionError if user is not an active teacher of the student.

        Returns teacher_user_id (== user_id) for stamping endorsement author.
        """
        teacher_id = await self._teacher_id_for_user(user_id)
        if teacher_id is None:
            raise PermissionError("No teacher profile for this user")

        rel = await self._db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id == teacher_id,
                TeacherStudentRelation.student_id == child_profile_id,
                TeacherStudentRelation.status == RelationStatus.active,
                TeacherStudentRelation.can_view_practice.is_(True),
            )
        )
        if rel is None:
            raise PermissionError("Not an active teacher of this student (or practice hidden)")
        return user_id

    async def assert_can_read(self, child_profile_id: str, user_id: str) -> None:
        """Allow if: student-self | active guardian | active teacher with view perm."""
        student = await self._db.get(Student, child_profile_id)
        if student is None:
            raise ValueError(f"Student {child_profile_id} not found")

        # student self
        if student.user_id == user_id:
            return

        # guardian
        from app.models.parent import Parent

        parent_id = await self._db.scalar(select(Parent.id).where(Parent.user_id == user_id))
        if parent_id is not None:
            pcr = await self._db.scalar(
                select(ParentChildRelation).where(
                    ParentChildRelation.parent_id == parent_id,
                    ParentChildRelation.student_id == child_profile_id,
                    ParentChildRelation.status == ParentChildRelationStatus.active,
                )
            )
            if pcr is not None:
                return

        # teacher
        teacher_id = await self._teacher_id_for_user(user_id)
        if teacher_id is not None:
            rel = await self._db.scalar(
                select(TeacherStudentRelation).where(
                    TeacherStudentRelation.teacher_id == teacher_id,
                    TeacherStudentRelation.student_id == child_profile_id,
                    TeacherStudentRelation.status == RelationStatus.active,
                    TeacherStudentRelation.can_view_practice.is_(True),
                )
            )
            if rel is not None:
                return

        raise PermissionError("Access denied to this student's practice journal")

    # ------------------------------------------------------------------
    # Ledger (computed, not stored)
    # ------------------------------------------------------------------

    async def get_ledger(
        self,
        child_profile_id: str,
        year: int,
        month: int,
    ) -> LedgerResponse:
        """Return the monthly practice ledger for a student.

        Wire shape mirrors FE PracticeLedger: full marks/seals/endorsements lists.
        - marks: by mark.date in the month
        - seals: by week_start in the month
        - endorsements: by endorsement.date in the month
        """
        from calendar import monthrange

        first_day = datetime.date(year, month, 1)
        last_day = datetime.date(year, month, monthrange(year, month)[1])

        marks_rows = (
            (
                await self._db.execute(
                    select(PracticeMark)
                    .where(
                        PracticeMark.child_profile_id == child_profile_id,
                        PracticeMark.date >= first_day,
                        PracticeMark.date <= last_day,
                    )
                    .order_by(PracticeMark.date)
                )
            )
            .scalars()
            .all()
        )

        seals_rows = (
            (
                await self._db.execute(
                    select(GuardianSeal)
                    .where(
                        GuardianSeal.child_profile_id == child_profile_id,
                        GuardianSeal.week_start >= first_day,
                        GuardianSeal.week_start <= last_day,
                    )
                    .order_by(GuardianSeal.week_start)
                )
            )
            .scalars()
            .all()
        )

        endorsements_rows = (
            (
                await self._db.execute(
                    select(Endorsement)
                    .where(
                        Endorsement.child_profile_id == child_profile_id,
                        Endorsement.date >= first_day,
                        Endorsement.date <= last_day,
                    )
                    .order_by(Endorsement.date)
                )
            )
            .scalars()
            .all()
        )

        return LedgerResponse(
            child_profile_id=child_profile_id,
            year=year,
            month=month,
            marks=[PracticeMarkResponse.model_validate(m) for m in marks_rows],
            seals=[GuardianSealResponse.model_validate(s) for s in seals_rows],
            endorsements=[EndorsementResponse.model_validate(e) for e in endorsements_rows],
        )

    # ------------------------------------------------------------------
    # Write operations
    # ------------------------------------------------------------------

    async def upsert_mark(self, req: MarkUpsertRequest) -> PracticeMarkResponse:
        """Insert or upgrade a daily practice mark.

        Monotonic upgrade: short -> full only.  Downgrade (full -> short) is a no-op.
        """
        existing = await self._db.scalar(
            select(PracticeMark).where(
                PracticeMark.child_profile_id == req.child_profile_id,
                PracticeMark.date == req.date,
            )
        )
        if existing is not None:
            # Monotonic upgrade only
            if existing.intensity == "short" and req.intensity == "full":
                existing.intensity = "full"
                await self._db.flush()
            return PracticeMarkResponse.model_validate(existing)

        mark = PracticeMark(
            child_profile_id=req.child_profile_id,
            date=req.date,
            intensity=req.intensity,
        )
        self._db.add(mark)
        await self._db.flush()
        await self._db.refresh(mark)
        return PracticeMarkResponse.model_validate(mark)

    async def add_seal(self, req: GuardianSealRequest, guardian_user_id: str) -> GuardianSealResponse:
        """Idempotent guardian seal for the week containing req.week_start.

        week_start is normalized to Monday before insert.
        Same week re-seal returns existing row.  guardian_user_id is stamped
        from the authenticated user (req.guardian_user_id is ignored).
        """
        # Normalize to Monday
        week_start = req.week_start - datetime.timedelta(days=req.week_start.weekday())

        existing = await self._db.scalar(
            select(GuardianSeal).where(
                GuardianSeal.child_profile_id == req.child_profile_id,
                GuardianSeal.week_start == week_start,
            )
        )
        if existing is not None:
            return GuardianSealResponse.model_validate(existing)

        seal = GuardianSeal(
            child_profile_id=req.child_profile_id,
            guardian_user_id=guardian_user_id,
            week_start=week_start,
            cheer_note=req.cheer_note,
        )
        self._db.add(seal)
        await self._db.flush()
        await self._db.refresh(seal)
        return GuardianSealResponse.model_validate(seal)

    async def add_endorsement(
        self,
        req: EndorsementRequest,
        author_user_id: str,
    ) -> EndorsementResponse:
        """Append-only endorsement.  ref rules re-validated here as well.

        author_user_id is stamped from the authenticated user (req.author_user_id
        is ignored).
        """
        if req.by == "teacher" and not req.assignment_ref:
            raise ValueError("assignment_ref required for teacher endorsement")
        if req.by == "self" and req.assignment_ref:
            raise ValueError("assignment_ref must be absent for self endorsement")

        endorsement = Endorsement(
            child_profile_id=req.child_profile_id,
            author_user_id=author_user_id,
            by=req.by,
            date=req.date,
            assignment_ref=req.assignment_ref,
            note=req.note,
        )
        self._db.add(endorsement)
        await self._db.flush()
        await self._db.refresh(endorsement)
        return EndorsementResponse.model_validate(endorsement)

    # ------------------------------------------------------------------
    # Volumes
    # ------------------------------------------------------------------

    async def list_volumes(self, child_profile_id: str) -> list[BoundVolumeResponse]:
        rows = (
            (
                await self._db.execute(
                    select(BoundVolume)
                    .where(BoundVolume.child_profile_id == child_profile_id)
                    .order_by(BoundVolume.volume_no)
                )
            )
            .scalars()
            .all()
        )
        return [BoundVolumeResponse.model_validate(r) for r in rows]

    async def bind_volume(self, req: BindVolumeRequest) -> BoundVolumeResponse:
        """Idempotent volume bind.

        If (child_profile_id, piece_id) already exists, return existing.
        volume_no = count of existing volumes + 1 at time of insert.
        bound_date is server-stamped to today.
        IntegrityError on race is caught and re-queried.
        """
        existing = await self._db.scalar(
            select(BoundVolume).where(
                BoundVolume.child_profile_id == req.child_profile_id,
                BoundVolume.piece_id == req.piece_id,
            )
        )
        if existing is not None:
            return BoundVolumeResponse.model_validate(existing)

        # Compute next volume_no
        count = await self._db.scalar(select(func.count()).where(BoundVolume.child_profile_id == req.child_profile_id))
        volume_no = (count or 0) + 1

        volume = BoundVolume(
            child_profile_id=req.child_profile_id,
            piece_id=req.piece_id,
            piece_name=req.piece_name,
            volume_no=volume_no,
            bound_date=datetime.date.today(),
        )
        self._db.add(volume)
        try:
            await self._db.flush()
        except IntegrityError:
            await self._db.rollback()
            # Race: another request inserted first
            row = await self._db.scalar(
                select(BoundVolume).where(
                    BoundVolume.child_profile_id == req.child_profile_id,
                    BoundVolume.piece_id == req.piece_id,
                )
            )
            if row is None:
                raise RuntimeError("Volume bind failed after IntegrityError re-query")
            return BoundVolumeResponse.model_validate(row)

        await self._db.refresh(volume)
        return BoundVolumeResponse.model_validate(volume)
