import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/providers/repository_provider.dart';
import '../../../auth/auth_facade.dart';
import '../../data/repositories/mock_invite_repository.dart';
import '../../domain/entities/invite.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../../invite/data/repositories/remote_invite_repository.dart';
import '../../../students/students_facade.dart';

part 'invite_provider.g.dart';

/// Provider for invite repository - switches between Mock and Remote.
@Riverpod(keepAlive: true)
InviteRepository inviteRepository(Ref ref) =>
    createRepository<InviteRepository>(
      ref: ref,
      mock: () => MockInviteRepository(),
      remote: (api) => RemoteInviteRepository(api),
    );

/// Current user role - synced with app's role system
@Riverpod(keepAlive: true)
class CurrentInviteUserRole extends _$CurrentInviteUserRole {
  @override
  InviteUserRole build() {
    // Sync with app's role system
    final appRole = ref.watch(currentUserRoleProvider);
    return _mapUserRole(appRole);
  }

  InviteUserRole _mapUserRole(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return InviteUserRole.teacher;
      case UserRole.student:
      case UserRole.parent:
        // Parent uses student role for invite system
        return InviteUserRole.student;
    }
  }

  void setRole(InviteUserRole role) {
    state = role;
  }
}

/// Current user ID - synced with app's user system
@Riverpod(keepAlive: true)
class CurrentInviteUserId extends _$CurrentInviteUserId {
  @override
  String build() {
    // Sync with app's user system
    return ref.watch(currentUserIdProvider);
  }

  void setUserId(String userId) {
    state = userId;
  }
}

// ===== Invite Management =====

/// Create a new invite
@riverpod
class InviteCreator extends _$InviteCreator {
  @override
  AsyncValue<Invite?> build() {
    return const AsyncValue.data(null);
  }

