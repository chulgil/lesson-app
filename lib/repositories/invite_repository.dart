import 'dart:math';

import '../models/invite.dart';

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
}

/// Mock implementation of InviteRepository
class MockInviteRepository implements InviteRepository {
  final Map<String, Invite> _invites = {};
  final Map<String, ConnectionRequest> _requests = {};
  final Map<String, Connection> _connections = {};

  static const _appScheme = 'lessonapp';
  static const _inviteHost = 'invite';

  MockInviteRepository() {
    _initMockData();
  }

  void _initMockData() {
    // Add some mock data for testing
    final now = DateTime.now();

    // Teacher's invite
    _invites['invite_1'] = Invite(
      id: 'invite_1',
      creatorId: 'teacher_1',
      creatorRole: InviteUserRole.teacher,
      inviteCode: '123456',
      inviteUrl: '$_appScheme://$_inviteHost/123456',
      qrCodeData: '$_appScheme://$_inviteHost/123456',
      createdAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 6)),
    );

    // Student's invite
    _invites['invite_2'] = Invite(
      id: 'invite_2',
      creatorId: 'student_1',
      creatorRole: InviteUserRole.student,
      inviteCode: '654321',
      inviteUrl: '$_appScheme://$_inviteHost/654321',
      qrCodeData: '$_appScheme://$_inviteHost/654321',
      createdAt: now.subtract(const Duration(hours: 2)),
      expiresAt: now.add(const Duration(days: 7)),
    );

    // Pending connection request
    _requests['request_1'] = ConnectionRequest(
      id: 'request_1',
      requesterId: 'student_2',
      requesterRole: InviteUserRole.student,
      requesterName: '이학생',
      targetId: 'teacher_1',
      targetRole: InviteUserRole.teacher,
      targetName: '김선생님',
      method: InviteMethod.qrCode,
      inviteId: 'invite_1',
      message: '바이올린 레슨 받고 싶습니다!',
      createdAt: now.subtract(const Duration(hours: 3)),
      expiresAt: now.add(const Duration(days: 7)),
    );

    // Existing connection
    _connections['connection_1'] = Connection(
      id: 'connection_1',
      teacherId: 'teacher_1',
      teacherName: '김선생님',
      studentId: 'student_1',
      studentName: '박학생',
      connectedAt: now.subtract(const Duration(days: 30)),
    );
  }

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
    await Future.delayed(const Duration(milliseconds: 200));

    final id = 'invite_${DateTime.now().millisecondsSinceEpoch}';
    final code = _generateInviteCode();
    final now = DateTime.now();

    final invite = Invite(
      id: id,
      creatorId: creatorId,
      creatorRole: creatorRole,
      inviteCode: code,
      inviteUrl: '$_appScheme://$_inviteHost/$code',
      qrCodeData: '$_appScheme://$_inviteHost/$code',
      createdAt: now,
      expiresAt: now.add(validity),
      isSingleUse: isSingleUse,
      maxUses: maxUses,
      note: note,
    );

    _invites[id] = invite;
    return invite;
  }

  String _generateInviteCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  @override
  Future<Invite?> getInviteById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _invites[id];
  }

  @override
  Future<Invite?> getInviteByCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _invites.values.firstWhere(
        (i) => i.inviteCode == code && i.isValid,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Invite>> getInvitesByCreator(String creatorId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _invites.values
        .where((i) => i.creatorId == creatorId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final invite = _invites[inviteId];
    if (invite != null) {
      _invites[inviteId] = invite.copyWith(status: InviteStatus.revoked);
    }
  }

  @override
  Future<Invite> useInvite(String inviteId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final invite = _invites[inviteId];
    if (invite == null) {
      throw Exception('Invite not found');
    }
    if (!invite.isValid) {
      throw Exception('Invite is no longer valid');
    }

    final updated = invite.copyWith(
      useCount: invite.useCount + 1,
      status: invite.isSingleUse ? InviteStatus.used : invite.status,
    );
    _invites[inviteId] = updated;
    return updated;
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
    await Future.delayed(const Duration(milliseconds: 200));

    // Check if already connected
    final existingConnection = _findConnection(
      requesterRole == InviteUserRole.teacher ? requesterId : targetId,
      requesterRole == InviteUserRole.student ? requesterId : targetId,
    );
    if (existingConnection != null && existingConnection.isActive) {
      throw Exception('이미 연결되어 있습니다');
    }

    // Check for existing pending request
    final existingRequest = _requests.values.cast<ConnectionRequest?>().firstWhere(
      (r) =>
          r!.requesterId == requesterId &&
          r.targetId == targetId &&
          r.status == ConnectionRequestStatus.pending,
      orElse: () => null,
    );
    if (existingRequest != null) {
      throw Exception('이미 요청이 진행 중입니다');
    }

    final id = 'request_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final request = ConnectionRequest(
      id: id,
      requesterId: requesterId,
      requesterRole: requesterRole,
      targetId: targetId,
      targetRole: targetRole,
      method: method,
      inviteId: inviteId,
      message: message,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );

    _requests[id] = request;

    // Mark invite as used if applicable
    if (inviteId != null) {
      await useInvite(inviteId);
    }

    return request;
  }

  @override
  Future<ConnectionRequest?> getConnectionRequestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _requests[id];
  }

  @override
  Future<List<ConnectionRequest>> getPendingRequestsForUser(
      String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.values
        .where((r) =>
            r.targetId == userId &&
            r.status == ConnectionRequestStatus.pending &&
            r.isActionable)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<ConnectionRequest>> getSentRequestsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _requests.values.where((r) => r.requesterId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Connection> acceptConnectionRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Request not found');
    }
    if (!request.isActionable) {
      throw Exception('Request is no longer actionable');
    }

    // Update request status
    _requests[requestId] = request.copyWith(
      status: ConnectionRequestStatus.accepted,
      respondedAt: DateTime.now(),
    );

    // Determine teacher and student IDs
    final String teacherId;
    final String teacherName;
    final String studentId;
    final String studentName;

    if (request.requesterRole == InviteUserRole.teacher) {
      teacherId = request.requesterId;
      teacherName = request.requesterName ?? '선생님';
      studentId = request.targetId;
      studentName = request.targetName ?? '학생';
    } else {
      teacherId = request.targetId;
      teacherName = request.targetName ?? '선생님';
      studentId = request.requesterId;
      studentName = request.requesterName ?? '학생';
    }

    // Create connection
    final connectionId = 'connection_${DateTime.now().millisecondsSinceEpoch}';
    final connection = Connection(
      id: connectionId,
      teacherId: teacherId,
      teacherName: teacherName,
      studentId: studentId,
      studentName: studentName,
      connectionRequestId: requestId,
      connectedAt: DateTime.now(),
    );

    _connections[connectionId] = connection;
    return connection;
  }

  @override
  Future<void> rejectConnectionRequest(String requestId,
      {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Request not found');
    }

    _requests[requestId] = request.copyWith(
      status: ConnectionRequestStatus.rejected,
      respondedAt: DateTime.now(),
      rejectionReason: reason,
    );
  }

  @override
  Future<void> cancelConnectionRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final request = _requests[requestId];
    if (request == null) {
      throw Exception('Request not found');
    }

    _requests[requestId] = request.copyWith(
      status: ConnectionRequestStatus.cancelled,
      respondedAt: DateTime.now(),
    );
  }

  // ===== Connection Management =====

  @override
  Future<Connection?> getConnectionById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _connections[id];
  }

  @override
  Future<List<Connection>> getConnectionsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _connections.values
        .where((c) =>
            (c.teacherId == userId || c.studentId == userId) && c.isActive)
        .toList()
      ..sort((a, b) => b.connectedAt.compareTo(a.connectedAt));
  }

  @override
  Future<Connection?> getConnectionBetween(
      String teacherId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _findConnection(teacherId, studentId);
  }

  Connection? _findConnection(String teacherId, String studentId) {
    try {
      return _connections.values.firstWhere(
        (c) => c.teacherId == teacherId && c.studentId == studentId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deactivateConnection(String connectionId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found');
    }

    _connections[connectionId] = connection.copyWith(
      isActive: false,
      deactivatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> reactivateConnection(String connectionId) async {
    await Future.delayed(const Duration(milliseconds: 150));

    final connection = _connections[connectionId];
    if (connection == null) {
      throw Exception('Connection not found');
    }

    _connections[connectionId] = connection.copyWith(
      isActive: true,
      deactivatedAt: null,
    );
  }

  @override
  Future<bool> areConnected(String userId1, String userId2) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _connections.values.any((c) =>
        c.isActive &&
        ((c.teacherId == userId1 && c.studentId == userId2) ||
            (c.teacherId == userId2 && c.studentId == userId1)));
  }
}
