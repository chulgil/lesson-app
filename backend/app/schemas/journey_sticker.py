"""Journey sticker catalog schemas (P3b, doc 46 §5).

WIRE CONTRACT: this is a pure computed catalog — no accrual table backs it.
Every read re-aggregates existing log tables (practice_logs, practice_journal_volumes,
practice_recordings) and the streak SSOT, so entries are retroactive by construction
(a student who practiced before this feature shipped still sees prior progress/
achieved state — nothing to backfill).
"""

from __future__ import annotations

from pydantic import BaseModel


class JourneyStickerEntry(BaseModel):
    """Single sticker in the journey catalog.

    - key: globally unique, stable identifier (e.g. "practice_minutes_10").
    - family: catalog section for grouping (practice | journey | streak | growth).
    - metric: sub-group within a family for tier-ladder rendering
      (e.g. "practice" has two metrics: practice_minutes and practice_days).
    - tier: 1-based position within its metric's ladder.
    - unit: how to read target/current (minutes | days | count).
    """

    key: str
    family: str
    metric: str
    tier: int
    target: int
    current: int
    achieved: bool
    unit: str


class JourneyStickerCatalogResponse(BaseModel):
    """Aggregated journey sticker catalog for a student."""

    student_id: str
    stickers: list[JourneyStickerEntry]
