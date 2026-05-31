"""Fixtures for remote beta API integration tests."""

from __future__ import annotations

import os
from collections.abc import AsyncIterator

import httpx
import pytest

from tests.integration_beta.helpers import BetaAccount, BetaClient

BETA_BASE_URL = os.getenv("BETA_BASE_URL", "https://api-beta.lessonaza.app").rstrip("/")
INTERNAL_API_KEY = os.getenv("INTERNAL_API_KEY")


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    if INTERNAL_API_KEY:
        return

    reason = "INTERNAL_API_KEY is required for beta integration tests"
    skip_marker = pytest.mark.skip(reason=reason)
    for item in items:
        item.add_marker(skip_marker)


@pytest.fixture(scope="session")
def beta_teacher_account() -> BetaAccount:
    return BetaAccount(
        email="minyeon@example.com",
        role="teacher",
        expected_user_id="seed-teacher-0001",
    )


@pytest.fixture(scope="session")
async def beta_client() -> AsyncIterator[BetaClient]:
    if INTERNAL_API_KEY is None:
        pytest.skip("INTERNAL_API_KEY is required for beta integration tests")

    timeout = httpx.Timeout(15.0, connect=5.0)
    async with httpx.AsyncClient(base_url=BETA_BASE_URL, timeout=timeout) as client:
        yield BetaClient(client, INTERNAL_API_KEY)
