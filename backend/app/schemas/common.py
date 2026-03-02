"""Common schemas shared across the application."""

from __future__ import annotations

import math
from typing import Generic, TypeVar

from pydantic import BaseModel, ConfigDict

T = TypeVar("T")


class PaginatedResponse(BaseModel, Generic[T]):
    """Generic paginated list response."""

    model_config = ConfigDict(from_attributes=True)

    items: list[T]
    total: int
    page: int
    size: int
    pages: int

    @classmethod
    def create(cls, *, items: list[T], total: int, page: int, size: int) -> "PaginatedResponse[T]":
        """Factory that computes `pages` automatically."""
        return cls(
            items=items,
            total=total,
            page=page,
            size=size,
            pages=max(1, math.ceil(total / size)),
        )


class ErrorResponse(BaseModel):
    """Standard error response body."""

    detail: str
    code: str


class SuccessResponse(BaseModel):
    """Generic success message."""

    message: str
