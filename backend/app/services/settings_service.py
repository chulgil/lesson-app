"""Settings service (teacher, subscription, proposal, notification, feedback, resource)."""

from __future__ import annotations

from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.common import PaginatedResponse


class SettingsService:
    """Handle various settings CRUD."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # -----------------------------------------------------------------------
    # Teacher Settings
    # -----------------------------------------------------------------------

    async def get_teacher_settings(self, teacher_id: str) -> Any:
        from app.models.settings import TeacherSettings

        settings = await self.db.scalar(
            select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id)
        )
        if settings is None:
            settings = TeacherSettings(teacher_id=teacher_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def update_teacher_settings(self, teacher_id: str, data: dict) -> Any:
        settings = await self.get_teacher_settings(teacher_id)
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    # -----------------------------------------------------------------------
    # Subscription Settings
    # -----------------------------------------------------------------------

    async def get_subscription_settings(self, teacher_id: str) -> Any:
        from app.models.settings import SubscriptionSettings

        settings = await self.db.scalar(
            select(SubscriptionSettings).where(SubscriptionSettings.teacher_id == teacher_id)
        )
        if settings is None:
            settings = SubscriptionSettings(teacher_id=teacher_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def update_subscription_settings(self, teacher_id: str, data: dict) -> Any:
        settings = await self.get_subscription_settings(teacher_id)
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    # -----------------------------------------------------------------------
    # Proposal Settings
    # -----------------------------------------------------------------------

    async def get_proposal_settings(self, teacher_id: str) -> Any:
        from app.models.settings import ProposalSettings

        settings = await self.db.scalar(
            select(ProposalSettings).where(ProposalSettings.teacher_id == teacher_id)
        )
        if settings is None:
            settings = ProposalSettings(teacher_id=teacher_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def update_proposal_settings(self, teacher_id: str, data: dict) -> Any:
        settings = await self.get_proposal_settings(teacher_id)
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    # -----------------------------------------------------------------------
    # Notification Settings (per-relationship)
    # -----------------------------------------------------------------------

    async def get_notification_settings(self, user_id: str, target_user_id: str) -> Any:
        from app.models.settings import NotificationSettings

        settings = await self.db.scalar(
            select(NotificationSettings).where(
                NotificationSettings.user_id == user_id,
                NotificationSettings.target_user_id == target_user_id,
            )
        )
        if settings is None:
            settings = NotificationSettings(
                user_id=user_id,
                target_user_id=target_user_id,
            )
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def update_notification_settings(self, user_id: str, target_user_id: str, data: dict) -> Any:
        settings = await self.get_notification_settings(user_id, target_user_id)
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    # -----------------------------------------------------------------------
    # Parent Notification Settings
    # -----------------------------------------------------------------------

    async def get_parent_notification_settings(self, parent_id: str) -> Any:
        from app.models.settings import ParentNotificationSettings

        settings = await self.db.scalar(
            select(ParentNotificationSettings).where(
                ParentNotificationSettings.parent_id == parent_id
            )
        )
        if settings is None:
            settings = ParentNotificationSettings(parent_id=parent_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def update_parent_notification_settings(self, parent_id: str, data: dict) -> Any:
        settings = await self.get_parent_notification_settings(parent_id)
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    # -----------------------------------------------------------------------
    # Feedback Presets
    # -----------------------------------------------------------------------

    async def get_feedback_presets(self, teacher_id: str) -> list[Any]:
        from app.models.settings import FeedbackPreset

        result = await self.db.scalars(
            select(FeedbackPreset)
            .where(
                (FeedbackPreset.teacher_id == teacher_id) | (FeedbackPreset.is_default.is_(True)),
                FeedbackPreset.is_hidden.is_(False),
            )
            .order_by(FeedbackPreset.sort_order)
        )
        return list(result.all())

    async def create_feedback_preset(self, teacher_id: str, text: str, sort_order: int = 0) -> Any:
        from app.models.settings import FeedbackPreset

        preset = FeedbackPreset(
            teacher_id=teacher_id,
            text=text,
            sort_order=sort_order,
        )
        self.db.add(preset)
        await self.db.flush()
        await self.db.refresh(preset)
        return preset

    async def update_feedback_preset(self, preset_id: str, data: dict) -> Any:
        from app.models.settings import FeedbackPreset

        preset = await self.db.get(FeedbackPreset, preset_id)
        if preset is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Preset not found")
        for key, value in data.items():
            if value is not None:
                setattr(preset, key, value)
        await self.db.flush()
        await self.db.refresh(preset)
        return preset

    async def delete_feedback_preset(self, preset_id: str) -> None:
        from app.models.settings import FeedbackPreset

        preset = await self.db.get(FeedbackPreset, preset_id)
        if preset is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Preset not found")
        if preset.is_default:
            preset.is_hidden = True
            await self.db.flush()
        else:
            await self.db.delete(preset)
            await self.db.flush()

    # -----------------------------------------------------------------------
    # Teaching Resources
    # -----------------------------------------------------------------------

    async def get_teaching_resources(
        self, teacher_id: str, *, page: int, size: int, offset: int
    ) -> PaginatedResponse:
        from app.models.settings import TeachingResource

        query = select(TeachingResource).where(TeachingResource.teacher_id == teacher_id)
        total = await self.db.scalar(
            select(func.count()).select_from(query.subquery())
        ) or 0

        result = await self.db.scalars(
            query.order_by(TeachingResource.created_at.desc()).offset(offset).limit(size)
        )
        return PaginatedResponse.create(items=list(result.all()), total=total, page=page, size=size)

    async def get_teaching_resources_by_ids(self, ids: list[str]) -> list[Any]:
        from app.models.settings import TeachingResource

        if not ids:
            return []
        result = await self.db.scalars(
            select(TeachingResource).where(TeachingResource.id.in_(ids))
        )
        return list(result.all())

    async def create_teaching_resource(self, teacher_id: str, data: dict) -> Any:
        from app.models.settings import TeachingResource

        resource = TeachingResource(teacher_id=teacher_id, **data)
        self.db.add(resource)
        await self.db.flush()
        await self.db.refresh(resource)
        return resource

    async def update_teaching_resource(self, resource_id: str, data: dict) -> Any:
        from app.models.settings import TeachingResource

        resource = await self.db.get(TeachingResource, resource_id)
        if resource is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resource not found")
        for key, value in data.items():
            if value is not None:
                setattr(resource, key, value)
        await self.db.flush()
        await self.db.refresh(resource)
        return resource

    async def delete_teaching_resource(self, resource_id: str) -> None:
        from app.models.settings import TeachingResource

        resource = await self.db.get(TeachingResource, resource_id)
        if resource is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resource not found")
        await self.db.delete(resource)
        await self.db.flush()
