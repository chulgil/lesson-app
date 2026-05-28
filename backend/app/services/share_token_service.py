"""Service for managing share tokens."""

from __future__ import annotations

import secrets
from datetime import UTC, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.share_token import ShareToken, ShareTokenScope


class ShareTokenService:
    """Service for issuing and validating share tokens."""

    def __init__(self, session: AsyncSession) -> None:
        """Initialize with async database session."""
        self.session = session

    async def issue_token(
        self,
        scope: ShareTokenScope,
        target_id: str,
        ttl_days: int = 30,
        created_by_user_id: str | None = None,
    ) -> ShareToken:
        """Issue a new share token.

        Args:
            scope: Scope of token access (e.g., "student_summary")
            target_id: ID of the target resource (e.g., student ID)
            ttl_days: Time-to-live in days (default 30)
            created_by_user_id: ID of user creating the token (optional)

        Returns:
            ShareToken: The newly created share token.
        """
        token_str = secrets.token_urlsafe(32)
        expires_at = datetime.now(UTC) + timedelta(days=ttl_days)

        token = ShareToken(
            token=token_str,
            scope=scope,
            target_id=target_id,
            created_by_user_id=created_by_user_id,
            expires_at=expires_at,
        )
        self.session.add(token)
        await self.session.flush()
        await self.session.refresh(token)
        return token

    async def resolve_token(self, token: str) -> ShareToken | None:
        """Resolve and validate a share token.

        Returns the token only when it exists and has not expired. Expiration
        is filtered at the SQL level so the comparison stays consistent across
        timezone-aware (PostgreSQL) and timezone-naive (SQLite) backends.
        """
        now = datetime.now(UTC)
        return await self.session.scalar(
            select(ShareToken).where(
                ShareToken.token == token,
                ShareToken.expires_at >= now,
            ),
        )

    async def get_by_scope_and_target(
        self,
        scope: ShareTokenScope,
        target_id: str,
    ) -> ShareToken | None:
        """Get a valid (non-expired) token by scope and target."""
        now = datetime.now(UTC)
        token_obj = await self.session.scalar(
            select(ShareToken).where(
                ShareToken.scope == scope,
                ShareToken.target_id == target_id,
                ShareToken.expires_at >= now,
            ),
        )
        return token_obj
