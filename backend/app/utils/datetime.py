"""Datetime utility functions."""
from datetime import datetime, timezone
from zoneinfo import ZoneInfo


def utc_now() -> datetime:
    """Get current UTC datetime."""
    return datetime.now(timezone.utc)


def to_user_timezone(dt: datetime, tz_name: str = "Asia/Seoul") -> datetime:
    """Convert UTC datetime to user timezone."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(ZoneInfo(tz_name))


def to_utc(dt: datetime, from_tz: str = "Asia/Seoul") -> datetime:
    """Convert local datetime to UTC."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=ZoneInfo(from_tz))
    return dt.astimezone(timezone.utc)
