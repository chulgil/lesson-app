"""Account recovery service for managing recovery codes."""

from __future__ import annotations

import secrets

from fastapi import HTTPException, status
from passlib.context import CryptContext
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.recovery import RecoveryCode

# Password context for bcrypt hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class RecoveryService:
    """Handle recovery code generation and verification."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def generate_codes(self, user_id: str) -> list[str]:
        """Generate 10 new recovery codes for a user.

        Args:
            user_id: User ID

        Returns:
            List of 10 plaintext recovery codes

        Raises:
            HTTPException: If operation fails
        """
        try:
            # Delete any existing unused codes
            await self.db.execute(
                delete(RecoveryCode).where(
                    (RecoveryCode.user_id == user_id) & (not RecoveryCode.is_used)
                )
            )

            # Generate 10 new codes
            plaintext_codes: list[str] = []
            recovery_codes: list[RecoveryCode] = []

            for _ in range(10):
                # Generate random 8-character code (alphanumeric, easy to type)
                code = secrets.token_hex(4)  # 8 hex characters
                plaintext_codes.append(code)

                # Hash the code before storing
                code_hash = pwd_context.hash(code)
                recovery_code = RecoveryCode(
                    user_id=user_id,
                    code_hash=code_hash,
                    is_used=False,
                )
                recovery_codes.append(recovery_code)

            self.db.add_all(recovery_codes)
            await self.db.commit()

            return plaintext_codes

        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to generate recovery codes: {str(e)}",
            )

    async def verify_code(self, user_id: str, code: str) -> bool:
        """Verify a recovery code and mark it as used.

        Args:
            user_id: User ID
            code: Plaintext recovery code to verify

        Returns:
            True if code is valid and unused, False otherwise

        Raises:
            HTTPException: If operation fails
        """
        try:
            # Find unused recovery codes for this user
            result = await self.db.execute(
                select(RecoveryCode).where(
                    (RecoveryCode.user_id == user_id) & (not RecoveryCode.is_used)
                )
            )
            recovery_codes = result.scalars().all()

            # Check each code against bcrypt hash
            for recovery_code in recovery_codes:
                if pwd_context.verify(code, recovery_code.code_hash):
                    # Mark as used
                    recovery_code.is_used = True
                    self.db.add(recovery_code)
                    await self.db.commit()
                    return True

            return False

        except Exception as e:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to verify recovery code: {str(e)}",
            )
