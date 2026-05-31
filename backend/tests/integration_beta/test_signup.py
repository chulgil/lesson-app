"""Remote beta signup/authentication smoke scenario."""

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
