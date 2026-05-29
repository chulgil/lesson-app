"""Address search endpoints."""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Query, status

from app.schemas.address import AddressSearchResponse
from app.services.address_service import AddressService

router = APIRouter()


@router.get(
    "/search",
    response_model=AddressSearchResponse,
    status_code=status.HTTP_200_OK,
    summary="Search addresses",
)
async def search_address(
    query: Annotated[str, Query(min_length=1)],
    page: Annotated[int, Query(ge=1)] = 1,
    size: Annotated[int, Query(ge=1, le=50)] = 10,
) -> AddressSearchResponse:
    """Search addresses through backend-managed providers."""
    if not query.strip():
        from fastapi import HTTPException

        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="query must not be blank")
    service = AddressService()
    return await service.search(query.strip(), page=page, size=size)
