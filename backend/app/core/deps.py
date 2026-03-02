"""Dependency injection utilities for FastAPI routes."""

from __future__ import annotations

from collections.abc import AsyncGenerator, Callable
from typing import Annotated, Any

from fastapi import Depends, HTTPException, Query, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.security import verify_token
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token", auto_error=False)


# ---------------------------------------------------------------------------
# Database session
# ---------------------------------------------------------------------------


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Yield an async database session with automatic commit/rollback."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise


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

    user = await db.scalar(select(User).where(User.id == user_id))
    if user is None:
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
) -> dict[str, int]:
    """Return pagination offset/limit dict."""
    return {"page": page, "size": size, "offset": (page - 1) * size}


# ---------------------------------------------------------------------------
# Convenience type aliases for Annotated dependencies
# ---------------------------------------------------------------------------

DbSession = Annotated[AsyncSession, Depends(get_db)]
CurrentUser = Annotated[User, Depends(get_current_user)]
CurrentTeacher = Annotated[User, Depends(get_current_teacher)]
CurrentParent = Annotated[User, Depends(get_current_parent)]
Pagination = Annotated[dict[str, int], Depends(get_pagination)]
Locale = Annotated[str, Depends(get_locale)]
