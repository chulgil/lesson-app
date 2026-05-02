import uuid
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx
import jwt
from jwt import PyJWKClient

from app.core.config import settings

# Google OAuth endpoints
GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_USERINFO_URL = "https://www.googleapis.com/oauth2/v2/userinfo"

# Kakao OAuth endpoints
KAKAO_TOKEN_URL = "https://kauth.kakao.com/oauth/token"
KAKAO_USERINFO_URL = "https://kapi.kakao.com/v2/user/me"

# Apple JWKS endpoint
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"

_INSECURE_JWT_SECRETS = {
    "change-me-in-production",
    "dev-only-insecure-jwt-secret-change-before-production",
}


def _assert_safe_jwt_secret() -> None:
    """Prevent production-like environments from signing tokens with weak defaults."""
    if settings.ENVIRONMENT not in {"production", "beta"}:
        return
    if settings.JWT_SECRET_KEY in _INSECURE_JWT_SECRETS or len(settings.JWT_SECRET_KEY) < 32:
        raise RuntimeError("JWT_SECRET_KEY must be set to a strong secret in production-like environments")


def create_access_token(data: dict[str, Any]) -> str:
    """Create a JWT access token with expiration."""
    _assert_safe_jwt_secret()
    to_encode = data.copy()
    expire = datetime.now(UTC) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(UTC),
        "type": "access",
    })
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def create_refresh_token(data: dict[str, Any]) -> str:
    """Create a JWT refresh token with 30-day expiration and unique jti."""
    _assert_safe_jwt_secret()
    to_encode = data.copy()
    expire = datetime.now(UTC) + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({
        "exp": expire,
        "iat": datetime.now(UTC),
        "type": "refresh",
        "jti": str(uuid.uuid4()),
    })
    return jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def verify_token(token: str) -> dict[str, Any]:
    """Decode and verify a JWT token. Raises jwt.PyJWTError on failure."""
    return jwt.decode(
        token,
        settings.JWT_SECRET_KEY,
        algorithms=[settings.JWT_ALGORITHM],
    )


def decode_access_token(token: str) -> dict[str, Any] | None:
    """Decode and validate a JWT access token. Returns payload or None."""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != "access":
            return None
        return payload
    except jwt.PyJWTError:
        return None


def decode_refresh_token(token: str) -> dict[str, Any] | None:
    """Decode and validate a JWT refresh token. Returns payload or None."""
    try:
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != "refresh":
            return None
        return payload
    except jwt.PyJWTError:
        return None


async def verify_google_token(code: str, redirect_uri: str) -> dict[str, Any]:
    """Exchange Google authorization code for user info.

    Returns dict with keys: id, email, name, picture.
    """
    async with httpx.AsyncClient() as client:
        # Exchange authorization code for access token
        token_response = await client.post(
            GOOGLE_TOKEN_URL,
            data={
                "code": code,
                "client_id": settings.GOOGLE_CLIENT_ID,
                "client_secret": settings.GOOGLE_CLIENT_SECRET,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            },
        )
        token_response.raise_for_status()
        token_data = token_response.json()

        # Fetch user info
        userinfo_response = await client.get(
            GOOGLE_USERINFO_URL,
            headers={"Authorization": f"Bearer {token_data['access_token']}"},
        )
        userinfo_response.raise_for_status()
        userinfo = userinfo_response.json()

    return {
        "id": userinfo["id"],
        "email": userinfo.get("email"),
        "name": userinfo.get("name"),
        "picture": userinfo.get("picture"),
    }


async def verify_kakao_token(code: str, redirect_uri: str) -> dict[str, Any]:
    """Exchange Kakao authorization code for user info.

    Returns dict with keys: id, email, name, picture.
    """
    async with httpx.AsyncClient() as client:
        # Exchange authorization code for access token
        token_response = await client.post(
            KAKAO_TOKEN_URL,
            data={
                "code": code,
                "client_id": settings.KAKAO_CLIENT_ID,
                "client_secret": settings.KAKAO_CLIENT_SECRET,
                "redirect_uri": redirect_uri,
                "grant_type": "authorization_code",
            },
        )
        token_response.raise_for_status()
        token_data = token_response.json()

        # Fetch user info
        userinfo_response = await client.get(
            KAKAO_USERINFO_URL,
            headers={"Authorization": f"Bearer {token_data['access_token']}"},
        )
        userinfo_response.raise_for_status()
        userinfo = userinfo_response.json()

    kakao_account = userinfo.get("kakao_account", {})
    profile = kakao_account.get("profile", {})

    return {
        "id": str(userinfo["id"]),
        "email": kakao_account.get("email"),
        "name": profile.get("nickname"),
        "picture": profile.get("profile_image_url"),
    }


async def verify_apple_identity_token(identity_token: str) -> dict[str, Any]:
    """Verify Apple identity_token JWT using Apple's public keys (JWKS).

    Returns dict with keys: id, email, is_private_email.
    """
    jwks_client = PyJWKClient(APPLE_JWKS_URL)
    signing_key = jwks_client.get_signing_key_from_jwt(identity_token)

    payload = jwt.decode(
        identity_token,
        signing_key.key,
        algorithms=["RS256"],
        audience=settings.APPLE_CLIENT_ID,
        issuer="https://appleid.apple.com",
    )

    return {
        "id": payload["sub"],
        "email": payload.get("email"),
        "is_private_email": payload.get("is_private_email") == "true",
    }
