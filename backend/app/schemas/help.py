"""Help manual schemas."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel

HelpRole = Literal["student", "teacher", "parent"]


class HelpFaqResponse(BaseModel):
    id: str
    role: HelpRole
    category: str
    question: str
    answer: str
    search_keywords: list[str]
    related_quest_id: str | None = None
