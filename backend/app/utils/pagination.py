"""Pagination utilities."""
from dataclasses import dataclass

from fastapi import Query
from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession


@dataclass
class PaginationParams:
    """Pagination parameters."""
    page: int = 1
    size: int = 20

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.size


def get_pagination(
    page: int = Query(1, ge=1, description="Page number"),
    size: int = Query(20, ge=1, le=100, description="Page size"),
) -> PaginationParams:
    """FastAPI dependency for pagination parameters."""
    return PaginationParams(page=page, size=size)


async def paginate(
    db: AsyncSession,
    query: Select,
    params: PaginationParams,
) -> dict:
    """Execute paginated query and return results with metadata."""
    # Count total
    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar() or 0

    # Fetch page
    paginated = query.offset(params.offset).limit(params.size)
    result = await db.execute(paginated)
    items = result.scalars().all()

    return {
        "items": items,
        "total": total,
        "page": params.page,
        "size": params.size,
        "pages": (total + params.size - 1) // params.size,
    }
