"""Audit log service for recording user actions."""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditAction, AuditLog


class AuditLogService:
    """Service for logging audit events."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def log_action(
        self,
        user_id: str,
        action: AuditAction,
        details: dict | None = None,
        ip_address: str | None = None,
        user_agent: str | None = None,
    ) -> AuditLog:
        """Log an audit action for a user.

        Args:
            user_id: The user ID performing the action
            action: The audit action (from AuditAction enum)
            details: Optional JSON details about the action
            ip_address: Optional IP address of the request
            user_agent: Optional user agent string

        Returns:
            The created AuditLog entry
        """
        audit_log = AuditLog(
            user_id=user_id,
            action=action.value,
            details=details,
            ip_address=ip_address,
            user_agent=user_agent,
        )
        self.db.add(audit_log)
        await self.db.flush()
        return audit_log
