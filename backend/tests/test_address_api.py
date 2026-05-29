"""Tests for server-mediated address search API."""

from __future__ import annotations

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_address_search_returns_unified_empty_response(client: AsyncClient) -> None:
    response = await client.get("/api/v1/address/search?query=역삼동&page=1&size=10")

    assert response.status_code == 200
    assert response.json() == {
        "results": [],
        "total_count": 0,
        "page": 1,
        "size": 10,
    }


@pytest.mark.asyncio
async def test_address_search_rejects_blank_query(client: AsyncClient) -> None:
    response = await client.get("/api/v1/address/search?query=   ")

    assert response.status_code == 422
