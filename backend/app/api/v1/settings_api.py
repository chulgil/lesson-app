"""Settings endpoints (teacher, subscription, proposal, feedback, resources)."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_teacher, get_current_user, get_db, get_pagination
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.schemas.settings import (
    CancellationDefaultsResponse,
    CancellationDefaultsUpdate,
    FeedbackPresetCreate,
    FeedbackPresetResponse,
    FeedbackPresetUpdate,
    FeedbackTemplateCreate,
    FeedbackTemplateResponse,
    FeedbackTemplateUpdate,
    NotificationSettingsResponse,
    NotificationSettingsUpdate,
    ProposalSettingsResponse,
    ProposalSettingsUpdate,
    SubscriptionSettingsResponse,
    SubscriptionSettingsUpdate,
    TeacherSettingsResponse,
    TeacherSettingsUpdate,
    TeachingResourceCreate,
    TeachingResourceResponse,
    TeachingResourceUpdate,
    TipTemplateCreate,
    TipTemplateResponse,
    TipTemplateUpdate,
)
from app.services.settings_service import SettingsService

router = APIRouter()


# ---------------------------------------------------------------------------
# Teacher Settings
# ---------------------------------------------------------------------------


@router.get(
    "/teacher",
    response_model=TeacherSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my teacher settings",
)
async def get_teacher_settings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherSettingsResponse:
    service = SettingsService(db)
    result: TeacherSettingsResponse = await service.get_teacher_settings(current_user.id)
    return result


@router.get(
    "/teachers/{teacher_id}",
    response_model=TeacherSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public teacher settings",
)
@router.get(
    "/teacher/{teacher_id}",
    response_model=TeacherSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get public teacher settings",
)
async def get_public_teacher_settings(
    teacher_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> TeacherSettingsResponse:
    service = SettingsService(db)
    result: TeacherSettingsResponse = await service.get_public_teacher_settings(teacher_id)
    return result


@router.put(
    "/teacher",
    response_model=TeacherSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Update teacher settings",
)
async def update_teacher_settings(
    body: TeacherSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeacherSettingsResponse:
    service = SettingsService(db)
    result: TeacherSettingsResponse = await service.update_teacher_settings(
        current_user.id, body.model_dump(exclude_none=True)
    )
    return result


# ---------------------------------------------------------------------------
# Subscription Settings
# ---------------------------------------------------------------------------


@router.get(
    "/subscription",
    response_model=SubscriptionSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get subscription settings",
)
async def get_subscription_settings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionSettingsResponse:
    service = SettingsService(db)
    result: SubscriptionSettingsResponse = await service.get_subscription_settings(current_user.id)
    return result


@router.put(
    "/subscription",
    response_model=SubscriptionSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Update subscription settings",
)
async def update_subscription_settings(
    body: SubscriptionSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> SubscriptionSettingsResponse:
    service = SettingsService(db)
    result: SubscriptionSettingsResponse = await service.update_subscription_settings(
        current_user.id, body.model_dump(exclude_none=True)
    )
    return result


# ---------------------------------------------------------------------------
# Proposal Settings
# ---------------------------------------------------------------------------


@router.get(
    "/proposal",
    response_model=ProposalSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get proposal settings",
)
async def get_proposal_settings(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> ProposalSettingsResponse:
    service = SettingsService(db)
    result: ProposalSettingsResponse = await service.get_proposal_settings(current_user.id)
    return result


@router.put(
    "/proposal",
    response_model=ProposalSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Update proposal settings",
)
async def update_proposal_settings(
    body: ProposalSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> ProposalSettingsResponse:
    service = SettingsService(db)
    result: ProposalSettingsResponse = await service.update_proposal_settings(
        current_user.id, body.model_dump(exclude_none=True)
    )
    return result


# ---------------------------------------------------------------------------
# Cancellation Defaults (#1178)
# ---------------------------------------------------------------------------


@router.get(
    "/cancellation",
    response_model=CancellationDefaultsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get my cancellation defaults",
)
async def get_cancellation_defaults(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> CancellationDefaultsResponse:
    service = SettingsService(db)
    result = await service.get_cancellation_defaults(current_user.id)
    return result


@router.put(
    "/cancellation",
    response_model=CancellationDefaultsResponse,
    status_code=status.HTTP_200_OK,
    summary="Update my cancellation defaults",
)
async def update_cancellation_defaults(
    body: CancellationDefaultsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> CancellationDefaultsResponse:
    service = SettingsService(db)
    result = await service.update_cancellation_defaults(current_user.id, body.model_dump(exclude_unset=True))
    return result


# ---------------------------------------------------------------------------
# Notification Settings
# ---------------------------------------------------------------------------


@router.get(
    "/notification/{target_user_id}",
    response_model=NotificationSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Get notification settings for a target",
)
async def get_notification_settings(
    target_user_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> NotificationSettingsResponse:
    service = SettingsService(db)
    result: NotificationSettingsResponse = await service.get_notification_settings(current_user.id, target_user_id)
    return result


@router.put(
    "/notification/{target_user_id}",
    response_model=NotificationSettingsResponse,
    status_code=status.HTTP_200_OK,
    summary="Update notification settings for a target",
)
async def update_notification_settings(
    target_user_id: str,
    body: NotificationSettingsUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> NotificationSettingsResponse:
    service = SettingsService(db)
    result: NotificationSettingsResponse = await service.update_notification_settings(
        current_user.id, target_user_id, body.model_dump(exclude_none=True)
    )
    return result


# ---------------------------------------------------------------------------
# Feedback Presets
# ---------------------------------------------------------------------------


@router.get(
    "/feedback-presets",
    response_model=list[FeedbackPresetResponse],
    status_code=status.HTTP_200_OK,
    summary="List feedback presets",
)
async def list_feedback_presets(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> list[FeedbackPresetResponse]:
    service = SettingsService(db)
    return await service.get_feedback_presets(current_user.id)


@router.post(
    "/feedback-presets",
    response_model=FeedbackPresetResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create feedback preset",
)
async def create_feedback_preset(
    body: FeedbackPresetCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> FeedbackPresetResponse:
    service = SettingsService(db)
    result: FeedbackPresetResponse = await service.create_feedback_preset(current_user.id, body.text, body.sort_order)
    return result


@router.put(
    "/feedback-presets/{preset_id}",
    response_model=FeedbackPresetResponse,
    status_code=status.HTTP_200_OK,
    summary="Update feedback preset",
)
async def update_feedback_preset(
    preset_id: str,
    body: FeedbackPresetUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> FeedbackPresetResponse:
    service = SettingsService(db)
    result: FeedbackPresetResponse = await service.update_feedback_preset(
        preset_id, body.model_dump(exclude_none=True), current_user.id
    )
    return result


@router.delete(
    "/feedback-presets/{preset_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete feedback preset",
)
async def delete_feedback_preset(
    preset_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    service = SettingsService(db)
    await service.delete_feedback_preset(preset_id, current_user.id)


# ---------------------------------------------------------------------------
# Feedback Templates
# ---------------------------------------------------------------------------


@router.get(
    "/feedback-templates",
    response_model=list[FeedbackTemplateResponse],
    status_code=status.HTTP_200_OK,
    summary="List feedback templates",
)
async def list_feedback_templates(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    category: str | None = None,
    tag: str | None = None,
    query: str | None = None,
    frequent: bool = False,
    limit: int | None = None,
) -> list[FeedbackTemplateResponse]:
    service = SettingsService(db)
    return await service.get_feedback_templates(
        current_user.id,
        category=category,
        tag=tag,
        query=query,
        frequent=frequent,
        limit=limit,
    )


@router.post(
    "/feedback-templates",
    response_model=FeedbackTemplateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create feedback template",
)
async def create_feedback_template(
    body: FeedbackTemplateCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> FeedbackTemplateResponse:
    service = SettingsService(db)
    result: FeedbackTemplateResponse = await service.create_feedback_template(
        current_user.id,
        body.model_dump(),
    )
    return result


@router.get(
    "/feedback-templates/{template_id}",
    response_model=FeedbackTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Get feedback template",
)
async def get_feedback_template(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> FeedbackTemplateResponse:
    service = SettingsService(db)
    result: FeedbackTemplateResponse = await service.get_feedback_template(template_id, current_user.id)
    return result


@router.put(
    "/feedback-templates/{template_id}",
    response_model=FeedbackTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update feedback template",
)
async def update_feedback_template(
    template_id: str,
    body: FeedbackTemplateUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> FeedbackTemplateResponse:
    service = SettingsService(db)
    result: FeedbackTemplateResponse = await service.update_feedback_template(
        template_id,
        current_user.id,
        body.model_dump(exclude_none=True),
    )
    return result


@router.patch(
    "/feedback-templates/{template_id}/usage",
    response_model=FeedbackTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Increment feedback template usage",
)
async def increment_feedback_template_usage(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> FeedbackTemplateResponse:
    service = SettingsService(db)
    result: FeedbackTemplateResponse = await service.increment_feedback_template_usage(
        template_id,
        current_user.id,
    )
    return result


@router.delete(
    "/feedback-templates/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete feedback template",
)
async def delete_feedback_template(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    service = SettingsService(db)
    await service.delete_feedback_template(template_id, current_user.id)


# ---------------------------------------------------------------------------
# Tip Templates
# ---------------------------------------------------------------------------


@router.get(
    "/tip-templates",
    response_model=list[TipTemplateResponse],
    status_code=status.HTTP_200_OK,
    summary="List tip templates",
)
async def list_tip_templates(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    category: str | None = None,
    instrument: str | None = None,
    query: str | None = None,
    frequent: bool = False,
    limit: int | None = None,
) -> list[TipTemplateResponse]:
    service = SettingsService(db)
    return await service.get_tip_templates(
        current_user.id,
        category=category,
        instrument=instrument,
        query=query,
        frequent=frequent,
        limit=limit,
    )


@router.post(
    "/tip-templates",
    response_model=TipTemplateResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create tip template",
)
async def create_tip_template(
    body: TipTemplateCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TipTemplateResponse:
    service = SettingsService(db)
    result: TipTemplateResponse = await service.create_tip_template(
        current_user.id,
        body.model_dump(),
    )
    return result


@router.get(
    "/tip-templates/{template_id}",
    response_model=TipTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Get tip template",
)
async def get_tip_template(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TipTemplateResponse:
    service = SettingsService(db)
    result: TipTemplateResponse = await service.get_tip_template(template_id, current_user.id)
    return result


@router.put(
    "/tip-templates/{template_id}",
    response_model=TipTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update tip template",
)
async def update_tip_template(
    template_id: str,
    body: TipTemplateUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TipTemplateResponse:
    service = SettingsService(db)
    result: TipTemplateResponse = await service.update_tip_template(
        template_id,
        current_user.id,
        body.model_dump(exclude_none=True),
    )
    return result


@router.patch(
    "/tip-templates/{template_id}/usage",
    response_model=TipTemplateResponse,
    status_code=status.HTTP_200_OK,
    summary="Increment tip template usage",
)
async def increment_tip_template_usage(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TipTemplateResponse:
    service = SettingsService(db)
    result: TipTemplateResponse = await service.increment_tip_template_usage(
        template_id,
        current_user.id,
    )
    return result


@router.delete(
    "/tip-templates/{template_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete tip template",
)
async def delete_tip_template(
    template_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    service = SettingsService(db)
    await service.delete_tip_template(template_id, current_user.id)


# ---------------------------------------------------------------------------
# Teaching Resources
# ---------------------------------------------------------------------------


@router.get(
    "/teaching-resources",
    response_model=PaginatedResponse[TeachingResourceResponse],
    status_code=status.HTTP_200_OK,
    summary="List teaching resources",
)
async def list_teaching_resources(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
    pagination: Annotated[dict, Depends(get_pagination)],
    tag: str | None = None,
    query: str | None = None,
) -> PaginatedResponse[TeachingResourceResponse]:
    service = SettingsService(db)
    return await service.get_teaching_resources(
        current_user.id,
        page=pagination["page"],
        size=pagination["size"],
        offset=pagination["offset"],
        tag=tag,
        query=query,
    )


@router.post(
    "/teaching-resources",
    response_model=TeachingResourceResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create teaching resource",
)
async def create_teaching_resource(
    body: TeachingResourceCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeachingResourceResponse:
    service = SettingsService(db)
    result: TeachingResourceResponse = await service.create_teaching_resource(current_user.id, body.model_dump())
    return result


@router.get(
    "/teaching-resources/{resource_id}",
    response_model=TeachingResourceResponse,
    status_code=status.HTTP_200_OK,
    summary="Get teaching resource",
)
async def get_teaching_resource(
    resource_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeachingResourceResponse:
    service = SettingsService(db)
    result: TeachingResourceResponse = await service.get_teaching_resource(resource_id, current_user.id)
    return result


@router.put(
    "/teaching-resources/{resource_id}",
    response_model=TeachingResourceResponse,
    status_code=status.HTTP_200_OK,
    summary="Update teaching resource",
)
async def update_teaching_resource(
    resource_id: str,
    body: TeachingResourceUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> TeachingResourceResponse:
    service = SettingsService(db)
    result: TeachingResourceResponse = await service.update_teaching_resource(
        resource_id, body.model_dump(exclude_none=True), current_user.id
    )
    return result


@router.delete(
    "/teaching-resources/{resource_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete teaching resource",
)
async def delete_teaching_resource(
    resource_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_teacher)],
) -> None:
    service = SettingsService(db)
    await service.delete_teaching_resource(resource_id, current_user.id)
