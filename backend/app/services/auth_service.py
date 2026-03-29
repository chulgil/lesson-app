"""Authentication service – OAuth login, token management."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

import httpx
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.schemas.auth import DevLoginRequest, OAuthRequest, RefreshTokenResponse, TokenResponse
from app.schemas.user import UserResponse


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

    async def dev_login(self, request: DevLoginRequest) -> TokenResponse:
        """Authenticate without OAuth — development environment only.

        Flow:
        1. Find existing user by email, or create a new one.
        2. Set role and auto-create role-specific profile (Teacher / Parent).
        3. Generate access + refresh tokens.
        """
        from app.core.config import settings

        if settings.ENVIRONMENT not in ("development", "beta"):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Dev login is only available in development/beta environment",
            )

        from app.models.user import User, UserRole

        user = await self.db.scalar(
            select(User).where(User.email == request.email)
        )

        role_enum = UserRole(request.role) if request.role else None

        if user is None:
            user = User(
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
        blacklisted = await self.db.scalar(
            select(TokenBlacklist).where(TokenBlacklist.jti == jti)
        ) if jti else None
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
        from datetime import datetime, timedelta, timezone

        from app.core.security import decode_refresh_token
        from app.models.user import TokenBlacklist

        payload = decode_refresh_token(refresh_token)
        jti = payload.get("jti", "") if payload else ""
        expires_at = datetime.now(timezone.utc) + timedelta(days=30)

        blacklist_entry = TokenBlacklist(
            jti=jti,
            user_id=user_id,
            expires_at=expires_at,
        )
        self.db.add(blacklist_entry)
        await self.db.flush()

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

    async def _google_user_info(self, request: OAuthRequest) -> dict[str, Any]:
        """Exchange Google authorization code for user info."""
        from app.core.config import settings

        async with httpx.AsyncClient() as client:
            token_data = {
                "code": request.code,
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
                raise HTTPException(
                    status_code=401,
                    detail=f"Google token exchange failed: {token_resp.text}",
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
                    "code": request.code,
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
        """Validate Apple identity token and extract user info."""
        import jwt

        try:
            payload = jwt.decode(
                request.identity_token,
                options={"verify_signature": False},
            )
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

            existing = await self.db.scalar(
                select(Teacher).where(Teacher.user_id == user.id)
            )
            if not existing:
                teacher = Teacher(user_id=user.id, instruments=[])
                self.db.add(teacher)
                await self.db.flush()

        elif role_enum == UserRole.parent:
            from app.models.parent import Parent

            existing = await self.db.scalar(
                select(Parent).where(Parent.user_id == user.id)
            )
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

        # Check if a user with this email already exists
        user = None
        if provider_user.get("email"):
            user = await self.db.scalar(
                select(User).where(User.email == provider_user["email"])
            )

        if user is None:
            user = User(
                email=provider_user.get("email"),
                name=provider_user.get("name"),
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
