"""Reusable assertion helpers for scenario tests."""

from __future__ import annotations


def assert_subscription_remaining(sub: dict, expected: int) -> None:
    """Assert a subscription has the expected remaining lessons."""
    actual = sub.get("remaining_lessons")
    assert actual == expected, (
        f"Expected {expected} remaining lessons, got {actual}. "
        f"(total={sub.get('total_lessons')}, used={sub.get('used_lessons')})"
    )


def assert_status(data: dict, expected: str) -> None:
    """Assert a resource has the expected status."""
    actual = data.get("status")
    assert actual == expected, f"Expected status '{expected}', got '{actual}'"


def assert_total(data: dict, expected: int) -> None:
    """Assert a paginated response has the expected total count."""
    actual = data.get("total")
    assert actual == expected, f"Expected total {expected}, got {actual}"


def assert_list_length(data: list | dict, expected: int) -> None:
    """Assert a list or paginated items has the expected length."""
    if isinstance(data, dict):
        items = data.get("items", [])
    else:
        items = data
    assert len(items) == expected, f"Expected {expected} items, got {len(items)}"
