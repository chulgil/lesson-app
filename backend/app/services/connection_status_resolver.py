"""Connection ↔ Relation status resolver — G3 Phase A.

`Student.connection_status` is the legacy enum; `TeacherStudentRelation.status`
is the SSOT going forward (gap catalog #5 D-G3). This module provides:

  * `connection_status_from_relation(relation_status)` — derive the legacy
    enum from the SSOT for read-paths that still expect ConnectionStatus
  * `effective_status_label(connection_status)` — UI/diagnostic label that
    follows the SSOT mapping (single Korean phrase per status)

No DB writes here — Phase B will migrate the column itself.
"""

from __future__ import annotations

from app.models.relationship import RelationStatus
from app.models.student import ConnectionStatus

# Mapping table (SSOT → legacy enum). Kept explicit so reviewers can audit it.
_RELATION_TO_CONNECTION: dict[RelationStatus, ConnectionStatus] = {
    RelationStatus.pending: ConnectionStatus.inviteSent,
    RelationStatus.trialBooked: ConnectionStatus.connected,
    RelationStatus.active: ConnectionStatus.connected,
    RelationStatus.inactive: ConnectionStatus.offline,
    RelationStatus.expired: ConnectionStatus.offline,
    RelationStatus.past: ConnectionStatus.disconnected,
    RelationStatus.disconnected: ConnectionStatus.disconnected,
}

# Inverse table — for legacy ConnectionStatus → most-likely RelationStatus.
_CONNECTION_TO_RELATION: dict[ConnectionStatus, RelationStatus] = {
    ConnectionStatus.offline: RelationStatus.inactive,
    ConnectionStatus.inviteSent: RelationStatus.pending,
    ConnectionStatus.inviteReceived: RelationStatus.pending,
    ConnectionStatus.connected: RelationStatus.active,
    ConnectionStatus.disconnected: RelationStatus.disconnected,
}


def connection_status_from_relation(status: RelationStatus) -> ConnectionStatus:
    """SSOT → legacy enum, deterministic. Used by reads that still type ConnectionStatus."""
    return _RELATION_TO_CONNECTION.get(status, ConnectionStatus.offline)


def relation_status_from_connection(status: ConnectionStatus) -> RelationStatus:
    """Legacy enum → best-effort SSOT (Phase B will refine per row)."""
    return _CONNECTION_TO_RELATION.get(status, RelationStatus.inactive)
