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
    InviteResponse,
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

    async def get_invites(self, *, user_id: str, page: int, size: int, offset: int) -> PaginatedResponse:
        """List invites created by the user."""
        from app.models.invite import Invite

        query = select(Invite).where(Invite.creator_id == user_id)
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0

        result = await self.db.scalars(query.order_by(Invite.created_at.desc()).offset(offset).limit(size))
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def get_invite(self, invite_id: str, current_user: Any) -> Any:
        """Get an invite by ID — restricted to its creator."""
        from app.models.invite import Invite

        invite = await self.db.get(Invite, invite_id)
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        if invite.creator_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your invite")
        return invite

    async def get_invite_by_code(self, invite_code: str, current_user: Any) -> Any:
        """Get an invite by its short code.

        Accessible to any authenticated user so a joining user can resolve the
        invite before connecting. When the caller is NOT the creator, sensitive
        fields (qr_code_data, note, invite_url, usage counts) are blanked so a
        non-creator cannot harvest them.
        """
        from app.models.invite import Invite

        invite = await self.db.scalar(select(Invite).where(Invite.invite_code == invite_code.upper()))
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        if invite.creator_id == current_user.id:
            return invite
        return self._redact_invite_for_non_creator(invite)

    @staticmethod
    def _redact_invite_for_non_creator(invite: Any) -> Any:
        """Build an InviteResponse with sensitive fields blanked for non-creators."""
        return InviteResponse(
            id=invite.id,
            creator_id=invite.creator_id,
            creator_name=invite.creator_name,
            creator_role=getattr(invite.creator_role, "value", invite.creator_role),
            invite_code=invite.invite_code,
            invite_url="",
            qr_code_data="",
            status=getattr(invite.status, "value", invite.status),
            is_single_use=invite.is_single_use,
            max_uses=None,
            use_count=0,
            note=None,
            expires_at=invite.expires_at,
            created_at=invite.created_at,
        )

    async def get_public_invite_landing(self, invite_code: str) -> PublicInviteLandingResponse:
        """Return minimal public landing data for Ghost-rendered invite pages."""
        from app.core.config import settings
        from app.models.invite import Invite, InviteStatus
        from app.models.teacher import Teacher

        invite = await self.db.scalar(select(Invite).where(Invite.invite_code == invite_code.upper()))
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")

        expires_at = invite.expires_at
        # A missing expiry is anomalous data for a public landing; the response
        # contract requires a concrete expiry, so treat it as unavailable rather
        # than touching `.tzinfo` (AttributeError → 500).
        is_expired = expires_at is None
        if expires_at is not None:
            if expires_at.tzinfo is None:
                expires_at = expires_at.replace(tzinfo=UTC)
            is_expired = expires_at <= datetime.now(UTC)
        if is_expired or invite.status in {
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
    # G3 — Resend / Pending list (#5 D-G3)
    # -----------------------------------------------------------------------

    RESEND_COOLDOWN_MINUTES = 10
    RESEND_EXTEND_DAYS = 7

    async def resend_invite(self, invite_id: str, current_user: Any) -> Any:
        """Resend an invite: extend expiry, bump resent_count, resurrect if expired."""
        from app.models.invite import Invite, InviteStatus

        invite = await self.db.get(Invite, invite_id)
        if invite is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
        if invite.creator_id != current_user.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your invite")
        if invite.status in (InviteStatus.used, InviteStatus.revoked):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invite is {invite.status.value}; cannot resend",
            )

        now = datetime.now(UTC)
        last = invite.last_resent_at
        if last is not None:
            last_aware = last if last.tzinfo else last.replace(tzinfo=UTC)
            if (now - last_aware) < timedelta(minutes=self.RESEND_COOLDOWN_MINUTES):
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"재발송은 {self.RESEND_COOLDOWN_MINUTES}분에 한 번만 가능합니다. cooldown",
                )

        invite.expires_at = now + timedelta(days=self.RESEND_EXTEND_DAYS)
        invite.resent_count = (invite.resent_count or 0) + 1
        invite.last_resent_at = now
        # Resurrect expired invites — the resend itself is what re-activates them.
        if invite.status == InviteStatus.expired:
            invite.status = InviteStatus.active

        await self.db.flush()
        await self.db.refresh(invite)
        return invite

    async def list_pending_invites(self, current_user: Any) -> dict[str, Any]:
        """Return the creator's active, non-expired, non-used invites with D+N + can_resend."""
        from app.models.invite import Invite, InviteStatus

        now = datetime.now(UTC)
        result = await self.db.scalars(
            select(Invite).where(
                Invite.creator_id == current_user.id,
                Invite.status == InviteStatus.active,
                Invite.expires_at > now,
            )
        )
        invites = list(result.all())

        cooldown = timedelta(minutes=self.RESEND_COOLDOWN_MINUTES)
        rows: list[dict[str, Any]] = []
        for inv in invites:
            created = inv.created_at if inv.created_at.tzinfo else inv.created_at.replace(tzinfo=UTC)
            last = inv.last_resent_at
            if last is not None:
                last_aware = last if last.tzinfo else last.replace(tzinfo=UTC)
                can_resend = (now - last_aware) >= cooldown
            else:
                can_resend = True
            rows.append(
                {
                    "invite_id": inv.id,
                    "invite_code": inv.invite_code,
                    "days_since_sent": max(0, (now - created).days),
                    "expires_at": inv.expires_at.isoformat() if inv.expires_at else None,
                    "resent_count": inv.resent_count or 0,
                    "last_resent_at": inv.last_resent_at.isoformat() if inv.last_resent_at else None,
                    "can_resend": can_resend,
                    "note": inv.note,
                }
            )
        rows.sort(key=lambda r: r["days_since_sent"], reverse=True)
        return {"pending": rows, "total_count": len(rows)}

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
        from app.models.invite import ConnectionRequest, ConnectionRequestStatus, Invite, InviteStatus
        from app.models.user import User

        invite: Invite | None = None

        # Validate invite code if provided. Row-locked so the validate →
        # use_count increment below is atomic — without the lock two
        # concurrent requests could both pass _validate_invite_can_be_used
        # and overshoot a single-use/max_uses invite (TOCTOU). No-op on the
        # SQLite test dialect, same as the subscription_service pattern.
        if invite_code:
            invite = await self.db.scalar(
                select(Invite).where(Invite.invite_code == invite_code.upper()).with_for_update()
            )
            if invite is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid invite code",
                )
        elif invite_id:
            invite = await self.db.scalar(select(Invite).where(Invite.id == invite_id).with_for_update())
            if invite is None:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid invite",
                )

        if invite is not None:
            self._validate_invite_can_be_used(invite)
            invite_id = invite.id
            target_id = invite.creator_id

        target_user = await self.db.get(User, target_id) if target_id else None

        target_role = (
            target_user.role if target_user is not None else "teacher" if current_user.role == "student" else "student"
        )
        target_name = (
            target_user.name if target_user is not None else invite.creator_name if invite is not None else None
        )

        existing_pending = await self.db.scalar(
            select(ConnectionRequest)
            .where(
                ConnectionRequest.requester_id == current_user.id,
                ConnectionRequest.target_id == target_id,
                ConnectionRequest.status == ConnectionRequestStatus.pending,
            )
            .order_by(ConnectionRequest.created_at.desc())
        )
        now = datetime.now(UTC)
        if existing_pending is not None:
            existing_pending.requester_role = current_user.role
            existing_pending.requester_name = current_user.name
            existing_pending.target_role = target_role
            existing_pending.target_name = target_name
            existing_pending.method = method
            existing_pending.invite_id = invite_id
            existing_pending.message = message
            existing_pending.expires_at = now + timedelta(days=7)
            existing_pending.created_at = now
            await self._cancel_older_pending_requests(
                requester_id=current_user.id,
                target_id=target_id,
                keep_request_id=existing_pending.id,
                now=now,
            )
            await self._upsert_connection_request_notification(existing_pending)
            await self.db.flush()
            await self.db.refresh(existing_pending)
            return existing_pending

        if invite is not None:
            invite.use_count += 1
            if invite.is_single_use or (invite.max_uses is not None and invite.use_count >= invite.max_uses):
                invite.status = InviteStatus.used

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
            expires_at=now + timedelta(days=7),
        )
        self.db.add(conn_req)
        await self.db.flush()
        await self._upsert_connection_request_notification(conn_req)
        await self.db.flush()
        await self.db.refresh(conn_req)
        return conn_req

    async def _cancel_older_pending_requests(
        self,
        *,
        requester_id: str,
        target_id: str,
        keep_request_id: str,
        now: datetime,
    ) -> None:
        """Keep only the latest pending request for a requester/target pair."""
        from app.models.invite import ConnectionRequest, ConnectionRequestStatus

        older_requests = await self.db.scalars(
            select(ConnectionRequest).where(
                ConnectionRequest.requester_id == requester_id,
                ConnectionRequest.target_id == target_id,
                ConnectionRequest.status == ConnectionRequestStatus.pending,
                ConnectionRequest.id != keep_request_id,
            )
        )
        for request in older_requests.all():
            request.status = ConnectionRequestStatus.cancelled
            request.responded_at = now

    async def _upsert_connection_request_notification(self, conn_req: Any) -> None:
        """Create or refresh the in-app notification for a pending connection request."""
        from app.models.notification import Notification, NotificationPriority

        now = datetime.now(UTC)
        action_url = "/invite/requests"
        data = {
            "connectionRequestId": conn_req.id,
            "requesterId": conn_req.requester_id,
            "targetId": conn_req.target_id,
            "requesterRole": getattr(conn_req.requester_role, "value", conn_req.requester_role),
        }
        title = "연결 요청"
        requester_name = conn_req.requester_name or "학생"
        body = f"{requester_name}님이 연결을 요청했습니다"

        notifications = await self.db.scalars(
            select(Notification)
            .where(
                Notification.user_id == conn_req.target_id,
                Notification.type == "connectionRequestReceived",
                Notification.action_url == action_url,
            )
            .order_by(Notification.created_at.desc())
        )
        existing = next(
            (
                notification
                for notification in notifications.all()
                if (notification.data or {}).get("requesterId") == conn_req.requester_id
                and (notification.data or {}).get("targetId") == conn_req.target_id
            ),
            None,
        )
        if existing is not None:
            existing.title = title
            existing.body = body
            existing.data = data
            existing.priority = NotificationPriority.high
            existing.is_in_app = True
            existing.is_push = True
            existing.action_label = "요청 확인"
            existing.read_at = None
            existing.sent_at = now
            existing.created_at = now
            return

        self.db.add(
            Notification(
                user_id=conn_req.target_id,
                type="connectionRequestReceived",
                priority=NotificationPriority.high,
                title=title,
                body=body,
                data=data,
                is_push=True,
                is_in_app=True,
                action_url=action_url,
                action_label="요청 확인",
                sent_at=now,
            )
        )

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

    async def get_pending_requests(self, *, user_id: str, page: int, size: int, offset: int) -> PaginatedResponse:
        """List pending connection requests for the user."""
        from app.models.invite import ConnectionRequest

        query = select(ConnectionRequest).where(
            ConnectionRequest.target_id == user_id,
            ConnectionRequest.status == "pending",
        )
        result = await self.db.scalars(query.order_by(ConnectionRequest.created_at.desc()))
        unique_items = self._latest_pending_request_per_pair(result.all())
        return PaginatedResponse.create(
            items=unique_items[offset : offset + size],
            total=len(unique_items),
            page=page,
            size=size,
        )

    async def get_sent_requests(self, *, user_id: str, page: int, size: int, offset: int) -> PaginatedResponse:
        """List connection requests sent by the user."""
        from app.models.invite import ConnectionRequest

        query = select(ConnectionRequest).where(ConnectionRequest.requester_id == user_id)
        result = await self.db.scalars(query.order_by(ConnectionRequest.created_at.desc()))
        unique_items = self._latest_pending_request_per_pair(result.all())
        return PaginatedResponse.create(
            items=unique_items[offset : offset + size],
            total=len(unique_items),
            page=page,
            size=size,
        )

    def _latest_pending_request_per_pair(self, requests: list[Any]) -> list[Any]:
        """Collapse duplicated pending requests while preserving other history."""
        unique_requests = []
        seen_pending_pairs: set[tuple[str, str]] = set()
        for request in requests:
            request_status = getattr(request.status, "value", request.status)
            if request_status == "pending":
                key = (request.requester_id, request.target_id)
                if key in seen_pending_pairs:
                    continue
                seen_pending_pairs.add(key)
            unique_requests.append(request)
        return unique_requests

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
        if getattr(conn_req.status, "value", conn_req.status) != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Request is not pending",
            )

        now = datetime.now(UTC)
        conn_req.responded_at = now
        await self._cancel_older_pending_requests(
            requester_id=conn_req.requester_id,
            target_id=conn_req.target_id,
            keep_request_id=conn_req.id,
            now=now,
        )

        if action == "accept":
            conn_req.status = ConnectionRequestStatus.accepted
            # Create connection
            teacher_id = conn_req.requester_id if conn_req.requester_role.value == "teacher" else conn_req.target_id
            student_id = conn_req.target_id if conn_req.requester_role.value == "teacher" else conn_req.requester_id
            teacher_name = conn_req.requester_name if conn_req.requester_role.value == "teacher" else current_user.name
            student_name = current_user.name if conn_req.requester_role.value == "teacher" else conn_req.requester_name
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
        from app.models.student import Student
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

        # G3 Phase B-2 — deprecated `connection_status` writer removed.
        # `connected_at` is now the canonical "app-connected" signal alongside
        # `TeacherStudentRelation.status`. Column drop lands in Phase B-2b.
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
        total = await self.db.scalar(select(func.count()).select_from(query.subquery())) or 0

        result = await self.db.scalars(query.order_by(Connection.connected_at.desc()).offset(offset).limit(size))
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
