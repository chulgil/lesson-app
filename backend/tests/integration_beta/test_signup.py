"""Remote beta signup/authentication smoke scenario."""

from uuid import uuid4

import pytest

from tests.integration_beta.helpers import BetaAccount, BetaClient


@pytest.mark.asyncio
async def test_seed_teacher_dev_login_round_trips_to_me(
    beta_client: BetaClient,
    beta_teacher_account: BetaAccount,
) -> None:
    """Beta gate allows seed teacher login, then the token authenticates /auth/me."""
    health = await beta_client.health()
    if health.status_code >= 500:
        pytest.skip(f"beta server is unavailable: status={health.status_code}")
    assert health.status_code == 200

    tokens = await beta_client.dev_login(beta_teacher_account)
    assert tokens.user["id"] == beta_teacher_account.expected_user_id
    assert tokens.user["role"] == beta_teacher_account.role
    assert tokens.refresh_token

    me = await beta_client.get_me(tokens.access_token)
    assert me["id"] == beta_teacher_account.expected_user_id
    assert me["email"] == beta_teacher_account.email
    assert me["role"] == beta_teacher_account.role


@pytest.mark.asyncio
async def test_teacher_signup_can_register_student_and_list_roster(
    beta_client: BetaClient,
) -> None:
    """Beta deploy must support signup-to-student-registration used by home onboarding."""
    suffix = uuid4().hex[:10]
    teacher = BetaAccount(
        email=f"beta-roster-teacher-{suffix}@example.com",
        role="teacher",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(teacher, name=f"Beta Roster Teacher {suffix}")
    created = await beta_client.create_student(
        teacher_tokens.access_token,
        name=f"Beta Roster Student {suffix}",
        instrument="piano",
        level="beginner",
        status="active",
        lesson_duration=60,
    )

    assert created["name"] == f"Beta Roster Student {suffix}"
    assert created["teacher_id"]

    students = await beta_client.get_students(teacher_tokens.access_token)
    assert any(item["id"] == created["id"] for item in students["items"])

    lesson_class = await beta_client.create_lesson_class(
        teacher_tokens.access_token,
        name=f"Beta Roster Class {suffix}",
        type="private",
    )
    membership = await beta_client.create_membership(
        teacher_tokens.access_token,
        lesson_class["id"],
        student_id=created["id"],
        instrument="piano",
        status="active",
        lesson_duration=60,
        travel_time_minutes=20,
    )
    assert membership["travel_time_minutes"] == 20

    memberships = await beta_client.get_memberships(
        teacher_tokens.access_token,
        student_id=created["id"],
    )
    assert any(
        item["id"] == membership["id"] and item["travel_time_minutes"] == 20
        for item in memberships
    )


@pytest.mark.asyncio
async def test_student_invite_code_signup_reaches_pending_then_connection(
    beta_client: BetaClient,
) -> None:
    """Beta deploy must support the frontend invite-code onboarding contract."""
    suffix = uuid4().hex[:10]
    teacher = BetaAccount(
        email=f"beta-teacher-{suffix}@example.com",
        role="teacher",
        expected_user_id="",
    )
    student = BetaAccount(
        email=f"beta-student-{suffix}@example.com",
        role="student",
        expected_user_id="",
    )

    teacher_tokens = await beta_client.dev_login(teacher, name=f"Beta Teacher {suffix}")
    student_tokens = await beta_client.dev_login(student, name=f"Beta Student {suffix}")
    teacher_id = teacher_tokens.user["id"]
    student_id = student_tokens.user["id"]

    invite = await beta_client.create_invite(
        teacher_tokens.access_token,
        is_single_use=True,
        note=f"beta-smoke-{suffix}",
    )
    assert invite["creator_id"] == teacher_id
    assert invite["invite_code"]

    request = await beta_client.create_connection_request(
        student_tokens.access_token,
        target_id="",
        method="inviteCode",
        invite_code=invite["invite_code"],
        message="beta smoke invite-code onboarding",
    )
    assert request["status"] == "pending"
    assert request["requester_id"] == student_id
    assert request["target_id"] == teacher_id

    sent = await beta_client.get_sent_connection_requests(student_tokens.access_token)
    assert any(item["id"] == request["id"] for item in sent["items"])

    pending = await beta_client.get_pending_connection_requests(teacher_tokens.access_token)
    assert any(item["id"] == request["id"] for item in pending["items"])

    accepted = await beta_client.respond_to_connection_request(
        teacher_tokens.access_token,
        request["id"],
        action="accept",
    )
    assert accepted["status"] == "accepted"

    teacher_connections = await beta_client.get_connections(teacher_tokens.access_token)
    assert any(
        item["teacher_id"] == teacher_id and item["student_id"] == student_id and item["is_active"]
        for item in teacher_connections["items"]
    )

    student_connections = await beta_client.get_connections(student_tokens.access_token)
    assert any(
        item["teacher_id"] == teacher_id and item["student_id"] == student_id and item["is_active"]
        for item in student_connections["items"]
    )

    teacher_roster = await beta_client.get_students(teacher_tokens.access_token)
    assert any(
        item["user_id"] == student_id and item["connection_status"] == "connected"
        for item in teacher_roster["items"]
    )
