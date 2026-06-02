"""Authentication service – OAuth login, token management."""

from __future__ import annotations

import logging
from datetime import UTC, datetime
from typing import Any

import httpx
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.auth import DevLoginRequest, OAuthRequest, RefreshTokenResponse, TokenResponse
from app.schemas.user import UserResponse

logger = logging.getLogger(__name__)


class AuthService:
    """Handle OAuth authentication and JWT token lifecycle."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def oauth_login(self, provider: str, request: OAuthRequest) -> TokenResponse:
        """Authenticate via OAuth provider and return JWT tokens.

        Flow:
        1. Exchange code / identity_token with the provider to get user info.
        2. Find or create User + OAuthAccount.
        3. Generate access + refresh tokens.
        """
        if provider not in ("google", "kakao", "apple"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported OAuth provider: {provider}",
            )
        self._assert_oauth_credentials(provider, request)

        # Fetch user info from the provider
        provider_user = await self._get_provider_user(provider, request)

        # Find or create local user
        user = await self._find_or_create_user(provider, provider_user, request)

        # Generate tokens
        from app.core.security import create_access_token, create_refresh_token

        access_token = create_access_token(data={"sub": user.id, "role": getattr(user.role, "value", None)})
        refresh_token = create_refresh_token(data={"sub": user.id})

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=UserResponse.model_validate(user),
        )

    async def dev_login(
        self,
        request: DevLoginRequest,
        *,
        internal_api_key: str | None = None,
    ) -> TokenResponse:
        """Authenticate without OAuth — development env, or beta with internal key.

        Environment gate:
          - development: always allowed (key ignored)
          - beta: allowed only if X-Internal-API-Key matches settings.INTERNAL_API_KEY
                  (used by the beta integration-test harness)
          - all other (production, staging, unknown): always 403

        Flow:
        1. Find existing user by email, or create a new one.
        2. Set role and auto-create role-specific profile (Teacher / Parent).
        3. Generate access + refresh tokens.
        """
        import secrets as _secrets

        from app.core.config import settings

        env = settings.ENVIRONMENT
        if env == "development":
            pass
        elif env == "beta":
            configured = settings.INTERNAL_API_KEY
            if not configured or internal_api_key is None or not _secrets.compare_digest(internal_api_key, configured):
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Dev login on beta requires a valid X-Internal-API-Key header",
                )
        else:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Dev login is only available in development environment",
            )

        from app.models.user import User, UserRole

        # Check if this email has a predefined seed ID
        try:
            from scripts.seeds.ids import SEED_ACCOUNTS

            seed_info = SEED_ACCOUNTS.get(request.email)
        except ImportError:
            seed_info = None

        user = await self.db.scalar(select(User).where(User.email == request.email))

        role_enum = UserRole(request.role) if request.role else None

        if user is None:
            user = User(
                id=seed_info["user_id"] if seed_info else None,
                email=request.email,
                name=request.name or request.email.split("@")[0],
                role=role_enum,
                onboarding_completed=True,
            )
            self.db.add(user)
            await self.db.flush()
        else:
            # Update role if changed
            if role_enum and user.role != role_enum:
                user.role = role_enum
            # Dev login always marks onboarding as completed
            if not user.onboarding_completed:
                user.onboarding_completed = True
            await self.db.flush()

        # Auto-create role-specific profile
        await self._ensure_role_profile(user, role_enum)

        from app.core.security import create_access_token, create_refresh_token

        access_token = create_access_token(
            data={"sub": user.id, "role": role_enum.value if role_enum else None},
        )
        refresh_token = create_refresh_token(data={"sub": user.id})

        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            user=UserResponse.model_validate(user),
        )

    async def refresh_token(self, refresh_token: str) -> RefreshTokenResponse:
        """Validate a refresh token and issue a new access token."""
        from app.core.security import create_access_token, decode_refresh_token

        payload = decode_refresh_token(refresh_token)
        if payload is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired refresh token",
            )

        # Check blacklist by jti
        from app.models.user import TokenBlacklist

        jti = payload.get("jti", "")
        blacklisted = await self.db.scalar(select(TokenBlacklist).where(TokenBlacklist.jti == jti)) if jti else None
        if blacklisted:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has been revoked",
            )

        access_token = create_access_token(data={"sub": payload["sub"], "role": payload.get("role")})
        return RefreshTokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
        )

    async def logout(self, user_id: str, refresh_token: str) -> None:
        """Blacklist the given refresh token."""
        from datetime import timedelta

        from app.core.security import decode_refresh_token
        from app.models.user import TokenBlacklist

        payload = decode_refresh_token(refresh_token)
        jti = payload.get("jti", "") if payload else ""
        expires_at = datetime.now(UTC) + timedelta(days=30)

        blacklist_entry = TokenBlacklist(
            jti=jti,
            user_id=user_id,
            expires_at=expires_at,
        )
        self.db.add(blacklist_entry)
        await self.db.flush()

    async def update_new_user_role(self, user: Any, role: str) -> Any:
        """Set role for a newly registered user and create the matching profile."""
        from app.models.user import UserRole

        if user.role is not None and user.onboarding_completed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Role is already set. Contact support to change it.",
            )

        role_enum = UserRole(role)
        user.role = role_enum
        self.db.add(user)
        await self._ensure_role_profile(user, role_enum)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def accept_terms(self, user: Any, marketing_consent: bool) -> Any:
        """#430 G1 B2 — 약관 동의 영속 저장.

        본 메서드 호출 자체가 필수 묶음(서비스 이용약관 + 개인정보 처리방침)
        동의를 의미한다. 마케팅 정보 수신은 정보통신망법 제50조에 따라 별도
        시각으로 기록된다 (false 일 때는 None 유지).

        재호출 시 마케팅 동의만 갱신되고 terms_accepted_at 은 최초 동의
        시각을 유지한다 (감사 추적성).
        """
        from datetime import datetime

        now = datetime.now(UTC)
        if user.terms_accepted_at is None:
            user.terms_accepted_at = now
        if marketing_consent:
            user.marketing_consent_at = now
        else:
            user.marketing_consent_at = None
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    # ------------------------------------------------------------------
    # Provider-specific user info fetching
    # ------------------------------------------------------------------

    async def _get_provider_user(self, provider: str, request: OAuthRequest) -> dict[str, Any]:
        """Exchange OAuth credentials for user profile from the provider."""
        if provider == "google":
            return await self._google_user_info(request)
        elif provider == "kakao":
            return await self._kakao_user_info(request)
        elif provider == "apple":
            return await self._apple_user_info(request)
        raise HTTPException(status_code=400, detail="Unknown provider")

    def _assert_oauth_credentials(self, provider: str, request: OAuthRequest) -> None:
        """Reject malformed OAuth requests before external provider calls."""
        if provider in ("google", "kakao") and not (request.code or request.authorization_code):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="authorization code is required")
        if provider == "apple" and not request.identity_token:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="identity_token is required")

    def _authorization_code(self, request: OAuthRequest) -> str:
        code = request.code or request.authorization_code
        if code is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="authorization code is required")
        return code

    async def _google_user_info(self, request: OAuthRequest) -> dict[str, Any]:
        """Exchange Google authorization code for user info."""
        from app.core.config import settings

        async with httpx.AsyncClient() as client:
            token_data = {
                "code": self._authorization_code(request),
                "client_id": settings.GOOGLE_CLIENT_ID,
                "client_secret": settings.GOOGLE_CLIENT_SECRET,
                "grant_type": "authorization_code",
            }
            # Mobile apps (serverAuthCode) don't use redirect_uri;
            # Web apps require it. Only include if explicitly provided.
            if request.redirect_uri:
                token_data["redirect_uri"] = request.redirect_uri

            token_resp = await client.post(
                "https://oauth2.googleapis.com/token",
                data=token_data,
            )
            if token_resp.status_code != 200:
                # Log upstream detail server-side only; never echo Google's
                # error body to the caller — it can contain trace IDs and
                # echoed grant material.
                logger.warning(
                    "Google token exchange failed: status=%s body=%s",
                    token_resp.status_code,
                    token_resp.text,
                )
                raise HTTPException(
                    status_code=401,
                    detail="Google token exchange failed",
                )

            tokens = token_resp.json()

            user_resp = await client.get(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                headers={"Authorization": f"Bearer {tokens['access_token']}"},
            )
            if user_resp.status_code != 200:
                raise HTTPException(status_code=401, detail="Failed to fetch Google user info")

            data = user_resp.json()
            return {
                "provider_user_id": data["id"],
                "email": data.get("email"),
                "name": data.get("name"),
                "profile_image_url": data.get("picture"),
            }

    async def _kakao_user_info(self, request: OAuthRequest) -> dict[str, Any]:
        """Exchange Kakao authorization code for user info."""
        from app.core.config import settings

        async with httpx.AsyncClient() as client:
            token_resp = await client.post(
                "https://kauth.kakao.com/oauth/token",
                data={
                    "code": self._authorization_code(request),
                    "client_id": settings.KAKAO_CLIENT_ID,
                    "client_secret": settings.KAKAO_CLIENT_SECRET,
                    "redirect_uri": request.redirect_uri or "",
                    "grant_type": "authorization_code",
                },
            )
            if token_resp.status_code != 200:
                raise HTTPException(status_code=401, detail="Kakao token exchange failed")

            tokens = token_resp.json()

            user_resp = await client.get(
                "https://kapi.kakao.com/v2/user/me",
                headers={"Authorization": f"Bearer {tokens['access_token']}"},
            )
            if user_resp.status_code != 200:
                raise HTTPException(status_code=401, detail="Failed to fetch Kakao user info")

            data = user_resp.json()
            account = data.get("kakao_account", {})
            profile = account.get("profile", {})
            return {
                "provider_user_id": str(data["id"]),
                "email": account.get("email"),
                "name": profile.get("nickname"),
                "profile_image_url": profile.get("profile_image_url"),
            }

    async def _apple_user_info(self, request: OAuthRequest) -> dict[str, Any]:
        """Validate Apple identity token and extract user info.

        Uses JWKS verification when APPLE_CLIENT_ID is configured,
        falls back to unverified decode for development.
        """
        from app.core.config import settings

        payload: dict[str, Any]

        if not request.identity_token:
            raise HTTPException(status_code=400, detail="identity_token is required for Apple login")

        if not settings.APPLE_CLIENT_ID:
            raise HTTPException(status_code=401, detail="Apple login is not configured")

        from app.core.security import verify_apple_identity_token

        try:
            verified = await verify_apple_identity_token(request.identity_token)
            payload = {"sub": verified["id"], "email": verified.get("email")}
        except Exception:
            raise HTTPException(status_code=401, detail="Invalid Apple identity token")

        user_data = request.user or {}
        name_data = user_data.get("name", {})
        full_name = None
        if name_data:
            first = name_data.get("firstName", "")
            last = name_data.get("lastName", "")
            full_name = f"{last}{first}".strip() or None

        return {
            "provider_user_id": payload.get("sub", ""),
            "email": payload.get("email") or user_data.get("email"),
            "name": full_name,
            "profile_image_url": None,
        }

    # ------------------------------------------------------------------
    # Role profile helpers
    # ------------------------------------------------------------------

    async def _ensure_role_profile(self, user: Any, role_enum: Any) -> None:
        """Create role-specific profile if it doesn't exist yet."""
        if role_enum is None:
            return

        from app.models.user import UserRole

        if role_enum == UserRole.teacher:
            from app.models.teacher import Teacher

            existing = await self.db.scalar(select(Teacher).where(Teacher.user_id == user.id))
            if not existing:
                teacher = Teacher(user_id=user.id, instruments=[])
                self.db.add(teacher)
                await self.db.flush()

        elif role_enum == UserRole.parent:
            from app.models.parent import Parent

            existing = await self.db.scalar(select(Parent).where(Parent.user_id == user.id))
            if not existing:
                parent = Parent(
                    user_id=user.id,
                    name=user.name,
                    email=user.email,
                )
                self.db.add(parent)
                await self.db.flush()

    # ------------------------------------------------------------------
    # Find or create user
    # ------------------------------------------------------------------

    async def _find_or_create_user(
        self,
        provider: str,
        provider_user: dict[str, Any],
        request: OAuthRequest,
    ) -> Any:
        """Find an existing user by OAuth account or create a new one."""
        from app.models.user import OAuthAccount, User

        # Check if OAuth account already exists
        oauth_account = await self.db.scalar(
            select(OAuthAccount).where(
                OAuthAccount.provider == provider,
                OAuthAccount.provider_user_id == provider_user["provider_user_id"],
            )
        )

        if oauth_account:
            user = await self.db.get(User, oauth_account.user_id)
            if user is None:
                raise HTTPException(status_code=404, detail="User not found")
            return user

        # Refuse silent cross-provider link when the provider-returned email
        # already belongs to another user. Providers do not uniformly prove
        # email ownership at signup, so auto-linking by email allows takeover
        # of the existing account by an attacker who registers the victim's
        # email on a different provider. The caller must use an explicit
        # account-linking flow instead. (#409)
        if provider_user.get("email"):
            existing_by_email = await self.db.scalar(select(User).where(User.email == provider_user["email"]))
            if existing_by_email is not None:
                raise HTTPException(
                    status_code=409,
                    detail=(
                        "An account with this email already exists. "
                        "Sign in with your original provider to link this account."
                    ),
                )

        user = User(
            email=provider_user.get("email"),
            name=provider_user.get("name") or provider_user.get("email") or provider_user["provider_user_id"],
            profile_image_url=provider_user.get("profile_image_url"),
            locale=request.locale or "ko",
            country=request.country or "KR",
            timezone=request.timezone or "Asia/Seoul",
        )
        self.db.add(user)
        await self.db.flush()

        new_oauth = OAuthAccount(
            user_id=user.id,
            provider=provider,
            provider_user_id=provider_user["provider_user_id"],
            provider_email=provider_user.get("email"),
        )
        self.db.add(new_oauth)
        await self.db.flush()

        return user
