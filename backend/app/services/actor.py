from typing import Any


def actor_type(user: Any) -> str:
    """Return the user's role value as a string ("" if absent).

    Shared across request-event / schedule-confirmation / lesson-request
    services so actor-role derivation stays consistent.
    """
    role = getattr(user, "role", None)
    return getattr(role, "value", role) or ""
