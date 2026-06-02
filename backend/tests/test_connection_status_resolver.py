"""ConnectionStatus ↔ RelationStatus mapping tests — G3 Phase A."""

from __future__ import annotations

import pytest

from app.models.relationship import RelationStatus
from app.models.student import ConnectionStatus
from app.services.connection_status_resolver import (
    connection_status_from_relation,
    relation_status_from_connection,
)


@pytest.mark.parametrize(
    "relation_status, expected_connection",
    [
        (RelationStatus.pending, ConnectionStatus.inviteSent),
        (RelationStatus.trialBooked, ConnectionStatus.connected),
        (RelationStatus.active, ConnectionStatus.connected),
        (RelationStatus.inactive, ConnectionStatus.offline),
        (RelationStatus.expired, ConnectionStatus.offline),
        (RelationStatus.past, ConnectionStatus.disconnected),
        (RelationStatus.disconnected, ConnectionStatus.disconnected),
    ],
)
def test_connection_status_from_relation_is_total(
    relation_status: RelationStatus,
    expected_connection: ConnectionStatus,
):
    """Every RelationStatus value maps to a defined ConnectionStatus."""
    assert connection_status_from_relation(relation_status) is expected_connection


@pytest.mark.parametrize(
    "connection_status, expected_relation",
    [
        (ConnectionStatus.offline, RelationStatus.inactive),
        (ConnectionStatus.inviteSent, RelationStatus.pending),
        (ConnectionStatus.inviteReceived, RelationStatus.pending),
        (ConnectionStatus.connected, RelationStatus.active),
        (ConnectionStatus.disconnected, RelationStatus.disconnected),
    ],
)
def test_relation_status_from_connection_is_total(
    connection_status: ConnectionStatus,
    expected_relation: RelationStatus,
):
    """Every ConnectionStatus value maps to a defined RelationStatus."""
    assert relation_status_from_connection(connection_status) is expected_relation


def test_connection_status_enum_carries_deprecation_doc():
    """ConnectionStatus docstring documents the SSOT migration (G3 Phase A)."""
    doc = (ConnectionStatus.__doc__ or "").lower()
    assert "deprecated" in doc
    assert "relationshipstatus" in doc or "relationstatus" in doc
