"""Teacher referral service – referral code management and rewards."""

from __future__ import annotations

import string
from datetime import UTC, datetime
from random import choice

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.referral import ReferralStatus, TeacherReferral
from app.models.teacher import Teacher


class ReferralService:
    """Handle teacher referral lifecycle and reward logic."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_or_create_referral_code(self, teacher_id: str) -> str:
        """Get existing referral code or create a new one.

        Returns:
            The 8-character alphanumeric referral code.
        """
        teacher = await self.db.scalar(select(Teacher).where(Teacher.id == teacher_id))
        if teacher is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Teacher not found",
            )

        # If code exists, return it
        if teacher.referral_code:
            return teacher.referral_code

        # Generate new code
        code = self._generate_referral_code()

        # Create TeacherReferral record
        referral = TeacherReferral(
            referrer_id=teacher_id,
            referral_code=code,
            status=ReferralStatus.PENDING,
        )
        self.db.add(referral)

        # Update teacher with code
        teacher.referral_code = code
        self.db.add(teacher)

        await self.db.commit()
        return code

    async def apply_referral_code(self, new_teacher_id: str, code: str) -> str:
        """Apply referral code to a newly registered teacher.

        Args:
            new_teacher_id: ID of the newly registered teacher.
            code: Referral code to apply.

        Returns:
            Confirmation message.

        Raises:
            HTTPException: If code is invalid or already used.
        """
        # Find the referral record
        referral = await self.db.scalar(
            select(TeacherReferral).where(TeacherReferral.referral_code == code)
        )
        if referral is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid referral code",
            )

        if referral.status != ReferralStatus.PENDING:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="This referral code has already been used",
            )

        # Link the referral
        referral.referred_teacher_id = new_teacher_id
        referral.status = ReferralStatus.COMPLETED
        self.db.add(referral)
        await self.db.commit()

        return "Referral code applied successfully"

    async def check_and_reward(self, referrer_id: str) -> dict | None:
        """Check if referrer has reached reward threshold and apply reward.

        Reward tiers:
        - 1 completed: notification
        - 3 completed: pro_2weeks
        - 5 completed: pro_1month
        - 10 completed: pro_3months

        Args:
            referrer_id: ID of the teacher who referred others.

        Returns:
            Reward info dict with {reward_type, count} or None if no new reward.
        """
        # Count completed referrals for this teacher
        completed_count = await self.db.scalar(
            select(func.count(TeacherReferral.id)).where(
                TeacherReferral.referrer_id == referrer_id,
                TeacherReferral.status.in_([ReferralStatus.COMPLETED, ReferralStatus.REWARDED]),
            )
        )

        # Determine if new reward applies
        reward_map = {
            10: "pro_3months",
            5: "pro_1month",
            3: "pro_2weeks",
            1: "notification",
        }

        new_reward = None
        for threshold in sorted(reward_map.keys(), reverse=True):
            if completed_count >= threshold:
                new_reward = reward_map[threshold]
                break

        if new_reward is None:
            return None

        # Check if this reward has already been given
        existing = await self.db.scalar(
            select(TeacherReferral).where(
                TeacherReferral.referrer_id == referrer_id,
                TeacherReferral.reward_type == new_reward,
            )
        )
        if existing is not None:
            # Reward already applied
            return None

        # Create a record for this reward
        reward_record = TeacherReferral(
            referrer_id=referrer_id,
            referred_teacher_id=None,
            referral_code=f"reward_{new_reward}_{referrer_id[:8]}",
            status=ReferralStatus.REWARDED,
            reward_type=new_reward,
            rewarded_at=datetime.now(UTC),
        )
        self.db.add(reward_record)
        await self.db.commit()

        return {
            "reward_type": new_reward,
            "completed_count": completed_count,
        }

    async def get_referral_stats(self, teacher_id: str) -> dict:
        """Get referral statistics for a teacher.

        Returns:
            Dict with total_generated, completed, rewarded counts.
        """
        # Count total referral codes generated
        total = await self.db.scalar(
            select(func.count(TeacherReferral.id)).where(
                TeacherReferral.referrer_id == teacher_id,
                TeacherReferral.referred_teacher_id.isnot(None)
                | (TeacherReferral.reward_type.isnot(None)),
            )
        )

        # Count completed referrals
        completed = await self.db.scalar(
            select(func.count(TeacherReferral.id)).where(
                TeacherReferral.referrer_id == teacher_id,
                TeacherReferral.status == ReferralStatus.COMPLETED,
            )
        )

        # Count rewarded
        rewarded = await self.db.scalar(
            select(func.count(TeacherReferral.id)).where(
                TeacherReferral.referrer_id == teacher_id,
                TeacherReferral.status == ReferralStatus.REWARDED,
            )
        )

        return {
            "total_referrals": total or 0,
            "completed_referrals": completed or 0,
            "rewarded_count": rewarded or 0,
        }

    # -----------------------------------------------------------------------
    # Helpers
    # -----------------------------------------------------------------------

    def _generate_referral_code(self) -> str:
        """Generate a unique 8-character alphanumeric referral code."""
        chars = string.ascii_uppercase + string.digits
        # Remove confusing characters: 0, O, 1, I, L
        chars = chars.replace("0", "").replace("O", "").replace("1", "").replace("I", "").replace("L", "")
        return "".join(choice(chars) for _ in range(8))
