"""AC-M2 §8.4 직전 active_context 자동 복원 (CT-10) 회귀 테스트.

별도 파일로 분리 — test_auth.py 에는 INTERNAL_API_KEY 관련 test fixture
secret 이 있어 pre-push 보안 훅이 false-positive 로 차단함. 본 파일은
§8.4 신규 테스트만 격리.
"""

from datetime import UTC, datetime

import pytest
from httpx import AsyncClient

from app.core.security import create_refresh_token, decode_access_token


@pytest.mark.asyncio
async def test_refresh_token_restores_last_active_context(create_test_user, db_session):
    """CT-10: refresh 시 직전 ContextSwitchLog 의 active_context 자동 복원."""
    from app.models.academy import Academy, AcademyMember, AcademyMemberRole
    from app.models.academy_governance import (
        AcademyContext,
        ContextSwitchLog,
        ContextSwitchTrigger,
    )
    from app.services.auth_service import AuthService

    user = await create_test_user(user_id="resume-user", role="teacher", email="resume@test.com")
    academy = Academy(
        slug=f"resume-{datetime.now(UTC).timestamp()}",
        name="Resume Academy",
        owner_user_id=user.id,
    )
    db_session.add(academy)
    await db_session.flush()
    db_session.add_all(
        [
            AcademyMember(academy_id=academy.id, user_id=user.id, role=AcademyMemberRole.owner),
            AcademyMember(academy_id=academy.id, user_id=user.id, role=AcademyMemberRole.teacher),
        ]
    )
    db_session.add(
        ContextSwitchLog(
            user_id=user.id,
            academy_id=academy.id,
            from_context=AcademyContext.academy_owner,
            to_context=AcademyContext.teacher,
            switched_at=datetime.now(UTC),
            triggered_by=ContextSwitchTrigger.user,
        )
    )
    await db_session.commit()

    refresh = create_refresh_token(data={"sub": user.id, "role": "teacher"})
    result = await AuthService(db_session).refresh_token(refresh)
    decoded = decode_access_token(result.access_token)
    assert decoded is not None
    assert decoded["active_context"] == "teacher"
    assert decoded["academy_id"] == academy.id


@pytest.mark.asyncio
async def test_refresh_token_falls_back_to_owner_when_teacher_revoked(create_test_user, db_session):
    """직전이 teacher 였지만 강사 자격 박탈 → owner 로 fallback."""
    from app.models.academy import Academy, AcademyMember, AcademyMemberRole
    from app.models.academy_governance import (
        AcademyContext,
        ContextSwitchLog,
        ContextSwitchTrigger,
    )
    from app.services.auth_service import AuthService

    user = await create_test_user(user_id="fallback-user", role="teacher", email="fb@test.com")
    academy = Academy(slug=f"fb-{datetime.now(UTC).timestamp()}", name="FB", owner_user_id=user.id)
    db_session.add(academy)
    await db_session.flush()
    db_session.add(AcademyMember(academy_id=academy.id, user_id=user.id, role=AcademyMemberRole.owner))
    db_session.add(
        AcademyMember(
            academy_id=academy.id,
            user_id=user.id,
            role=AcademyMemberRole.teacher,
            access_revoked_at=datetime.now(UTC),
        )
    )
    db_session.add(
        ContextSwitchLog(
            user_id=user.id,
            academy_id=academy.id,
            from_context=AcademyContext.academy_owner,
            to_context=AcademyContext.teacher,
            switched_at=datetime.now(UTC),
            triggered_by=ContextSwitchTrigger.user,
        )
    )
    await db_session.commit()

    refresh = create_refresh_token(data={"sub": user.id, "role": "teacher"})
    result = await AuthService(db_session).refresh_token(refresh)
    decoded = decode_access_token(result.access_token)
    assert decoded["active_context"] == "academy_owner"
    assert decoded["academy_id"] == academy.id


@pytest.mark.asyncio
async def test_refresh_token_omits_context_when_no_membership(create_test_user, db_session):
    """멤버십 0개 + ContextSwitchLog 0개 → active_context 미설정."""
    from app.services.auth_service import AuthService

    user = await create_test_user(user_id="lonely-user", role="teacher", email="lonely@test.com")
    refresh = create_refresh_token(data={"sub": user.id, "role": "teacher"})

    result = await AuthService(db_session).refresh_token(refresh)
    decoded = decode_access_token(result.access_token)
    assert "active_context" not in decoded
    assert "academy_id" not in decoded


@pytest.mark.asyncio
async def test_dev_login_restores_last_active_context(
    client: AsyncClient,
    db_session,
    create_test_user,
):
    """dev_login 도 직전 active_context 복원."""
    from unittest.mock import patch

    from app.models.academy import Academy, AcademyMember, AcademyMemberRole
    from app.models.academy_governance import (
        AcademyContext,
        ContextSwitchLog,
        ContextSwitchTrigger,
    )

    user = await create_test_user(user_id="dev-resume", role="teacher", email="devresume@test.com")
    academy = Academy(
        slug=f"dev-{datetime.now(UTC).timestamp()}",
        name="Dev Academy",
        owner_user_id=user.id,
    )
    db_session.add(academy)
    await db_session.flush()
    db_session.add(AcademyMember(academy_id=academy.id, user_id=user.id, role=AcademyMemberRole.owner))
    db_session.add(
        ContextSwitchLog(
            user_id=user.id,
            academy_id=academy.id,
            from_context=AcademyContext.teacher,
            to_context=AcademyContext.academy_owner,
            switched_at=datetime.now(UTC),
            triggered_by=ContextSwitchTrigger.user,
        )
    )
    await db_session.commit()

    with patch("app.core.config.settings.ENVIRONMENT", "development"):
        response = await client.post(
            "/api/v1/auth/dev-login",
            json={"email": "devresume@test.com", "role": "teacher"},
        )
    assert response.status_code == 200
    decoded = decode_access_token(response.json()["access_token"])
    assert decoded["active_context"] == "academy_owner"
    assert decoded["academy_id"] == academy.id
