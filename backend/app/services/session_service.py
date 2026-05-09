"""User session management service for multi-device tracking."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user_session import UserSession


class SessionService:
    """Handle user session creation, listing, and revocation."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create_session(
        self,
        user_id: str,
        device_name: str | None = None,
        device_type: str | None = None,
        ip_address: str | None = None,
    ) -> UserSession:
        """Create a new session for a user.

        Args:
            user_id: User ID
            device_name: Optional device name (e.g., "iPhone 15 Pro")
            device_type: Optional device type (ios, android, web)
            ip_address: Optional IP address

        Returns:
            Created UserSession

        Raises:
            HTTPException: If operation fails
        """
        try:
            session = UserSession(
                user_id=user_id,
                device_name=device_name,
                device_type=device_type,
                ip_address=ip_address,
                is_active=True,
            )
            self.db.add(session)
            await self.db.commit()
            await self.db.refresh(session)
            return session

        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to create session: {str(e)}",
            )

    async def list_sessions(self, user_id: str) -> list[UserSession]:
        """Get all active sessions for a user.

        Args:
            user_id: User ID

        Returns:
            List of active UserSession records
        """
        result = await self.db.execute(
            select(UserSession).where(
                (UserSession.user_id == user_id) & (UserSession.is_active)
            )
        )
        return result.scalars().all()

    async def revoke_session(self, session_id: str) -> bool:
        """Revoke a specific session by setting is_active to False.

        Args:
            session_id: Session ID to revoke

        Returns:
            True if session was revoked, False if not found
        """
        try:
            result = await self.db.execute(
                select(UserSession).where(UserSession.id == session_id)
            )
            session = result.scalar_one_or_none()

            if session is None:
                return False

            session.is_active = False
            self.db.add(session)
            await self.db.commit()
            return True

        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to revoke session: {str(e)}",
            )

    async def revoke_all_except(self, user_id: str, current_session_id: str) -> int:
        """Revoke all sessions for a user except the current one.

        Args:
            user_id: User ID
            current_session_id: Session ID to keep active

        Returns:
            Number of sessions revoked
        """
        try:
            stmt = (
                update(UserSession)
                .where(
                    (UserSession.user_id == user_id)
                    & (UserSession.id != current_session_id)
                    & (UserSession.is_active)
                )
                .values(is_active=False)
            )
            result = await self.db.execute(stmt)
            await self.db.commit()
            return result.rowcount

        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to revoke sessions: {str(e)}",
            )
