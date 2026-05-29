"""Address search schemas."""

from __future__ import annotations

from pydantic import BaseModel


class AddressSearchResult(BaseModel):
    """Unified address search result returned to clients."""

    postal_code: str
    address: str
    road_address: str | None = None
    district: str
    latitude: float | None = None
    longitude: float | None = None


class AddressSearchResponse(BaseModel):
    """Address search response."""

    results: list[AddressSearchResult]
    total_count: int
    page: int
    size: int
