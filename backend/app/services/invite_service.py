"""Invite, connection request, and connection service."""

from __future__ import annotations

import secrets
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse
from app.schemas.invite import (
    PublicInviteLandingResponse,
    PublicInviteLandingShare,
    PublicInviteLandingTeacher,
)


class InviteService:
    """Handle invites, connection requests, and connections."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # -----------------------------------------------------------------------
    # Invites
    # -----------------------------------------------------------------------

    async def create_invite(
        self,
        *,
        is_single_use: bool = False,
        max_uses: int | None = None,
        note: str | None = None,
        expires_in_hours: int = 48,
        current_user: Any,
    ) -> Any:
        """Create a new invite code."""
        from app.models.invite import Invite

        code = secrets.token_urlsafe(4).upper()[:6]
        invite_url = f"lessonapp://invite/{code}"
        qr_data = invite_url

        invite = Invite(
            creator_id=current_user.id,
            creator_name=current_user.name,
            creator_role=current_user.role,
            invite_code=code,
            invite_url=invite_url,
            qr_code_data=qr_data,
            is_single_use=is_single_use,
            max_uses=max_uses,
            note=note,
            expires_at=datetime.now(UTC) + timedelta(hours=expires_in_hours),
        )
        self.db.add(invite)
        await self.db.flush()
        await self.db.refresh(invite)
        return invite

    async def get_invites(
        self, *, user_id: str, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        """List invites created by the user."""
        from app.models.invite import Invite

        query = select(Invite).where(Invite.creator_id == user_id)
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(Invite.created_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def get_invite(self, invite_id: str) -> Any:
        """Get an invite by ID for scan/share confirmation flows."""
        from app.models.invite import Invite

        invite = await self.db.get(Invite, invite_id)
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        return invite

    async def get_invite_by_code(self, invite_code: str) -> Any:
        """Get an invite by its short code."""
        from app.models.invite import Invite

        invite = await self.db.scalar(
            select(Invite).where(Invite.invite_code == invite_code.upper())
        )
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        return invite

    async def get_public_invite_landing(self, invite_code: str) -> PublicInviteLandingResponse:
        """Return minimal public landing data for Ghost-rendered invite pages."""
        from app.core.config import settings
        from app.models.invite import Invite, InviteStatus
        from app.models.teacher import Teacher

        invite = await self.db.scalar(
            select(Invite).where(Invite.invite_code == invite_code.upper())
        )
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")

        expires_at = invite.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=UTC)
        if expires_at <= datetime.now(UTC) or invite.status in {
            InviteStatus.expired,
            InviteStatus.revoked,
            InviteStatus.used,
        }:
            raise HTTPException(status_code=status.HTTP_410_GONE, detail="Invite expired or unavailable")

        teacher = await self.db.scalar(select(Teacher).where(Teacher.user_id == invite.creator_id))
        instrument = "음악"
        if teacher and teacher.instruments:
            if isinstance(teacher.instruments, list) and teacher.instruments:
                instrument = str(teacher.instruments[0])
            elif isinstance(teacher.instruments, dict) and teacher.instruments:
                instrument = str(next(iter(teacher.instruments.values())))

        teacher_name = invite.creator_name or "선생님"
        public_url = f"{settings.WWW_BASE_URL.rstrip('/')}/invite/{invite.invite_code}"
        return PublicInviteLandingResponse(
            code=invite.invite_code,
            status=invite.status.value,
            teacher=PublicInviteLandingTeacher(
                id=teacher.id if teacher else None,
                name=teacher_name,
                instrument=instrument,
                profile_image_url=None,
            ),
            share=PublicInviteLandingShare(
                title=f"{teacher_name} 선생님의 레슨앱 초대",
                description=f"{instrument} 레슨 기록과 숙제를 함께 확인해요",
                url=public_url,
                app_deep_link=f"lessonapp://invite/{invite.invite_code}",
            ),
            expires_at=invite.expires_at,
        )

    async def revoke_invite(self, invite_id: str, current_user: Any) -> Any:
        """Revoke an invite."""
        from app.models.invite import Invite, InviteStatus

        invite = await self.db.get(Invite, invite_id)
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        if invite.creator_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your invite")
        invite.status = InviteStatus.revoked
        await self.db.flush()
        await self.db.refresh(invite)
        return invite

    # -----------------------------------------------------------------------
    # Connection Requests
    # -----------------------------------------------------------------------

    async def create_connection_request(
        self,
        *,
        target_id: str,
        method: str,
        invite_id: str | None = None,
        invite_code: str | None = None,
        message: str | None = None,
        current_user: Any,
    ) -> Any:
        """Create a connection request."""
        from app.models.invite import ConnectionRequest, Invite, InviteStatus
        from app.models.user import User

        invite: Invite | None = None

        # Validate invite code if provided
        if invite_code:
            invite = await self.db.scalar(
                select(Invite).where(Invite.invite_code == invite_code.upper())
            )
            if invite is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid invite code",
                )
        elif invite_id:
            invite = await self.db.get(Invite, invite_id)
            if invite is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid invite",
                )

        if invite is not None:
            self._validate_invite_can_be_used(invite)
            invite_id = invite.id
            target_id = invite.creator_id

            invite.use_count += 1
            if invite.is_single_use or (invite.max_uses is not None and invite.use_count >= invite.max_uses):
                invite.status = InviteStatus.used

        target_user = await self.db.get(User, target_id) if target_id else None

        target_role = (
            target_user.role
            if target_user is not None
            else "teacher"
            if current_user.role == "student"
            else "student"
        )
        target_name = (
            target_user.name
            if target_user is not None
            else invite.creator_name
            if invite is not None
            else None
        )

        conn_req = ConnectionRequest(
            requester_id=current_user.id,
            requester_role=current_user.role,
            requester_name=current_user.name,
            target_id=target_id,
            target_role=target_role,
            target_name=target_name,
            method=method,
            invite_id=invite_id,
            message=message,
            expires_at=datetime.now(UTC) + timedelta(days=7),
        )
        self.db.add(conn_req)
        await self.db.flush()
        await self.db.refresh(conn_req)
        return conn_req

    def _validate_invite_can_be_used(self, invite: Any) -> None:
        """Validate active/unexpired usage limits before creating a request."""
        invite_status = getattr(invite.status, "value", invite.status)
        if invite_status != "active":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired invite code",
            )

        expires_at = invite.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=UTC)
        if expires_at <= datetime.now(UTC):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired invite code",
            )

        if invite.is_single_use and invite.use_count > 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invite has already been used",
            )
        if invite.max_uses is not None and invite.use_count >= invite.max_uses:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invite usage limit reached",
            )

    async def get_pending_requests(
        self, *, user_id: str, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        """List pending connection requests for the user."""
        from app.models.invite import ConnectionRequest

        query = select(ConnectionRequest).where(
            ConnectionRequest.target_id == user_id,
            ConnectionRequest.status == "pending",
        )
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(ConnectionRequest.created_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def get_sent_requests(
        self, *, user_id: str, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        """List connection requests sent by the user."""
        from app.models.invite import ConnectionRequest

        query = select(ConnectionRequest).where(ConnectionRequest.requester_id == user_id)
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(ConnectionRequest.created_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def respond_to_request(
        self,
        request_id: str,
        action: str,
        rejection_reason: str | None,
        current_user: Any,
    ) -> Any:
        """Accept or reject a connection request."""
        from app.models.invite import Connection, ConnectionRequest, ConnectionRequestStatus

        conn_req = await self.db.get(ConnectionRequest, request_id)
        if conn_req is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")
        if conn_req.target_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your request")

        now = datetime.now(UTC)
        conn_req.responded_at = now

        if action == "accept":
            conn_req.status = ConnectionRequestStatus.accepted
            # Create connection
            teacher_id = conn_req.requester_id if conn_req.requester_role.value == "teacher" else conn_req.target_id
            student_id = conn_req.target_id if conn_req.requester_role.value == "teacher" else conn_req.requester_id
            teacher_name = (
                conn_req.requester_name
                if conn_req.requester_role.value == "teacher"
                else current_user.name
            )
            student_name = (
                current_user.name
                if conn_req.requester_role.value == "teacher"
                else conn_req.requester_name
            )
            connection = Connection(
                teacher_id=teacher_id,
                teacher_name=teacher_name,
                student_id=student_id,
                student_name=student_name,
                connection_request_id=request_id,
            )
            self.db.add(connection)
            await self._attach_student_to_teacher(
                teacher_user_id=teacher_id,
                student_user_id=student_id,
                student_name=student_name,
                connected_at=now,
            )
        else:
            conn_req.status = ConnectionRequestStatus.rejected
            conn_req.rejection_reason = rejection_reason

        await self.db.flush()
        await self.db.refresh(conn_req)
        return conn_req

    async def _attach_student_to_teacher(
        self,
        *,
        teacher_user_id: str,
        student_user_id: str,
        student_name: str | None,
        connected_at: datetime,
    ) -> None:
        """Attach an accepted app connection to the teacher-owned student roster."""
        from app.models.relationship import RelationStatus, TeacherStudentRelation
        from app.models.student import ConnectionStatus, Student
        from app.services.teacher_id_resolver import resolve_teacher_id

        teacher_id = await resolve_teacher_id(self.db, teacher_user_id)
        student = await self.db.scalar(select(Student).where(Student.user_id == student_user_id))
        if student is None:
            student = Student(
                user_id=student_user_id,
                teacher_id=teacher_id,
                name=student_name or "Student",
                instrument="",
            )
            self.db.add(student)
            await self.db.flush()
        else:
            student.teacher_id = teacher_id
            student.is_active = True

        student.connection_status = ConnectionStatus.connected
        student.connected_at = connected_at

        relation = await self.db.scalar(
            select(TeacherStudentRelation).where(
                TeacherStudentRelation.teacher_id == teacher_id,
                TeacherStudentRelation.student_id == student.id,
            )
        )
        if relation is None:
            relation = TeacherStudentRelation(
                teacher_id=teacher_id,
                student_id=student.id,
            )
            self.db.add(relation)

        relation.status = RelationStatus.active
        relation.connected_at = connected_at
        relation.disconnected_at = None
        relation.is_app_connected = True
        relation.app_connected_at = relation.app_connected_at or connected_at

    async def cancel_request(self, request_id: str, current_user: Any) -> Any:
        """Cancel a pending request by its requester."""
        from app.models.invite import ConnectionRequest, ConnectionRequestStatus

        conn_req = await self.db.get(ConnectionRequest, request_id)
        if conn_req is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Request not found")
        if conn_req.requester_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your request")
        if getattr(conn_req.status, "value", conn_req.status) != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only pending requests can be cancelled",
            )

        conn_req.status = ConnectionRequestStatus.cancelled
        conn_req.responded_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(conn_req)
        return conn_req

    # -----------------------------------------------------------------------
    # Connections
    # -----------------------------------------------------------------------

    async def get_connections(
        self, *, user_id: str, page: int, size: int, offset: int, include_inactive: bool = False
    ) -> PaginatedResponse:
        """List active connections."""
        from app.models.invite import Connection

        query = select(Connection).where(
            (Connection.teacher_id == user_id) | (Connection.student_id == user_id),
        )
        if not include_inactive:
            query = query.where(Connection.is_active.is_(True))
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(Connection.connected_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def reactivate_connection(self, connection_id: str, current_user: Any) -> Any:
        """Reactivate a previously deactivated connection."""
        from app.models.invite import Connection

        conn = await self.db.get(Connection, connection_id)
        if conn is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Connection not found")
        if conn.teacher_id != current_user.id and conn.student_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your connection")
        conn.is_active = True
        conn.deactivated_at = None
        await self.db.flush()
        await self.db.refresh(conn)
        return conn

    async def deactivate_connection(self, connection_id: str, current_user: Any) -> None:
        """Deactivate a connection."""
        from app.models.invite import Connection

        conn = await self.db.get(Connection, connection_id)
        if conn is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Connection not found")
        if conn.teacher_id != current_user.id and conn.student_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your connection")
        conn.is_active = False
        conn.deactivated_at = datetime.now(UTC)
        await self.db.flush()
