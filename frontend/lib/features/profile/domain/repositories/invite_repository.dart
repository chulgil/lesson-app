import '../entities/invite.dart';
import '../entities/pending_invite.dart';

/// Repository interface for invite and connection management
abstract class InviteRepository {
  // ===== Invite Management =====

  /// Create a new invite (QR/URL/code)
  Future<Invite> createInvite({
    required String creatorId,
    required InviteUserRole creatorRole,
    bool isSingleUse = false,
    int? maxUses,
    Duration validity = const Duration(days: 7),
    String? note,
    InviteTargetRole? targetRole,
  });

  /// Get invite by ID
  Future<Invite?> getInviteById(String id);

  /// Get invite by code
  Future<Invite?> getInviteByCode(String code);

  /// Get all invites created by user
  Future<List<Invite>> getInvitesByCreator(String creatorId);

  /// Revoke an invite
  Future<void> revokeInvite(String inviteId);

  /// Use an invite (increment use count)
  Future<Invite> useInvite(String inviteId);

  // ===== G3 Phase 2 — Pending invite dashboard (#5 D-G3) =====

  /// 현재 사용자의 active + 만료 전 초대 목록 (D+N 큰 순).
  Future<List<PendingInvite>> getPendingInvites();

  /// 초대 재발송: expires_at 갱신 + resent_count++.
  /// 서버 정책: 10분 쿨다운, 만료된 초대도 부활, used/revoked 는 400.
  Future<void> resendInvite(String inviteId);

  // ===== Connection Request Management =====

  /// Create a connection request from invite
  Future<ConnectionRequest> createConnectionRequest({
    required String requesterId,
    required InviteUserRole requesterRole,
    required String targetId,
    required InviteUserRole targetRole,
    required InviteMethod method,
    String? inviteId,
    String? message,
  });

  /// Get connection request by ID
  Future<ConnectionRequest?> getConnectionRequestById(String id);

  /// Get pending requests for a user (as target)
  Future<List<ConnectionRequest>> getPendingRequestsForUser(String userId);

  /// Get sent requests by a user (as requester)
  Future<List<ConnectionRequest>> getSentRequestsByUser(String userId);

  /// Accept a connection request
  Future<Connection> acceptConnectionRequest(String requestId);

  /// Reject a connection request
  Future<void> rejectConnectionRequest(String requestId, {String? reason});

  /// Cancel a connection request (by requester)
  Future<void> cancelConnectionRequest(String requestId);

  // ===== Connection Management =====

  /// Get connection by ID
  Future<Connection?> getConnectionById(String id);

  /// Get all connections for a user
  Future<List<Connection>> getConnectionsByUser(String userId);

  /// Get connection between specific teacher and student
  Future<Connection?> getConnectionBetween(String teacherId, String studentId);

  /// Deactivate a connection
  Future<void> deactivateConnection(String connectionId);

  /// Reactivate a connection
  Future<void> reactivateConnection(String connectionId);

  /// Check if two users are connected
  Future<bool> areConnected(String userId1, String userId2);

  /// Get inactive (disconnected) connections for a user
  /// Returns teachers that the student previously had lessons with but is now disconnected
  Future<List<Connection>> getInactiveConnectionsByUser(String userId);
}
