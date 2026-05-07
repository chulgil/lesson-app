"""User profile service."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.user import (
    LocaleUpdate,
    OnboardingProgressResponse,
    OnboardingProgressUpdate,
    OnboardingQuestListResponse,
    OnboardingQuestResponse,
    SupportedLocale,
    SupportedLocalesResponse,
    UserUpdate,
)


@dataclass(frozen=True)
class QuestDefinition:
    id: str
    title: str
    description: str
    category: str = "required"
    celebration_message: str | None = None


QUESTS_BY_ROLE: dict[str, list[QuestDefinition]] = {
    "teacher": [
        QuestDefinition(
            id="teacher.profile",
            title="프로필 완성",
            description="이름, 악기, 프로필 사진을 정리해 학생이 선생님을 알아볼 수 있게 합니다.",
            celebration_message="프로필 준비가 끝났습니다.",
        ),
        QuestDefinition(
            id="teacher.firstStudent",
            title="첫 학생 추가",
            description="학생을 추가하거나 초대 코드로 연결합니다.",
            celebration_message="첫 학생 연결 준비가 끝났습니다.",
        ),
        QuestDefinition(
            id="teacher.firstLesson",
            title="첫 레슨 등록",
            description="캘린더에 첫 레슨을 등록합니다.",
            celebration_message="첫 레슨이 준비됐습니다.",
        ),
    ],
    "student": [
        QuestDefinition(
            id="student.profile",
            title="프로필 완성",
            description="이름과 악기 정보를 설정합니다.",
            celebration_message="프로필 준비가 끝났습니다.",
        ),
        QuestDefinition(
            id="student.metronome",
            title="메트로놈 사용",
            description="메트로놈을 켜고 BPM을 조절해봅니다.",
            celebration_message="첫 연습 도구를 사용했습니다.",
        ),
        QuestDefinition(
            id="student.firstRecording",
            title="첫 녹음",
            description="짧은 연습 녹음을 남깁니다.",
            celebration_message="첫 녹음을 저장했습니다.",
        ),
    ],
    "parent": [
        QuestDefinition(
            id="parent.profile",
            title="프로필 완성",
            description="학부모 프로필 정보를 설정합니다.",
            celebration_message="프로필 준비가 끝났습니다.",
        ),
        QuestDefinition(
            id="parent.addChild",
            title="자녀 프로필 추가",
            description="자녀 프로필을 만들거나 초대 코드로 연결합니다.",
            celebration_message="자녀 프로필이 준비됐습니다.",
        ),
        QuestDefinition(
            id="parent.viewLesson",
            title="레슨 현황 확인",
            description="자녀 레슨 현황을 확인합니다.",
            celebration_message="레슨 현황 확인 준비가 끝났습니다.",
        ),
    ],
}


class UserService:
    """Handle user profile operations."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_by_id(self, user_id: str) -> Any:
        """Return a user by ID or raise 404."""
        from app.models.user import User

        user = await self.db.get(User, user_id)
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user

    async def update_profile(self, user_id: str, data: UserUpdate) -> Any:
        """Update mutable profile fields."""
        user = await self.get_by_id(user_id)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update_role(self, user_id: str, role: str) -> Any:
        """Set user role (used during onboarding)."""
        user = await self.get_by_id(user_id)
        user.role = role
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update_locale(self, user_id: str, data: LocaleUpdate) -> Any:
        """Update locale / country / timezone / currency."""
        user = await self.get_by_id(user_id)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(user, key, value)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def complete_onboarding(self, user_id: str) -> Any:
        """Mark onboarding as completed."""
        user = await self.get_by_id(user_id)
        user.onboarding_completed = True
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def get_onboarding_progress(self, current_user: Any) -> OnboardingProgressResponse:
        """Return onboarding progress, creating a progress row on first access."""
        progress = await self._get_or_create_progress(current_user.id)
        return await self._progress_response(current_user, progress)

    async def update_onboarding_progress(
        self,
        current_user: Any,
        data: OnboardingProgressUpdate,
    ) -> OnboardingProgressResponse:
        """Update patchable onboarding progress fields."""
        progress = await self._get_or_create_progress(current_user.id)
        update_data = data.model_dump(exclude_unset=True)
        if "profile_completeness" in update_data:
            update_data["profile_completeness"] = max(0, min(100, update_data["profile_completeness"]))
        for key, value in update_data.items():
            setattr(progress, key, value)
        await self.db.flush()
        await self.db.refresh(progress)
        return await self._progress_response(current_user, progress)

    async def get_onboarding_quests(self, current_user: Any) -> OnboardingQuestListResponse:
        """Return role-specific quests with current completion state."""
        progress = await self._get_or_create_progress(current_user.id)
        response = await self._progress_response(current_user, progress)
        return OnboardingQuestListResponse(quests=response.quests)

    async def complete_onboarding_quest(self, current_user: Any, quest_id: str) -> OnboardingProgressResponse:
        """Mark a quest complete idempotently."""
        from app.models.onboarding import UserOnboardingQuestProgress

        quest = self._quest_definition(current_user, quest_id)
        progress = await self._get_or_create_progress(current_user.id)
        existing = await self.db.scalar(
            select(UserOnboardingQuestProgress).where(
                UserOnboardingQuestProgress.user_id == current_user.id,
                UserOnboardingQuestProgress.quest_id == quest.id,
            )
        )
        if existing is None:
            self.db.add(
                UserOnboardingQuestProgress(
                    user_id=current_user.id,
                    quest_id=quest.id,
                    status="completed",
                    completed_at=datetime.now(UTC),
                )
            )
        else:
            existing.status = "completed"
            existing.completed_at = existing.completed_at or datetime.now(UTC)

        await self.db.flush()
        response = await self._progress_response(current_user, progress)
        if response.is_all_required_completed:
            progress.current_phase = "completed"
            progress.completed_at = progress.completed_at or datetime.now(UTC)
            user = await self.get_by_id(current_user.id)
            user.onboarding_completed = True
            await self.db.flush()
            await self.db.refresh(progress)
            response = await self._progress_response(current_user, progress)
        return response

    async def _get_or_create_progress(self, user_id: str) -> Any:
        from app.models.onboarding import UserOnboardingProgress

        progress = await self.db.scalar(
            select(UserOnboardingProgress).where(UserOnboardingProgress.user_id == user_id)
        )
        if progress is None:
            progress = UserOnboardingProgress(user_id=user_id)
            self.db.add(progress)
            await self.db.flush()
            await self.db.refresh(progress)
        return progress

    def _quest_definitions(self, current_user: Any) -> list[QuestDefinition]:
        role = getattr(getattr(current_user, "role", None), "value", getattr(current_user, "role", None))
        return QUESTS_BY_ROLE.get(role or "", [])

    def _quest_definition(self, current_user: Any, quest_id: str) -> QuestDefinition:
        for quest in self._quest_definitions(current_user):
            if quest.id == quest_id:
                return quest
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quest not found")

    async def _quest_completion_map(self, user_id: str) -> dict[str, Any]:
        from app.models.onboarding import UserOnboardingQuestProgress

        result = await self.db.scalars(
            select(UserOnboardingQuestProgress).where(UserOnboardingQuestProgress.user_id == user_id)
        )
        return {row.quest_id: row for row in result.all()}

    async def _progress_response(self, current_user: Any, progress: Any) -> OnboardingProgressResponse:
        completed = await self._quest_completion_map(current_user.id)
        quest_definitions = self._quest_definitions(current_user)
        quests = [
            OnboardingQuestResponse(
                id=quest.id,
                title=quest.title,
                description=quest.description,
                category=quest.category,
                status="completed" if quest.id in completed else "available",
                completed_at=completed[quest.id].completed_at if quest.id in completed else None,
                celebration_message=quest.celebration_message,
            )
            for quest in quest_definitions
        ]
        completed_count = sum(1 for quest in quests if quest.status == "completed")
        total_required = sum(1 for quest in quests if quest.category == "required")
        completed_required = sum(1 for quest in quests if quest.category == "required" and quest.status == "completed")
        is_all_required_completed = total_required > 0 and completed_required == total_required
        role = getattr(getattr(current_user, "role", None), "value", getattr(current_user, "role", None))
        return OnboardingProgressResponse(
            user_id=current_user.id,
            role=role,
            current_phase=progress.current_phase,
            quests=quests,
            profile_completeness=progress.profile_completeness,
            walkthrough_skipped=progress.walkthrough_skipped,
            coach_marks_seen=progress.coach_marks_seen or {},
            coach_marks_dismissed=progress.coach_marks_dismissed or {},
            started_at=progress.created_at,
            completed_at=progress.completed_at,
            completed_quest_count=completed_count,
            total_required_quests=total_required,
            is_all_required_completed=is_all_required_completed,
            progress_percentage=(completed_required / total_required * 100) if total_required else 0,
        )

    @staticmethod
    def get_supported_locales() -> SupportedLocalesResponse:
        """Return the static list of supported locales."""
        return SupportedLocalesResponse(
            locales=[
                SupportedLocale(
                    locale="ko",
                    language_name="Korean",
                    native_name="\ud55c\uad6d\uc5b4",
                    default_country="KR",
                ),
                SupportedLocale(
                    locale="en",
                    language_name="English",
                    native_name="English",
                    default_country="US",
                ),
                SupportedLocale(
                    locale="ja",
                    language_name="Japanese",
                    native_name="\u65e5\u672c\u8a9e",
                    default_country="JP",
                ),
            ]
        )