  Future<Invite?> createInvite({
    bool isSingleUse = false,
    int? maxUses,
    Duration validity = const Duration(days: 7),
    String? note,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      final creatorId = ref.read(currentInviteUserIdProvider);
      final creatorRole = ref.read(currentInviteUserRoleProvider);

      final invite = await repo.createInvite(
        creatorId: creatorId,
        creatorRole: creatorRole,
        isSingleUse: isSingleUse,
        maxUses: maxUses,
        validity: validity,
        note: note,
      );

      state = AsyncValue.data(invite);

      // Refresh the invites list
      ref.invalidate(myInvitesProvider);

      return invite;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Get user's own invites
@riverpod
Future<List<Invite>> myInvites(Ref ref) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final userId = ref.watch(currentInviteUserIdProvider);
  return repo.getInvitesByCreator(userId);
}

/// Get invite by code
@riverpod
Future<Invite?> inviteByCode(Ref ref, String code) async {
  final repo = ref.watch(inviteRepositoryProvider);
  return repo.getInviteByCode(code);
}

/// Revoke invite action
@riverpod
class InviteRevoker extends _$InviteRevoker {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> revokeInvite(String inviteId) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      await repo.revokeInvite(inviteId);
      state = const AsyncValue.data(null);

      // Refresh the invites list
      ref.invalidate(myInvitesProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// ===== Connection Request Management =====

/// Create connection request from invite code
@riverpod
class ConnectionRequester extends _$ConnectionRequester {
  @override
  AsyncValue<ConnectionRequest?> build() {
    return const AsyncValue.data(null);
  }

  Future<ConnectionRequest?> requestConnection({
    required String targetId,
    required InviteUserRole targetRole,
    required InviteMethod method,
    String? inviteId,
    String? message,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      final requesterId = ref.read(currentInviteUserIdProvider);
      final requesterRole = ref.read(currentInviteUserRoleProvider);

      final request = await repo.createConnectionRequest(
        requesterId: requesterId,
        requesterRole: requesterRole,
        targetId: targetId,
        targetRole: targetRole,
        method: method,
        inviteId: inviteId,
        message: message,
      );

      state = AsyncValue.data(request);

      // Refresh sent requests
      ref.invalidate(mySentRequestsProvider);

      return request;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Rethrow typed API errors so the caller can distinguish conflict (409)
      // from generic network failures and show the appropriate UI.
      if (e is ApiException) rethrow;
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Pending requests for current user (as target)
@riverpod
Future<List<ConnectionRequest>> pendingRequests(Ref ref) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final userId = ref.watch(currentInviteUserIdProvider);
  return repo.getPendingRequestsForUser(userId);
}

/// Sent requests by current user
@riverpod
Future<List<ConnectionRequest>> mySentRequests(Ref ref) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final userId = ref.watch(currentInviteUserIdProvider);
  return repo.getSentRequestsByUser(userId);
}

/// Accept/Reject connection request
@riverpod
class ConnectionRequestResponder extends _$ConnectionRequestResponder {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<Connection?> acceptRequest(String requestId) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      final connection = await repo.acceptConnectionRequest(requestId);
      state = const AsyncValue.data(null);

      // Refresh relevant providers
      ref.invalidate(pendingRequestsProvider);
      ref.invalidate(myConnectionsProvider);
      ref.invalidate(studentsProvider);
      ref.invalidate(studentsNotifierProvider);

      // #1212 — 요청자(상대방) 통지는 BE Notification row 가 SSOT.
      // flutter_local_notifications 는 액터(수락자) 기기 전용이라 상대 통지로 쓸 수
      // 없어(기존엔 수락자 기기에 오발) FE 로컬 알림 호출을 제거함.

      return connection;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> rejectRequest(String requestId, {String? reason}) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      await repo.rejectConnectionRequest(requestId, reason: reason);
      state = const AsyncValue.data(null);

      // Refresh pending requests
      ref.invalidate(pendingRequestsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      await repo.cancelConnectionRequest(requestId);
      state = const AsyncValue.data(null);

      // Refresh sent requests
      ref.invalidate(mySentRequestsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

// ===== Connection Management =====

/// Current user's connections
@riverpod
Future<List<Connection>> myConnections(Ref ref) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final userId = ref.watch(currentInviteUserIdProvider);
  return repo.getConnectionsByUser(userId);
}

/// Check if connected with specific user
@riverpod
Future<bool> isConnectedWith(Ref ref, String otherUserId) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final userId = ref.watch(currentInviteUserIdProvider);
  return repo.areConnected(userId, otherUserId);
}

/// Connection manager for deactivate/reactivate
@riverpod
class ConnectionManager extends _$ConnectionManager {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> deactivateConnection(String connectionId) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      await repo.deactivateConnection(connectionId);
      state = const AsyncValue.data(null);

      ref.invalidate(myConnectionsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> reactivateConnection(String connectionId) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(inviteRepositoryProvider);
      await repo.reactivateConnection(connectionId);
      state = const AsyncValue.data(null);

      ref.invalidate(myConnectionsProvider);

      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

/// Pending request count (for badge display)
@riverpod
Future<int> pendingRequestCount(Ref ref) async {
  final requests = await ref.watch(pendingRequestsProvider.future);
  return requests.length;
}

// ===== Disconnected (Previous) Teachers =====

/// Get inactive/disconnected connections for current user
/// Used in teacher search to show "이전에 레슨했어요" teachers
@riverpod
Future<List<Connection>> myDisconnectedConnections(Ref ref) async {
  final repo = ref.watch(inviteRepositoryProvider);
  final userId = ref.watch(currentInviteUserIdProvider);
  return repo.getInactiveConnectionsByUser(userId);
}

/// Get teacher IDs that the current student previously had lessons with
@riverpod
Future<Set<String>> previousTeacherIds(Ref ref) async {
  final connections = await ref.watch(myDisconnectedConnectionsProvider.future);
  return connections.map((c) => c.teacherId).toSet();
}
