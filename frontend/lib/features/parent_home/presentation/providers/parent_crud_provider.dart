import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/parent.dart';
import '../../domain/entities/parent_child_relation.dart';
import '../../domain/entities/parent_visibility_settings.dart';
import '../../domain/entities/parent_notification_settings.dart';
import '../../domain/repositories/parent_repository.dart';
import 'parent_repository_provider.dart';

part 'parent_crud_provider.g.dart';

// ============================================================================
// Parent CRUD Providers
// ============================================================================

/// All parents provider
@Riverpod(keepAlive: true)
Future<List<Parent>> parents(ParentsRef ref) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParents();
}

/// Single parent provider by ID
@Riverpod(keepAlive: true)
Future<Parent?> parent(ParentRef ref, String id) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParent(id);
}

/// Parent by user ID provider
@Riverpod(keepAlive: true)
Future<Parent?> parentByUserId(ParentByUserIdRef ref, String userId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParentByUserId(userId);
}

// ============================================================================
// Invitation Providers
// ============================================================================

/// Invitation by code provider
@Riverpod(keepAlive: true)
Future<ParentInvitation?> invitationByCode(
  InvitationByCodeRef ref,
  String code,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getInvitationByCode(code);
}

/// Pending invitations for a student
@Riverpod(keepAlive: true)
Future<List<ParentInvitation>> pendingInvitations(
  PendingInvitationsRef ref,
  String studentId,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getPendingInvitationsForStudent(studentId);
}

// ============================================================================
// Relation Providers
// ============================================================================

/// Relations for a parent (their children)
@Riverpod(keepAlive: true)
Future<List<ParentChildRelation>> relationsForParent(
  RelationsForParentRef ref,
  String parentId,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getRelationsForParent(parentId);
}

/// Relations for a student (their parents)
@Riverpod(keepAlive: true)
Future<List<ParentChildRelation>> relationsForStudent(
  RelationsForStudentRef ref,
  String studentId,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getRelationsForStudent(studentId);
}

/// Single relation between parent and student
@Riverpod(keepAlive: true)
Future<ParentChildRelation?> parentStudentRelation(
  ParentStudentRelationRef ref,
  ({String parentId, String studentId}) params,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getRelation(params.parentId, params.studentId);
}

// ============================================================================
// Visibility Settings Providers
// ============================================================================

/// Visibility settings for a student (set by teacher)
@Riverpod(keepAlive: true)
Future<ParentVisibilitySettings?> visibilitySettings(
  VisibilitySettingsRef ref,
  ({String teacherId, String studentId}) params,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getVisibilitySettings(params.teacherId, params.studentId);
}

// ============================================================================
// Notification Settings Providers
// ============================================================================

/// Notification settings for a parent
@Riverpod(keepAlive: true)
Future<ParentNotificationSettings?> notificationSettings(
  NotificationSettingsRef ref,
  String parentId,
) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getNotificationSettings(parentId);
}

// ============================================================================
// Billing Provider
// ============================================================================

/// Billing target parent for a student
@Riverpod(keepAlive: true)
Future<Parent?> billingTarget(BillingTargetRef ref, String studentId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getBillingTargetForStudent(studentId);
}

// ============================================================================
// Parents Notifier (CRUD Operations)
// ============================================================================

/// Parent list notifier for CRUD operations
@Riverpod(keepAlive: true)
class ParentsNotifier extends _$ParentsNotifier {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<List<Parent>> build() async {
    return _repository.getParents();
  }

  Future<Parent> addParent(Parent parent) async {
    state = const AsyncValue.loading();
    try {
      final newParent = await _repository.createParent(parent);
      state = await AsyncValue.guard(() => _repository.getParents());
      return newParent;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Parent> updateParent(Parent parent) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateParent(parent);
      state = await AsyncValue.guard(() => _repository.getParents());
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteParent(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteParent(id);
      state = await AsyncValue.guard(() => _repository.getParents());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getParents());
  }
}

// ============================================================================
// Invitations Notifier
// ============================================================================

/// Invitation notifier for creating/managing invitations
@Riverpod(keepAlive: true)
class InvitationsNotifier extends _$InvitationsNotifier {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<List<ParentInvitation>> build(String studentId) async {
    return _repository.getPendingInvitationsForStudent(studentId);
  }

  Future<ParentInvitation> createInvitation(ParentInvitation invitation) async {
    state = const AsyncValue.loading();
    try {
      final newInvitation = await _repository.createInvitation(invitation);
      state = await AsyncValue.guard(
        () => _repository.getPendingInvitationsForStudent(studentId),
      );
      return newInvitation;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> markUsed(String invitationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.markInvitationUsed(invitationId);
      state = await AsyncValue.guard(
        () => _repository.getPendingInvitationsForStudent(studentId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ============================================================================
// Relations Notifier
// ============================================================================

/// Relations notifier for managing parent-child relationships
@Riverpod(keepAlive: true)
class RelationsNotifier extends _$RelationsNotifier {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<List<ParentChildRelation>> build(String parentId) async {
    return _repository.getRelationsForParent(parentId);
  }

  Future<ParentChildRelation> addRelation(ParentChildRelation relation) async {
    state = const AsyncValue.loading();
    try {
      final newRelation = await _repository.createRelation(relation);
      state = await AsyncValue.guard(
        () => _repository.getRelationsForParent(parentId),
      );
      return newRelation;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<ParentChildRelation> updateRelation(
    ParentChildRelation relation,
  ) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateRelation(relation);
      state = await AsyncValue.guard(
        () => _repository.getRelationsForParent(parentId),
      );
      return updated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRelation(String relationId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteRelation(relationId);
      state = await AsyncValue.guard(
        () => _repository.getRelationsForParent(parentId),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ============================================================================
// Visibility Settings Notifier
// ============================================================================

/// Visibility settings notifier for teacher to manage parent access
@Riverpod(keepAlive: true)
class VisibilitySettingsNotifier extends _$VisibilitySettingsNotifier {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<ParentVisibilitySettings?> build(
    ({String teacherId, String studentId}) params,
  ) async {
    return _repository.getVisibilitySettings(
      params.teacherId,
      params.studentId,
    );
  }

  Future<ParentVisibilitySettings> saveSettings(
    ParentVisibilitySettings settings,
  ) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repository.saveVisibilitySettings(settings);
      state = AsyncValue.data(saved);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ============================================================================
// Notification Settings Notifier
// ============================================================================

/// Notification settings notifier for parent to customize their preferences
@Riverpod(keepAlive: true)
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<ParentNotificationSettings?> build(String parentId) async {
    return _repository.getNotificationSettings(parentId);
  }

  Future<ParentNotificationSettings> saveSettings(
    ParentNotificationSettings settings,
  ) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repository.saveNotificationSettings(settings);
      state = AsyncValue.data(saved);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
