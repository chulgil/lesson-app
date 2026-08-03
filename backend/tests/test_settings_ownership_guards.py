"""Regression tests: settings_service must not allow one teacher to mutate
another teacher's feedback presets or teaching resources by ID (IDOR).

``get_feedback_preset``/``get_teaching_resource``-style ownership checks
already existed for reads; the update/delete paths were missing them.
"""

from __future__ import annotations

import pytest
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.settings_service import SettingsService


@pytest.mark.asyncio
async def test_update_feedback_preset_rejects_other_teacher(db_session: AsyncSession, create_test_user) -> None:
    owner = await create_test_user(user_id="teacher-preset-owner", role="teacher", email="preset-owner@test.com")
    intruder = await create_test_user(
        user_id="teacher-preset-intruder", role="teacher", email="preset-intruder@test.com"
    )

    service = SettingsService(db_session)
    preset = await service.create_feedback_preset(owner.id, "원본 텍스트", 0)

    with pytest.raises(HTTPException) as exc_info:
        await service.update_feedback_preset(preset.id, {"text": "탈취 시도"}, intruder.id)
    assert exc_info.value.status_code == 404

    with pytest.raises(HTTPException) as exc_info:
        await service.delete_feedback_preset(preset.id, intruder.id)
    assert exc_info.value.status_code == 404


@pytest.mark.asyncio
async def test_update_feedback_preset_allows_owner(db_session: AsyncSession, create_test_user) -> None:
    owner = await create_test_user(user_id="teacher-preset-owner-2", role="teacher", email="preset-owner-2@test.com")

    service = SettingsService(db_session)
    preset = await service.create_feedback_preset(owner.id, "원본 텍스트", 0)

    updated = await service.update_feedback_preset(preset.id, {"text": "수정됨"}, owner.id)
    assert updated.text == "수정됨"

    await service.delete_feedback_preset(preset.id, owner.id)


@pytest.mark.asyncio
async def test_update_teaching_resource_rejects_other_teacher(db_session: AsyncSession, create_test_user) -> None:
    owner = await create_test_user(user_id="teacher-resource-owner", role="teacher", email="resource-owner@test.com")
    intruder = await create_test_user(
        user_id="teacher-resource-intruder", role="teacher", email="resource-intruder@test.com"
    )

    service = SettingsService(db_session)
    resource = await service.create_teaching_resource(
        owner.id, {"type": "externalLink", "title": "원본 자료", "tags": []}
    )

    with pytest.raises(HTTPException) as exc_info:
        await service.update_teaching_resource(resource["id"], {"title": "탈취 시도"}, intruder.id)
    assert exc_info.value.status_code == 404

    with pytest.raises(HTTPException) as exc_info:
        await service.delete_teaching_resource(resource["id"], intruder.id)
    assert exc_info.value.status_code == 404
