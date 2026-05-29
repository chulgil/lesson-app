"""Contract tests that verify backend exposes frontend-required remote API routes."""

from collections.abc import Iterable

import pytest


def _assert_path_methods(routes: dict, path: str, methods: Iterable[str]) -> None:
    assert path in routes, f"Missing route: {path}"
    actual_methods = {method.lower() for method in routes[path].keys()}
    for method in methods:
        assert method.lower() in actual_methods, f"Missing method {method.upper()} on {path}"


@pytest.mark.asyncio
async def test_openapi_exposes_frontend_remote_contract_routes(client) -> None:
    """Ensure critical frontend-relevant routes remain contract-available."""
    response = await client.get("/openapi.json")
    assert response.status_code == 200
    routes = response.json()["paths"]

    expected_routes = {
        "/api/v1/lessons/bulk-cancel": {"post"},
        "/api/v1/lessons/bulk-cancel/preview": {"post"},
        "/api/v1/lessons/{lesson_id}/archive": {"patch"},
        "/api/v1/lessons/{lesson_id}/unarchive": {"patch"},
        "/api/v1/students/{student_id}/archive": {"patch"},
        "/api/v1/students/{student_id}/unarchive": {"patch"},
        "/api/v1/notifications/broadcast": {"post"},
        "/api/v1/announcements": {"post", "get"},
        "/api/v1/announcements/day-offs": {"get"},
        "/api/v1/notifications/{notification_id}/read": {"patch"},
        "/api/v1/notifications/read-all": {"patch"},
        "/api/v1/notifications/unread-count": {"get"},
        "/api/v1/groups/bookings": {"get", "post"},
        "/api/v1/groups/bookings/{booking_id}": {"get"},
        "/api/v1/groups/bookings/{booking_id}/cancel": {"patch"},
        "/api/v1/groups/bookings/{booking_id}/attendance": {"patch"},
        "/api/v1/groups/bookings/{booking_id}/deduct": {"patch"},
        "/api/v1/groups/bookings/promote": {"post"},
        "/api/v1/groups/bookings/auto-cancel-waitlist": {"post"},
        "/api/v1/groups/bookings/batch-attendance": {"post"},
        "/api/v1/groups/schedules/{schedule_id}/bookings": {"get"},
        "/api/v1/groups/{group_class_id}/schedules": {"get"},
        "/api/v1/schedule/confirmation-cards": {"get", "post"},
        "/api/v1/schedule/confirmation-cards/by-subscription/{subscription_id}": {"get"},
        "/api/v1/schedule/confirmation-cards/{card_id}": {"get"},
        "/api/v1/schedule/confirmation-cards/{card_id}/status": {"patch"},
        "/api/v1/schedule/confirmation-cards/{card_id}/confirm": {"patch"},
        "/api/v1/schedule/confirmation-cards/dismiss-all": {"post"},
        "/api/v1/parents/{parent_id}/child-profiles": {"get"},
        "/api/v1/parents/child-profiles": {"post"},
        "/api/v1/parents/child-profiles/{child_id}": {"get", "put", "delete"},
        "/api/v1/parents/child-profiles/{child_id}/teacher": {"post", "delete"},
        "/api/v1/practice/pieces": {"get", "post"},
        "/api/v1/practice/pieces/{piece_id}": {"get", "put", "delete"},
        "/api/v1/practice/pieces/search": {"get"},
        "/api/v1/practice/repertoires": {"get", "post"},
        "/api/v1/practice/repertoires/{repertoire_id}/archive": {"patch"},
        "/api/v1/practice/repertoires/{repertoire_id}/restore": {"patch"},
        "/api/v1/practice/repertoires/{repertoire_id}/permanent": {"delete"},
        "/api/v1/practice/sections/{section_id}/notes": {"get", "post"},
        "/api/v1/practice/notes/{note_id}": {"put", "delete"},
        "/api/v1/parents/me/children": {"get"},
        "/api/v1/subscriptions/{subscription_id}/events": {"get", "post"},
        "/api/v1/subscriptions/schedule-change-events/pending": {"get"},
        "/api/v1/subscriptions/{subscription_id}/use-reschedule": {"patch"},
    }

    for path, methods in expected_routes.items():
        _assert_path_methods(routes, path, methods)


@pytest.mark.asyncio
async def test_openapi_does_not_expose_app_managed_payment_endpoints(client) -> None:
    """Manual tuition-deposit model does not include app-managed payment routes."""
    response = await client.get("/openapi.json")
    assert response.status_code == 200
    routes = response.json()["paths"]

    prohibited_routes = {
        "/api/v1/payments",
        "/api/v1/payments/{payment_id}",
        "/api/v1/payments/summary",
        "/api/v1/payments/overdue",
        "/api/v1/payments/tuition-settings/{student_id}",
        "/api/v1/payments/tuition-settings/{student_id}/",
    }
    for path in prohibited_routes:
        assert path not in routes, f"Unexpected app-managed payment route should stay absent: {path}"
