"""Settings service (teacher, subscription, proposal, notification, feedback, resource)."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import func, or_, select
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

        teacher_id = await self._resolve_teacher_user_id(teacher_id)
        settings = await self.db.scalar(
            select(TeacherSettings).where(TeacherSettings.teacher_id == teacher_id)
        )
        if settings is None:
            settings = TeacherSettings(teacher_id=teacher_id)
            self.db.add(settings)
            await self.db.flush()
        await self.db.refresh(settings)
        return settings

    async def get_public_teacher_settings(self, teacher_id: str) -> Any:
        """Return settings for a target teacher, using defaults when unset."""
        return await self.get_teacher_settings(teacher_id)

    async def update_teacher_settings(self, teacher_id: str, data: dict) -> Any:
        settings = await self.get_teacher_settings(teacher_id)
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    async def _resolve_teacher_user_id(self, teacher_id: str) -> str:
        """Accept either Teacher.id or User.id and return the owning User.id."""
        from app.models.teacher import Teacher

        teacher = await self.db.get(Teacher, teacher_id)
        if teacher:
            return teacher.user_id
        return teacher_id

    # -----------------------------------------------------------------------
    # Subscription Settings
    # -----------------------------------------------------------------------

    async def get_subscription_settings(self, teacher_id: str) -> Any:
        from app.models.settings import SubscriptionSettings

        teacher_id = await self._resolve_subscription_teacher_id(teacher_id)

        settings = await self.db.scalar(
            select(SubscriptionSettings).where(SubscriptionSettings.teacher_id == teacher_id)
        )
        if settings is None:
            settings = SubscriptionSettings(teacher_id=teacher_id)
            self.db.add(settings)
            await self.db.flush()
            await self.db.refresh(settings)
        return settings

    async def get_subscription_settings_by_teacher(self, teacher_id: str) -> Any:
        from app.models.settings import SubscriptionSettings

        teacher_id = await self._resolve_subscription_teacher_id(teacher_id)
        settings = await self.db.scalar(
            select(SubscriptionSettings).where(SubscriptionSettings.teacher_id == teacher_id)
        )
        if settings is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription settings not found")
        return settings

    async def get_subscription_settings_by_organization(self, organization_id: str) -> Any:
        from app.models.settings import SubscriptionSettings

        settings = await self.db.scalar(
            select(SubscriptionSettings).where(SubscriptionSettings.organization_id == organization_id)
        )
        if settings is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription settings not found")
        return settings

    async def create_subscription_settings(self, data: dict, current_user: Any | None = None) -> Any:
        from app.models.settings import SubscriptionSettings

        data = await self._normalize_subscription_settings_data(data)
        if current_user is not None:
            await self._assert_subscription_settings_owner(data, current_user)
        settings = SubscriptionSettings(**data)
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

    async def update_subscription_settings_by_id(
        self,
        settings_id: str,
        data: dict,
        current_user: Any | None = None,
    ) -> Any:
        from app.models.settings import SubscriptionSettings

        settings = await self.db.get(SubscriptionSettings, settings_id)
        if settings is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subscription settings not found")
        data = await self._normalize_subscription_settings_data(data)
        if current_user is not None:
            await self._assert_subscription_settings_owner(
                {
                    "teacher_id": data.get("teacher_id", settings.teacher_id),
                    "organization_id": data.get("organization_id", settings.organization_id),
                },
                current_user,
            )
        for key, value in data.items():
            if value is not None:
                setattr(settings, key, value)
        await self.db.flush()
        await self.db.refresh(settings)
        return settings

    async def _normalize_subscription_settings_data(self, data: dict) -> dict:
        """Normalize subscription settings teacher_id values to Teacher.id."""
        if data.get("teacher_id") is None:
            return data
        normalized = dict(data)
        normalized["teacher_id"] = await self._resolve_subscription_teacher_id(data["teacher_id"])
        return normalized

    async def _resolve_subscription_teacher_id(self, teacher_id: str) -> str:
        """Accept either User.id or Teacher.id and return the canonical Teacher.id."""
        from app.models.teacher import Teacher
        from app.services.teacher_id_resolver import resolve_teacher_id

        teacher = await self.db.get(Teacher, teacher_id)
        if teacher is not None:
            return teacher_id
        return await resolve_teacher_id(self.db, teacher_id)

    async def _assert_subscription_settings_owner(self, data: dict, current_user: Any) -> None:
        """Allow flat subscription settings writes only for the current teacher profile."""
        from app.services.teacher_id_resolver import resolve_teacher_id

        teacher_id = data.get("teacher_id")
        organization_id = data.get("organization_id")
        if organization_id is not None:
            return
        if teacher_id is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="teacher_id is required")
        teacher_id = await self._resolve_subscription_teacher_id(teacher_id)
        current_teacher_id = await resolve_teacher_id(self.db, current_user.id)
        if teacher_id != current_teacher_id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Forbidden")

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
    # Feedback Templates
    # -----------------------------------------------------------------------

    def _normalize_tags(self, tags: list[str] | None) -> list[str]:
        seen = set()
        normalized = []
        for tag in tags or []:
            value = tag.strip()
            if not value or value in seen:
                continue
            seen.add(value)
            normalized.append(value)
        return normalized

    async def _feedback_template_response(self, template: Any) -> dict:
        from app.models.settings import FeedbackTemplateTag

        result = await self.db.scalars(
            select(FeedbackTemplateTag.tag)
            .where(FeedbackTemplateTag.template_id == template.id)
            .order_by(FeedbackTemplateTag.tag.asc())
        )
        return {
            "id": template.id,
            "teacher_id": template.teacher_id,
            "title": template.title,
            "body": template.body,
            "tags": list(result.all()),
            "category": getattr(template.category, "value", template.category),
            "usage_count": template.usage_count,
            "created_at": template.created_at,
            "last_used_at": template.last_used_at,
            "updated_at": template.updated_at,
        }

    async def get_feedback_templates(
        self,
        teacher_id: str,
        *,
        category: str | None = None,
        tag: str | None = None,
        query: str | None = None,
        frequent: bool = False,
        limit: int | None = None,
    ) -> list[dict]:
        from app.models.settings import FeedbackTemplate, FeedbackTemplateTag

        stmt = select(FeedbackTemplate).where(FeedbackTemplate.teacher_id == teacher_id)
        if category:
            stmt = stmt.where(FeedbackTemplate.category == category)
        if tag:
            stmt = stmt.join(
                FeedbackTemplateTag,
                FeedbackTemplateTag.template_id == FeedbackTemplate.id,
            ).where(FeedbackTemplateTag.tag == tag)
        if query:
            like_query = f"%{query}%"
            tag_exists = (
                select(FeedbackTemplateTag.id)
                .where(
                    FeedbackTemplateTag.template_id == FeedbackTemplate.id,
                    FeedbackTemplateTag.tag.ilike(like_query),
                )
                .exists()
            )
            stmt = stmt.where(
                or_(
                    FeedbackTemplate.title.ilike(like_query),
                    FeedbackTemplate.body.ilike(like_query),
                    tag_exists,
                )
            )
        if frequent:
            stmt = stmt.order_by(FeedbackTemplate.usage_count.desc(), FeedbackTemplate.last_used_at.desc().nullslast())
        else:
            stmt = stmt.order_by(FeedbackTemplate.created_at.desc())
        if limit is not None:
            stmt = stmt.limit(limit)

        result = await self.db.scalars(stmt)
        return [await self._feedback_template_response(template) for template in result.unique().all()]

    async def get_feedback_template(self, template_id: str, teacher_id: str) -> dict:
        from app.models.settings import FeedbackTemplate

        template = await self.db.get(FeedbackTemplate, template_id)
        if template is None or template.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Feedback template not found")
        return await self._feedback_template_response(template)

    async def _replace_feedback_template_tags(self, template_id: str, tags: list[str]) -> None:
        from app.models.settings import FeedbackTemplateTag

        existing = await self.db.scalars(
            select(FeedbackTemplateTag).where(FeedbackTemplateTag.template_id == template_id)
        )
        for row in existing.all():
            await self.db.delete(row)
        for tag in self._normalize_tags(tags):
            self.db.add(FeedbackTemplateTag(template_id=template_id, tag=tag))

    async def create_feedback_template(self, teacher_id: str, data: dict) -> dict:
        from app.models.settings import FeedbackCategory, FeedbackTemplate

        template = FeedbackTemplate(
            teacher_id=teacher_id,
            title=data["title"],
            body=data["body"],
            category=FeedbackCategory(data.get("category") or "general"),
        )
        self.db.add(template)
        await self.db.flush()
        await self._replace_feedback_template_tags(template.id, data.get("tags") or [])
        await self.db.flush()
        await self.db.refresh(template)
        return await self._feedback_template_response(template)

    async def update_feedback_template(self, template_id: str, teacher_id: str, data: dict) -> dict:
        from app.models.settings import FeedbackCategory, FeedbackTemplate

        template = await self.db.get(FeedbackTemplate, template_id)
        if template is None or template.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Feedback template not found")
        tags = data.pop("tags", None)
        for key, value in data.items():
            if value is None:
                continue
            if key == "category":
                value = FeedbackCategory(value)
            setattr(template, key, value)
        if tags is not None:
            await self._replace_feedback_template_tags(template.id, tags)
        await self.db.flush()
        await self.db.refresh(template)
        return await self._feedback_template_response(template)

    async def increment_feedback_template_usage(self, template_id: str, teacher_id: str) -> dict:
        from app.models.settings import FeedbackTemplate

        template = await self.db.get(FeedbackTemplate, template_id)
        if template is None or template.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Feedback template not found")
        template.usage_count = (template.usage_count or 0) + 1
        template.last_used_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(template)
        return await self._feedback_template_response(template)

    async def delete_feedback_template(self, template_id: str, teacher_id: str) -> None:
        from app.models.settings import FeedbackTemplate

        template = await self.db.get(FeedbackTemplate, template_id)
        if template is None or template.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Feedback template not found")
        await self.db.delete(template)
        await self.db.flush()

    # -----------------------------------------------------------------------
    # Tip Templates
    # -----------------------------------------------------------------------

    async def get_tip_templates(
        self,
        teacher_id: str,
        *,
        category: str | None = None,
        instrument: str | None = None,
        query: str | None = None,
        frequent: bool = False,
        limit: int | None = None,
    ) -> list[Any]:
        from app.models.tip import TipTemplate

        stmt = select(TipTemplate).where(TipTemplate.teacher_id == teacher_id)
        if category:
            stmt = stmt.where(TipTemplate.category == category)
        if instrument is not None:
            stmt = stmt.where(
                or_(
                    TipTemplate.instrument == instrument,
                    TipTemplate.instrument.is_(None),
                )
            )
        if query:
            like_query = f"%{query}%"
            stmt = stmt.where(TipTemplate.content.ilike(like_query))
        if frequent:
            stmt = stmt.order_by(TipTemplate.usage_count.desc(), TipTemplate.last_used_at.desc().nullslast())
        else:
            stmt = stmt.order_by(TipTemplate.created_at.desc())
        if limit is not None:
            stmt = stmt.limit(limit)

        result = await self.db.scalars(stmt)
        return list(result.all())

    async def get_tip_template(self, template_id: str, teacher_id: str) -> Any:
        from app.models.tip import TipTemplate

        template = await self.db.get(TipTemplate, template_id)
        if template is None or template.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Tip template not found")
        return template

    async def create_tip_template(self, teacher_id: str, data: dict) -> Any:
        from app.models.tip import TipCategory, TipTemplate

        template = TipTemplate(
            teacher_id=teacher_id,
            content=data["content"],
            category=TipCategory(data.get("category") or "general"),
            instrument=data.get("instrument"),
        )
        self.db.add(template)
        await self.db.flush()
        await self.db.refresh(template)
        return template

    async def update_tip_template(self, template_id: str, teacher_id: str, data: dict) -> Any:
        from app.models.tip import TipCategory

        template = await self.get_tip_template(template_id, teacher_id)
        for key, value in data.items():
            if value is None:
                continue
            if key == "category":
                value = TipCategory(value)
            setattr(template, key, value)
        await self.db.flush()
        await self.db.refresh(template)
        return template

    async def increment_tip_template_usage(self, template_id: str, teacher_id: str) -> Any:
        template = await self.get_tip_template(template_id, teacher_id)
        template.usage_count = (template.usage_count or 0) + 1
        template.last_used_at = datetime.now(UTC)
        await self.db.flush()
        await self.db.refresh(template)
        return template

    async def delete_tip_template(self, template_id: str, teacher_id: str) -> None:
        template = await self.get_tip_template(template_id, teacher_id)
        await self.db.delete(template)
        await self.db.flush()

    # -----------------------------------------------------------------------
    # Teaching Resources
    # -----------------------------------------------------------------------

    async def get_teaching_resources(
        self,
        teacher_id: str,
        *,
        page: int,
        size: int,
        offset: int,
        tag: str | None = None,
        query: str | None = None,
    ) -> PaginatedResponse:
        from app.models.settings import TeachingResource, TeachingResourceTag

        stmt = select(TeachingResource).where(TeachingResource.teacher_id == teacher_id)
        if tag:
            stmt = stmt.join(
                TeachingResourceTag,
                TeachingResourceTag.resource_id == TeachingResource.id,
            ).where(TeachingResourceTag.tag == tag)
        if query:
            like_query = f"%{query}%"
            tag_exists = (
                select(TeachingResourceTag.id)
                .where(
                    TeachingResourceTag.resource_id == TeachingResource.id,
                    TeachingResourceTag.tag.ilike(like_query),
                )
                .exists()
            )
            stmt = stmt.where(
                or_(
                    TeachingResource.title.ilike(like_query),
                    TeachingResource.description.ilike(like_query),
                    TeachingResource.instrument.ilike(like_query),
                    tag_exists,
                )
            )
        total = await self.db.scalar(
            select(func.count()).select_from(stmt.subquery())
        ) or 0

        result = await self.db.scalars(
            stmt.order_by(TeachingResource.created_at.desc()).offset(offset).limit(size)
        )
        items = [await self._teaching_resource_response(resource) for resource in result.unique().all()]
        return PaginatedResponse.create(items=items, total=total, page=page, size=size)

    async def get_teaching_resources_by_ids(self, ids: list[str]) -> list[Any]:
        from app.models.settings import TeachingResource

        if not ids:
            return []
        result = await self.db.scalars(
            select(TeachingResource).where(TeachingResource.id.in_(ids))
        )
        return [await self._teaching_resource_response(resource) for resource in result.all()]

    async def get_teaching_resource(self, resource_id: str, teacher_id: str) -> Any:
        from app.models.settings import TeachingResource

        resource = await self.db.get(TeachingResource, resource_id)
        if resource is None or resource.teacher_id != teacher_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resource not found")
        return await self._teaching_resource_response(resource)

    async def _teaching_resource_response(self, resource: Any) -> dict:
        from app.models.settings import TeachingResourceTag

        result = await self.db.scalars(
            select(TeachingResourceTag.tag)
            .where(TeachingResourceTag.resource_id == resource.id)
            .order_by(TeachingResourceTag.tag.asc())
        )
        return {
            "id": resource.id,
            "teacher_id": resource.teacher_id,
            "type": resource.type,
            "title": resource.title,
            "description": resource.description,
            "youtube_url": resource.youtube_url,
            "youtube_video_id": resource.youtube_video_id,
            "youtube_thumbnail": resource.youtube_thumbnail,
            "youtube_start_seconds": resource.youtube_start_seconds,
            "youtube_end_seconds": resource.youtube_end_seconds,
            "audio_url": resource.audio_url,
            "audio_duration_seconds": resource.audio_duration_seconds,
            "external_url": resource.external_url,
            "instrument": resource.instrument,
            "tags": list(result.all()),
            "created_at": resource.created_at,
            "updated_at": resource.updated_at,
        }

    async def _replace_teaching_resource_tags(self, resource_id: str, tags: list[str]) -> None:
        from app.models.settings import TeachingResourceTag

        existing = await self.db.scalars(
            select(TeachingResourceTag).where(TeachingResourceTag.resource_id == resource_id)
        )
        for row in existing.all():
            await self.db.delete(row)
        for tag in self._normalize_tags(tags):
            self.db.add(TeachingResourceTag(resource_id=resource_id, tag=tag))

    async def create_teaching_resource(self, teacher_id: str, data: dict) -> Any:
        from app.models.settings import TeachingResource

        tags = data.pop("tags", [])
        resource = TeachingResource(teacher_id=teacher_id, **data)
        self.db.add(resource)
        await self.db.flush()
        await self._replace_teaching_resource_tags(resource.id, tags)
        await self.db.flush()
        await self.db.refresh(resource)
        return await self._teaching_resource_response(resource)

    async def update_teaching_resource(self, resource_id: str, data: dict) -> Any:
        from app.models.settings import TeachingResource

        resource = await self.db.get(TeachingResource, resource_id)
        if resource is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resource not found")
        tags = data.pop("tags", None)
        for key, value in data.items():
            if value is not None:
                setattr(resource, key, value)
        if tags is not None:
            await self._replace_teaching_resource_tags(resource.id, tags)
        await self.db.flush()
        await self.db.refresh(resource)
        return await self._teaching_resource_response(resource)

    async def delete_teaching_resource(self, resource_id: str) -> None:
        from app.models.settings import TeachingResource

        resource = await self.db.get(TeachingResource, resource_id)
        if resource is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resource not found")
        await self.db.delete(resource)
        await self.db.flush()
