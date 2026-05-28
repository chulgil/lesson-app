"""OAuth cross-provider email auto-link guard (#409).

Before this guard, `AuthService._find_or_create_user` silently linked a new
OAuth provider to any existing User whose email matched the provider-returned
email. That allowed cross-provider account takeover:

1. Victim signs up via Google with email="victim@example.com"
   -> creates User(id=V) + OAuthAccount(provider=google, ...).
2. Attacker creates a Kakao account whose profile email is also
   "victim@example.com" (Kakao does not require email ownership proof at
   signup the same way Google does).
3. Attacker initiates OAuth login via Kakao.
   * `oauth_accounts` has no row for (kakao, attacker-kakao-id),
   * but `users.email = "victim@example.com"` matches,
   * old code took that match and added OAuthAccount(provider=kakao,
     provider_user_id=attacker-kakao-id, user_id=V).
4. Attacker now logs in as User V on every subsequent Kakao login.

The fix: when no OAuthAccount matches (provider, provider_user_id) but a User
with the provider-returned email exists, refuse silent linking. The caller
must take an explicit account-linking flow. We surface this as
HTTPException(409 Conflict) so the API caller cannot mistake it for a
"login succeeded" path.

These tests pin three behaviors:

* RED -> attack path raises 409, no OAuthAccount row is created.
* Regression -> brand-new email still creates a fresh user + OAuthAccount.
* Regression -> an already-linked OAuthAccount still resolves to its user.
"""

from __future__ import annotations

import pytest
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import OAuthAccount, OAuthProvider, User, UserRole
from app.schemas.auth import OAuthRequest
from app.services.auth_service import AuthService


def _oauth_request() -> OAuthRequest:
    """Build a minimal OAuthRequest suitable for `_find_or_create_user` calls."""
    return OAuthRequest(
        provider="kakao",
        code="attacker-auth-code",
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
    )


async def _insert_victim(db_session: AsyncSession) -> User:
    """Create a victim user previously signed up via Google."""
    victim = User(
        id="user-victim",
        email="victim@example.com",
        name="Victim",
        role=UserRole.teacher,
        locale="ko",
        country="KR",
        timezone="Asia/Seoul",
        currency="KRW",
    )
    db_session.add(victim)
    await db_session.flush()
    db_session.add(
        OAuthAccount(
            user_id=victim.id,
            provider=OAuthProvider.google,
            provider_user_id="google-victim-sub-123",
            provider_email="victim@example.com",
        )
    )
    await db_session.flush()
    return victim


@pytest.mark.asyncio
async def test_cross_provider_email_match_refuses_silent_link(
    db_session: AsyncSession,
) -> None:
    """Attacker on a new provider with victim's email must NOT be linked to victim.

    Pre-state:
        users(id=user-victim, email=victim@example.com)
        oauth_accounts(google, google-victim-sub-123) -> user-victim

    Attempt:
        provider=kakao, provider_user_id=kakao-attacker-id, email=victim@example.com

    Expected: HTTPException(status_code=409) and NO new OAuthAccount row.
    """
    victim = await _insert_victim(db_session)
    service = AuthService(db_session)

    attacker_provider_user = {
        "provider_user_id": "kakao-attacker-id-999",
        "email": "victim@example.com",
        "name": "Not Victim",
        "profile_image_url": None,
    }

    with pytest.raises(HTTPException) as exc_info:
        await service._find_or_create_user(
            provider="kakao",
            provider_user=attacker_provider_user,
            request=_oauth_request(),
        )

    assert exc_info.value.status_code == 409, (
        f"Cross-provider email collision must return 409 Conflict (refuse silent link), "
        f"got {exc_info.value.status_code} with detail={exc_info.value.detail!r}"
    )

    rows = (await db_session.scalars(select(OAuthAccount).where(OAuthAccount.user_id == victim.id))).all()
    assert len(rows) == 1, (
        f"Refused link must not persist a new OAuthAccount row for the victim user; "
        f"found {[(r.provider, r.provider_user_id) for r in rows]}"
    )
    assert rows[0].provider == OAuthProvider.google, "Victim's original Google linkage must survive the refused attack."

    attacker_rows = (
        await db_session.scalars(
            select(OAuthAccount).where(
                OAuthAccount.provider == OAuthProvider.kakao,
                OAuthAccount.provider_user_id == "kakao-attacker-id-999",
            )
        )
    ).all()
    assert attacker_rows == [], "Attacker's provider_user_id must not be persisted on refusal."


@pytest.mark.asyncio
async def test_brand_new_email_creates_user_and_oauth_account(
    db_session: AsyncSession,
) -> None:
    """Regression: a never-seen email still gets a fresh user + OAuthAccount."""
    service = AuthService(db_session)
    provider_user = {
        "provider_user_id": "kakao-newbie-id-001",
        "email": "newbie@example.com",
        "name": "Newbie",
        "profile_image_url": None,
    }

    user = await service._find_or_create_user(
        provider="kakao",
        provider_user=provider_user,
        request=_oauth_request(),
    )
    assert user.email == "newbie@example.com"

    linked = (await db_session.scalars(select(OAuthAccount).where(OAuthAccount.user_id == user.id))).all()
    assert len(linked) == 1
    assert linked[0].provider == OAuthProvider.kakao
    assert linked[0].provider_user_id == "kakao-newbie-id-001"


@pytest.mark.asyncio
async def test_existing_oauth_account_returns_same_user(
    db_session: AsyncSession,
) -> None:
    """Regression: an already-linked (provider, provider_user_id) returns its user."""
    victim = await _insert_victim(db_session)
    service = AuthService(db_session)

    provider_user = {
        "provider_user_id": "google-victim-sub-123",
        "email": "victim@example.com",
        "name": "Victim",
        "profile_image_url": None,
    }

    user = await service._find_or_create_user(
        provider="google",
        provider_user=provider_user,
        request=_oauth_request(),
    )
    assert user.id == victim.id

    rows = (await db_session.scalars(select(OAuthAccount).where(OAuthAccount.user_id == victim.id))).all()
    assert len(rows) == 1, "Re-logging in via the same provider must not duplicate the OAuthAccount row."
