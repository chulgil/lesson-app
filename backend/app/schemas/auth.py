"""Authentication-related schemas."""


from pydantic import BaseModel, ConfigDict

from app.schemas.user import UserResponse


class OAuthRequest(BaseModel):
    """OAuth login request – supports Google, Kakao, and Apple."""

    provider: str
    code: str | None = None
    authorization_code: str | None = None
    identity_token: str | None = None
    redirect_uri: str | None = None
    user: dict | None = None

    # Optional locale info from the client device
    locale: str | None = None
    country: str | None = None
    timezone: str | None = None


class TokenResponse(BaseModel):
    """JWT token pair returned after successful authentication."""

    model_config = ConfigDict(from_attributes=True)

    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    user: UserResponse


class RefreshTokenRequest(BaseModel):
    """Request body for refreshing an access token."""

    refresh_token: str


class RefreshTokenResponse(BaseModel):
    """Response for a token refresh – only a new access token."""

    access_token: str
    token_type: str = "bearer"


class DevLoginRequest(BaseModel):
    """Dev-only login request — bypasses OAuth for local development."""

    email: str
    role: str = "teacher"
    name: str | None = None


class LogoutRequest(BaseModel):
    """Request body for logout."""

    refresh_token: str
