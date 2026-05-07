"""Contract tests for the backend database integrity inventory."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from app.models.base import Base

BACKEND_ROOT = Path(__file__).resolve().parent.parent
INVENTORY_PATH = BACKEND_ROOT / "docs" / "db_integrity_inventory.json"


def _load_inventory() -> dict[str, Any]:
    return json.loads(INVENTORY_PATH.read_text())


def test_db_integrity_inventory_names_real_tables_and_columns() -> None:
    """Every unresolved FK gap must point at a real SQLAlchemy table column."""
    inventory = _load_inventory()
    assert inventory["version"] == 1

    gaps = inventory["unresolved_foreign_key_gaps"]
    assert gaps
    seen = set()

    for gap in gaps:
        key = (gap["table"], gap["column"], gap["target"])
        assert key not in seen
        seen.add(key)

        table = Base.metadata.tables[gap["table"]]
        column = table.c[gap["column"]]
        targets = {fk.target_fullname for fk in column.foreign_keys}

        assert gap["status"] in {"missing", "partial", "present"}
        if gap["status"] == "missing":
            assert gap["target"] not in targets
        if gap["status"] == "present":
            assert gap["target"] in targets


def test_db_integrity_inventory_business_constraints_reference_real_tables() -> None:
    """Business-level constraint debt must be attached to existing tables."""
    inventory = _load_inventory()
    constraints = inventory["business_constraint_gaps"]
    assert constraints

    for constraint in constraints:
        assert constraint["table"] in Base.metadata.tables
        assert constraint["priority"] in {"P0", "P1", "P2"}
        assert constraint["type"] in {"check", "unique", "partial_unique", "exclusion", "state_machine"}


def test_subscription_counter_check_constraints_are_registered() -> None:
    """Subscription counter invariants should be backed by database checks."""
    table = Base.metadata.tables["subscriptions"]
    constraint_names = {constraint.name for constraint in table.constraints}

    assert "ck_subscriptions_non_negative_counters" in constraint_names
    assert "ck_subscriptions_lesson_counter_capacity" in constraint_names
    assert "ck_subscriptions_reschedule_counter_capacity" in constraint_names


def test_schedule_change_remote_contract_audit_is_recorded() -> None:
    """The per-session schedule-change remote API audit should stay explicit."""
    inventory = _load_inventory()
    audit = inventory["schedule_change_remote_contract_audit"]

    assert audit["canonical_event_api"] == "/api/v1/subscriptions/{subscription_id}/events"
    assert audit["session_scope_field"] == "session_number"
    assert audit["frontend_remote_status"] in {"mock_only", "partial", "remote"}
    assert audit["backend_remote_status"] in {"missing", "partial", "remote"}
