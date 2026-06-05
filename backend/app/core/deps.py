"""Dependency injection utilities for FastAPI routes."""

from __future__ import annotations

import secrets
from collections.abc import Callable
from typing import Annotated, Any

from fastapi import Depends, HTTPException, Query, Request, status
from fastapi.security import APIKeyHeader, OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.security import verify_token
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token", auto_error=False)
internal_api_key_header = APIKeyHeader(name="X-Internal-API-Key", auto_error=False)


# ---------------------------------------------------------------------------
# Authentication helpers
# ---------------------------------------------------------------------------


async def get_current_user(
    token: Annotated[str | None, Depends(oauth2_scheme)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """Extract and validate the current user from the JWT token."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if token is None:
        raise credentials_exception

    try:
        payload = verify_token(token)
        user_id: str | None = payload.get("sub")
        token_type: str | None = payload.get("type")
        if user_id is None or token_type != "access":
            raise credentials_exception
    except Exception:
        raise credentials_exception

    # AC-M2 §7.2: access token revocation 체크. jti 가 TokenBlacklist 에 있으면
    # 컨텍스트 토글로 만료된 이전 토큰 — 즉시 401. jti 없는 레거시 토큰은 통과.
    jti: str | None = payload.get("jti")
    if jti:
        from app.models.user import TokenBlacklist

        revoked = await db.scalar(select(TokenBlacklist).where(TokenBlacklist.jti == jti))
        if revoked is not None:
            raise credentials_exception

    user = await db.scalar(select(User).where(User.id == user_id))
    if user is None:
        raise credentials_exception
    # AC-M2 §7.2: 다중 디바이스 일괄 만료. user.tokens_revoked_at 갱신 후 발급된
    # 토큰만 유효 — iat 가 epoch 이하이면 401. ``<=`` 인 이유: JWT iat 가 초 단위
    # 정수로 truncation 되므로 같은 초 발급 토큰도 epoch 이하로 같이 차단해야 안전.
    # switch_context 는 epoch 을 새 토큰 iat - 1 초로 설정해 새 토큰이 안전하게 통과.
    revoked_at = user.tokens_revoked_at
    token_iat = payload.get("iat")
    if revoked_at is not None and token_iat is not None:
        from datetime import UTC, datetime

        iat_dt = datetime.fromtimestamp(token_iat, tz=UTC)
        epoch_dt = revoked_at if revoked_at.tzinfo else revoked_at.replace(tzinfo=UTC)
        if iat_dt <= epoch_dt:
            raise credentials_exception
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )
    return user


async def get_current_teacher(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Ensure the current user has the 'teacher' role."""
    if user.role is None or user.role.value != "teacher":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Teacher access required",
        )
    return user


async def get_current_student(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Ensure the current user has the 'student' role."""
    if user.role is None or user.role.value != "student":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Student access required",
        )
    return user


async def get_current_parent(
    user: Annotated[User, Depends(get_current_user)],
) -> User:
    """Ensure the current user has the 'parent' role."""
    if user.role is None or user.role.value != "parent":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Parent access required",
        )
    return user


def require_role(*roles: str) -> Callable[..., Any]:
    """Return a dependency that checks user role against allowed roles.

    Usage:
        @router.get("/admin", dependencies=[Depends(require_role("teacher"))])
    """

    async def role_checker(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        if current_user.role is None or current_user.role.value not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role {current_user.role} not authorized. Required: {', '.join(roles)}",
            )
        return current_user

    return role_checker


async def require_phone_verified_teacher(
    teacher_user: Annotated[User, Depends(get_current_teacher)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    """E3 hard gate — block subscription issuance until the teacher's phone is verified.

    Spec: docs/specs/user/phone_verification_policy.md §4.2 / §5.3.
    Frontend intercepts the 409 + ``phone_verification_required`` code and
    routes to the verification flow.

    Returns the verified teacher user so the caller still receives the
    ``current_user`` it would have gotten from ``get_current_teacher``.
    """
    from app.core.exceptions import PhoneVerificationRequiredException
    from app.models.teacher import Teacher

    teacher_row = await db.scalar(select(Teacher).where(Teacher.user_id == teacher_user.id))
    # No teacher profile yet: keep current behaviour and let the downstream
    # service raise a more specific error. The gate is opt-in per route.
    if teacher_row is None:
        return teacher_user
    if not teacher_row.is_phone_verified:
        raise PhoneVerificationRequiredException("수강권 발급에는 전화인증이 필요해요")
    return teacher_user


async def require_internal_api_key(
    api_key: Annotated[str | None, Depends(internal_api_key_header)],
) -> None:
    """Authorize internal automation endpoints with a dedicated API key."""
    configured_key = settings.INTERNAL_API_KEY
    if not configured_key:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Internal API key is not configured",
        )
    if api_key is None or not secrets.compare_digest(api_key, configured_key):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid internal API key",
        )


# ---------------------------------------------------------------------------
# Locale helper
# ---------------------------------------------------------------------------


async def get_locale(request: Request) -> str:
    """Return the resolved locale from middleware (falls back to 'ko')."""
    return getattr(request.state, "locale", "ko")


# ---------------------------------------------------------------------------
# Pagination parameters
# ---------------------------------------------------------------------------


async def get_pagination(
    page: Annotated[int, Query(ge=1)] = 1,
    size: Annotated[int, Query(ge=1, le=100)] = 20,
    per_page: Annotated[int | None, Query(ge=1, le=100)] = None,
) -> dict[str, int]:
    """Return pagination offset/limit dict."""
    if per_page is not None:
        size = per_page
    return {"page": page, "size": size, "offset": (page - 1) * size}


# ---------------------------------------------------------------------------
# Convenience type aliases for Annotated dependencies
# ---------------------------------------------------------------------------

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
CurrentTeacher = Annotated[User, Depends(get_current_teacher)]
VerifiedTeacher = Annotated[User, Depends(require_phone_verified_teacher)]
CurrentStudent = Annotated[User, Depends(get_current_student)]
CurrentParent = Annotated[User, Depends(get_current_parent)]
Pagination = Annotated[dict[str, int], Depends(get_pagination)]
Locale = Annotated[str, Depends(get_locale)]
