"""Practice journal request / response schemas (#872).

All fields are snake_case — the FE .g.dart files are the authoritative wire
contract.  CAMEL_MODEL_CONFIG is intentionally NOT used here.

WIRE CONTRACT (FE .g.dart authoritative keys):
  - PracticeMark response: date, intensity
  - GuardianSeal response:  week_start, guardian_user_id, cheer_note
  - Endorsement response:   by, date, author_user_id, assignment_ref, note
  - BoundVolume response:   child_profile_id, piece_id, piece_name, volume_no, bound_date
  - PracticeLedger:         child_profile_id, year, month, marks[], seals[], endorsements[]

guardian_user_id / author_user_id in request bodies are ACCEPTED but IGNORED —
the service stamps the current authenticated user's id (anti-IDOR).
"""

from __future__ import annotations

import datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

# ---------------------------------------------------------------------------
# Shared config
# ---------------------------------------------------------------------------

_PLAIN = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------


class MarkUpsertRequest(BaseModel):
    """Upsert a daily practice mark (short or full).

    FE body: {child_profile_id, date, intensity}.
    """

    child_profile_id: str
    date: datetime.date
    # Values: "short" | "full"
    intensity: str = Field(pattern=r"^(short|full)$")


class GuardianSealRequest(BaseModel):
    """Apply a guardian weekly seal.

    FE body: {child_profile_id, week_start, guardian_user_id, cheer_note?}.
    guardian_user_id in the body is accepted but IGNORED — the service stamps
    the current authenticated user's id (anti-IDOR).
    """

    child_profile_id: str
    # week_start is normalized to the nearest Monday by the service
    week_start: datetime.date
    # Accepted-but-ignored; service stamps current user. Optional in case FE omits.
    guardian_user_id: str | None = None
    cheer_note: str | None = None


class EndorsementRequest(BaseModel):
    """Teacher or self endorsement.

    FE body: {child_profile_id, by, date, author_user_id, assignment_ref?, note}.
    author_user_id is accepted but IGNORED — the service stamps the current
    authenticated user's id (anti-IDOR).

    Validation rules:
      - by="teacher": assignment_ref is required
      - by="self": assignment_ref must be absent/None
    """

    child_profile_id: str
    # Values: "self" | "teacher"
    by: str = Field(pattern=r"^(self|teacher)$")
    date: datetime.date
    # Accepted-but-ignored; service stamps current user.
    author_user_id: str | None = None
    assignment_ref: str | None = Field(default=None, max_length=64)
    note: str

    @model_validator(mode="after")
    def _validate_ref_rules(self) -> EndorsementRequest:
        if self.by == "teacher" and not self.assignment_ref:
            raise ValueError("assignment_ref is required when by is 'teacher'")
        if self.by == "self" and self.assignment_ref:
            raise ValueError("assignment_ref must be absent when by is 'self'")
        return self


class BindVolumeRequest(BaseModel):
    """Bind a completed piece into a volume.

    FE body: {child_profile_id, piece_id, piece_name}.
    Idempotent: if (child_profile_id, piece_id) already exists, returns the
    existing row (HTTP 200, not 409).
    """

    child_profile_id: str
    piece_id: str
    piece_name: str = Field(max_length=200)


# ---------------------------------------------------------------------------
# Response schemas — keys mirror FE .g.dart fromJson exactly
# ---------------------------------------------------------------------------


class PracticeMarkResponse(BaseModel):
    """FE PracticeMark.fromJson reads: date, intensity."""

    model_config = _PLAIN

    date: datetime.date
    intensity: str


class GuardianSealResponse(BaseModel):
    """FE GuardianSeal.fromJson reads: week_start, guardian_user_id, cheer_note."""

    model_config = _PLAIN

    week_start: datetime.date
    guardian_user_id: str
    cheer_note: str | None


class EndorsementResponse(BaseModel):
    """FE Endorsement.fromJson reads: by, date, author_user_id, assignment_ref, note."""

    model_config = _PLAIN

    by: str
    date: datetime.date
    author_user_id: str
    assignment_ref: str | None
    note: str


class BoundVolumeResponse(BaseModel):
    """FE BoundVolume.fromJson reads: child_profile_id, piece_id, piece_name, volume_no, bound_date."""

    model_config = _PLAIN

    child_profile_id: str
    piece_id: str
    piece_name: str
    volume_no: int
    bound_date: datetime.date


class LedgerResponse(BaseModel):
    """FE PracticeLedger.fromJson reads: child_profile_id, year, month, marks[], seals[], endorsements[].

    Each list element is a full object (PracticeMark / GuardianSeal / Endorsement),
    NOT a flattened day-summary.
    """

    child_profile_id: str
    year: int
    month: int
    marks: list[PracticeMarkResponse]
    seals: list[GuardianSealResponse]
    endorsements: list[EndorsementResponse]
