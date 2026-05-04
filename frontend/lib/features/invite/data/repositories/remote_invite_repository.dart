import '../../../../core/network/api_client.dart';
import '../../../../features/profile/domain/entities/invite.dart';
import '../../../profile/domain/repositories/invite_repository.dart';

/// Remote implementation of [InviteRepository] using FastAPI backend.
class RemoteInviteRepository implements InviteRepository {
  final ApiClient _apiClient;

  RemoteInviteRepository(this._apiClient);

  // ===== Invite Management =====

  @override
  Future<Invite> createInvite({
    required String creatorId,
    required InviteUserRole creatorRole,
    bool isSingleUse = false,
    int? maxUses,
    Duration validity = const Duration(days: 7),
    String? note,
  }) async {
    final response = await _apiClient.post(
      '/invites/',
      data: {
        'is_single_use': isSingleUse,
        if (maxUses != null) 'max_uses': maxUses,
        'expires_in_hours': validity.inHours,
        if (note != null) 'note': note,
      },
    );
    return _inviteFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Invite?> getInviteById(String id) async {
    final response = await _apiClient.get('/invites/$id');
    return _inviteFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Invite?> getInviteByCode(String code) async {
    final response = await _apiClient.get(
      '/invites/code/${code.toUpperCase()}',
    );
    return _inviteFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<Invite>> getInvitesByCreator(String creatorId) async {
    final response = await _apiClient.get('/invites/');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => _inviteFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    await _apiClient.patch('/invites/$inviteId/revoke');
  }

  @override
  Future<Invite> useInvite(String inviteId) async {
    // Use is tracked server-side via connection request creation
    final invite = await getInviteById(inviteId);
    return invite!;
  }

  // ===== Connection Request Management =====

  @override
  Future<ConnectionRequest> createConnectionRequest({
    required String requesterId,
    required InviteUserRole requesterRole,
    required String targetId,
    required InviteUserRole targetRole,
    required InviteMethod method,
    String? inviteId,
    String? message,
  }) async {
    final response = await _apiClient.post(
      '/invites/connection-requests',
      data: {
        'target_id': targetId,
        'method': method.name,
        if (inviteId != null) 'invite_id': inviteId,
        if (message != null) 'message': message,
      },
    );
    return _requestFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ConnectionRequest?> getConnectionRequestById(String id) async {
    // No direct GET by ID endpoint — filter from pending list
    final pending = await getPendingRequestsForUser('');
    final sent = await getSentRequestsByUser('');
    final all = [...pending, ...sent];
    return all.where((r) => r.id == id).firstOrNull;
  }

  @override
  Future<List<ConnectionRequest>> getPendingRequestsForUser(
    String userId,
  ) async {
    final response = await _apiClient.get(
      '/invites/connection-requests/pending',
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => _requestFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ConnectionRequest>> getSentRequestsByUser(String userId) async {
    final response = await _apiClient.get('/invites/connection-requests/sent');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => _requestFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Connection> acceptConnectionRequest(String requestId) async {
    final response = await _apiClient.patch(
      '/invites/connection-requests/$requestId/respond',
      data: {'action': 'accept'},
    );
    // Backend returns ConnectionRequestResponse, not ConnectionResponse
    // Extract connection info from the response
    final data = response.data as Map<String, dynamic>;
    return Connection(
      id: data['id'] as String,
      teacherId: data['target_id'] as String? ?? '',
      teacherName: data['target_name'] as String? ?? '',
      studentId: data['requester_id'] as String? ?? '',
      studentName: data['requester_name'] as String? ?? '',
      connectedAt: DateTime.now(),
    );
  }

  @override
  Future<void> rejectConnectionRequest(
    String requestId, {
    String? reason,
  }) async {
    await _apiClient.patch(
      '/invites/connection-requests/$requestId/respond',
      data: {
        'action': 'reject',
        if (reason != null) 'rejection_reason': reason,
      },
    );
  }

  @override
  Future<void> cancelConnectionRequest(String requestId) async {
    await _apiClient.patch('/invites/connection-requests/$requestId/cancel');
  }

  // ===== Connection Management =====

  @override
  Future<Connection?> getConnectionById(String id) async {
    final connections = await getConnectionsByUser('');
    return connections.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<Connection>> getConnectionsByUser(String userId) async {
    final response = await _apiClient.get('/invites/connections');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((e) => _connectionFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Connection?> getConnectionBetween(
    String teacherId,
    String studentId,
  ) async {
    final connections = await getConnectionsByUser('');
    return connections
        .where((c) => c.teacherId == teacherId && c.studentId == studentId)
        .firstOrNull;
  }

  @override
  Future<void> deactivateConnection(String connectionId) async {
    await _apiClient.delete('/invites/connections/$connectionId');
  }

  @override
  Future<void> reactivateConnection(String connectionId) async {
    await _apiClient.patch('/invites/connections/$connectionId/reactivate');
  }

  @override
  Future<bool> areConnected(String userId1, String userId2) async {
    final connections = await getConnectionsByUser('');
    return connections.any(
      (c) =>
          c.isActive &&
          ((c.teacherId == userId1 && c.studentId == userId2) ||
              (c.teacherId == userId2 && c.studentId == userId1)),
    );
  }

  @override
  Future<List<Connection>> getInactiveConnectionsByUser(String userId) async {
    final response = await _apiClient.get(
      '/invites/connections',
      queryParameters: {'include_inactive': true},
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    final connections =
        items
            .map((e) => _connectionFromJson(e as Map<String, dynamic>))
            .toList();
    return connections.where((c) => !c.isActive).toList();
  }

  // ===== JSON Helpers =====

  Invite _inviteFromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      creatorName: json['creator_name'] as String?,
      creatorRole: InviteUserRole.values.firstWhere(
        (e) => e.name == json['creator_role'],
        orElse: () => InviteUserRole.teacher,
      ),
      inviteCode: json['invite_code'] as String,
      inviteUrl: json['invite_url'] as String? ?? '',
      qrCodeData: json['qr_code_data'] as String? ?? '',
      status: InviteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InviteStatus.active,
      ),
      isSingleUse: json['is_single_use'] as bool? ?? false,
      maxUses: json['max_uses'] as int?,
      useCount: json['use_count'] as int? ?? 0,
      note: json['note'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ConnectionRequest _requestFromJson(Map<String, dynamic> json) {
    return ConnectionRequest(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      requesterRole: InviteUserRole.values.firstWhere(
        (e) => e.name == json['requester_role'],
        orElse: () => InviteUserRole.student,
      ),
      requesterName: json['requester_name'] as String?,
      requesterProfileImage: json['requester_profile_image'] as String?,
      targetId: json['target_id'] as String,
      targetRole: InviteUserRole.values.firstWhere(
        (e) => e.name == json['target_role'],
        orElse: () => InviteUserRole.teacher,
      ),
      targetName: json['target_name'] as String?,
      targetProfileImage: json['target_profile_image'] as String?,
      method: InviteMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => InviteMethod.inviteCode,
      ),
      inviteId: json['invite_id'] as String?,
      message: json['message'] as String?,
      status: ConnectionRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionRequestStatus.pending,
      ),
      respondedAt:
          json['responded_at'] != null
              ? DateTime.parse(json['responded_at'] as String)
              : null,
      rejectionReason: json['rejection_reason'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Connection _connectionFromJson(Map<String, dynamic> json) {
    return Connection(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teacher_name'] as String? ?? '',
      teacherProfileImage: json['teacher_profile_image'] as String?,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? '',
      studentProfileImage: json['student_profile_image'] as String?,
      connectionRequestId: json['connection_request_id'] as String?,
      connectedAt: DateTime.parse(json['connected_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      deactivatedAt:
          json['deactivated_at'] != null
              ? DateTime.parse(json['deactivated_at'] as String)
              : null,
    );
  }
}
