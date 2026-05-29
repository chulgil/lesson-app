"""Server-mediated address search service."""

from __future__ import annotations

from abc import ABC, abstractmethod

from app.schemas.address import AddressSearchResponse


class AddressProvider(ABC):
    """External address API interface."""

    @abstractmethod
    async def search(self, query: str, page: int, size: int) -> AddressSearchResponse:
        """Search addresses using the provider."""


class AddressService:
    """Address search service with provider fallback."""

    def __init__(self, providers: list[AddressProvider] | None = None) -> None:
        self.providers = providers or []

    async def search(self, query: str, page: int = 1, size: int = 10) -> AddressSearchResponse:
        """Search addresses through configured providers.

        Without provider credentials, return an empty unified response instead
        of exposing external API keys to clients.
        """
        for provider in self.providers:
            try:
                return await provider.search(query, page, size)
            except Exception:
                continue
        return AddressSearchResponse(results=[], total_count=0, page=page, size=size)
