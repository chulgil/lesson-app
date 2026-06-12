"""Remote beta scenario 5: Boundary / error-path tests.

- 만료/위변조 JWT → 401
- 권한 위반: 학생이 타인 레슨 완료 시도 → 403/404
- KST 자정 경계 신청 (서버가 UTC 기반으로 날짜를 해석하는지 검증)
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest

from tests.integration_beta.helpers import BetaAccount, BetaClient


def _yesterday() -> str:
    return (datetime.now(UTC).date() - timedelta(days=1)).isoformat()


def _tomorrow() -> str:
    return (datetime.now(UTC).date() + timedelta(days=1)).isoformat()


@pytest.mark.asyncio
async def test_expired_jwt_returns_401(beta_client: BetaClient) -> None:
    """A tampered/expired JWT must be rejected with 401."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    # Craft a structurally valid but unsigned JWT (header.payload.badsig).
    fake_token = (
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmYWtlLXVzZXIiLCJleHAiOjE3MDAwMDAwMDB9.invalidsignature"
    )
    response = await beta_client.raw_get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {fake_token}"},
    )
    assert response.status_code == 401, (
        f"expired/tampered JWT: expected 401, got {response.status_code} — body: {response.text[:200]}"
    )


@pytest.mark.asyncio
async def test_missing_auth_header_returns_401(beta_client: BetaClient) -> None:
    """A request without Authorization header must return 401."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    response = await beta_client.raw_get("/api/v1/auth/me", headers={})
    assert response.status_code == 401, f"no auth header: expected 401, got {response.status_code}"


@pytest.mark.asyncio
async def test_student_cannot_complete_other_students_lesson(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Student B must not be able to mark Student A's lesson as completed (403 or 404)."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    student_b_account = BetaAccount(
        email=f"beta-boundary-b-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(beta_teacher_account)
    student_b_tokens = await beta_client.dev_login(student_b_account, name=f"Boundary B {suffix}")

    # Teacher creates a lesson for a fresh student A (no user link — teacher-only student).
    student_a = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"Boundary A {suffix}",
        instrument="violin",
        level="beginner",
        status="active",
        lesson_duration=60,
    )
    student_a_id = student_a["id"]

    lesson = await beta_client.create_lesson(
        teacher_tokens.access_token,
        student_id=student_a_id,
        date=_yesterday(),
        start_time="10:00",
        duration=60,
    )
    lesson_id = lesson["id"]

    # Student B attempts to complete Student A's lesson — must be denied.
    response = await beta_client.update_lesson_status_expect(
        student_b_tokens.access_token,
        lesson_id,
        status="completed",
        expected_status=403,
    )
    assert response.status_code in (403, 404), (
        f"student B completing A's lesson: expected 403/404, got {response.status_code} — body: {response.text[:200]}"
    )


@pytest.mark.asyncio
async def test_lesson_request_date_is_utc_agnostic(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Lesson request with a date near KST midnight must be accepted by the server.

    KST = UTC+9.  23:00 KST on date D == 14:00 UTC, which is still date D in UTC.
    The server operates in UTC; this test submits a request for tomorrow (UTC) and
    verifies the server stores the correct preferred_day without a date-shift error.
    """
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server unavailable: {health.status_code}")

    suffix = uuid4().hex[:8]
    student_account = BetaAccount(
        email=f"beta-kst-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(beta_teacher_account)
    student_tokens = await beta_client.dev_login(student_account, name=f"KST Student {suffix}")

    teacher_id = teacher_tokens.user["id"]

    # Tomorrow's weekday as preferred_day — mimics a KST near-midnight submission.
    tomorrow = datetime.now(UTC).date() + timedelta(days=1)
    preferred_day = tomorrow.weekday()  # 0=Mon … 6=Sun

    request = await beta_client.create_lesson_request(
        student_tokens.access_token,
        teacher_id=teacher_id,
        request_type="trial",
        instrument="violin",
        goal="hobby",
        experience_level="beginner",
        preferred_day=preferred_day,
        preferred_time="23:00",  # 23:00 KST boundary time
        preferred_duration=60,
        message=f"KST boundary smoke {suffix}",
    )
    request_id = request["id"]

    try:
        assert request["status"] in ("pending", "submitted"), (
            f"KST boundary request: expected pending/submitted, got {request['status']!r}"
        )
        # Server must echo back the same preferred_day without a ±1 day shift.
        assert request.get("preferred_day") == preferred_day, (
            f"KST boundary: preferred_day mismatch — sent {preferred_day}, got {request.get('preferred_day')}"
        )
    finally:
        try:
            await beta_client.delete_lesson_request(teacher_tokens.access_token, request_id)
        except Exception:  # noqa: BLE001
            pass
