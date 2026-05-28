"""Public landing page for invite codes."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.responses import HTMLResponse
from jinja2 import Environment, FileSystemLoader
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.models.invite import Invite, InviteStatus
from app.models.teacher import Teacher

router = APIRouter()


def get_templates_dir() -> str:
    """Get templates directory path."""
    import pathlib

    return str(pathlib.Path(__file__).parent.parent.parent / "templates")


def get_jinja_env() -> Environment:
    """Create Jinja2 environment."""
    templates_dir = get_templates_dir()
    return Environment(loader=FileSystemLoader(templates_dir), autoescape=True)


@router.get(
    "/invite/{code}/landing",
    response_class=HTMLResponse,
    status_code=status.HTTP_200_OK,
    summary="Get invite landing page",
    tags=["invites-public"],
)
async def get_invite_landing(
    code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> str:
    """
    Render HTML landing page for an invite code.

    Public endpoint (no authentication required).
    Shows teacher name, instrument, and app installation CTA.

    Args:
        code: Invite code (case-insensitive)
        db: Database session

    Returns:
        HTML page or error page

    Status codes:
        200: Valid invite code
        404: Invalid or not found code
        410: Expired invite code
    """
    # Query invite by code
    invite = await db.scalar(select(Invite).where(Invite.invite_code == code.upper()))

    if invite is None:
        return render_error_page(db, "invalid")

    # Check if invite is expired
    now = datetime.now(UTC)
    if invite.expires_at < now:
        return render_error_page(db, "expired", status_code=410)

    # Check if invite is revoked or used
    if invite.status == InviteStatus.revoked:
        return render_error_page(db, "revoked", status_code=410)

    if invite.status == InviteStatus.expired:
        return render_error_page(db, "expired", status_code=410)

    # Fetch teacher info
    teacher_name = invite.creator_name or "선생님"
    instrument = None

    if invite.creator_id:
        teacher = await db.scalar(select(Teacher).where(Teacher.user_id == invite.creator_id))
        if teacher and teacher.instruments:
            # instruments is JSON, typically a list or dict
            if isinstance(teacher.instruments, list) and len(teacher.instruments) > 0:
                instrument = teacher.instruments[0]
            elif isinstance(teacher.instruments, dict):
                # Handle dict format if applicable
                instruments_list = list(teacher.instruments.values())
                if instruments_list:
                    instrument = instruments_list[0]

    # Render landing page
    env = get_jinja_env()
    template = env.get_template("landing.html")
    html_content = template.render(
        teacher_name=teacher_name,
        code=code.upper(),
        instrument=instrument or "음악",
    )

    return html_content


def render_error_page(
    db: AsyncSession | None = None,
    error_reason: str = "invalid",
    status_code: int = 404,
) -> str:
    """
    Render error landing page.

    Args:
        db: Database session (not used currently)
        error_reason: Reason for error ('invalid', 'expired', 'revoked')
        status_code: HTTP status code

    Returns:
        HTML error page
    """
    env = get_jinja_env()
    template = env.get_template("landing_error.html")
    html_content = template.render(error_reason=error_reason)

    return html_content
