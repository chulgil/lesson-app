import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parent.dart';
import '../../models/parent_child_relation.dart';
import '../../models/parent_visibility_settings.dart';
import '../../models/parent_notification_settings.dart';
import '../../repositories/parent_repository.dart';
import 'parent_repository_provider.dart';

// ============================================================================
// Parent CRUD Providers
// ============================================================================

/// All parents provider
final parentsProvider = FutureProvider<List<Parent>>((ref) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParents();
});

/// Single parent provider by ID
final parentProvider = FutureProvider.family<Parent?, String>((ref, id) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParent(id);
});

/// Parent by user ID provider
final parentByUserIdProvider =
    FutureProvider.family<Parent?, String>((ref, userId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getParentByUserId(userId);
});

// ============================================================================
// Invitation Providers
// ============================================================================

/// Invitation by code provider
final invitationByCodeProvider =
    FutureProvider.family<ParentInvitation?, String>((ref, code) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getInvitationByCode(code);
});

/// Pending invitations for a student
final pendingInvitationsProvider =
    FutureProvider.family<List<ParentInvitation>, String>(
        (ref, studentId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getPendingInvitationsForStudent(studentId);
});

// ============================================================================
// Relation Providers
// ============================================================================

/// Relations for a parent (their children)
final relationsForParentProvider =
    FutureProvider.family<List<ParentChildRelation>, String>(
        (ref, parentId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getRelationsForParent(parentId);
});

/// Relations for a student (their parents)
final relationsForStudentProvider =
    FutureProvider.family<List<ParentChildRelation>, String>(
        (ref, studentId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getRelationsForStudent(studentId);
});

/// Single relation between parent and student
final parentStudentRelationProvider = FutureProvider.family<ParentChildRelation?,
    ({String parentId, String studentId})>((ref, params) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getRelation(params.parentId, params.studentId);
});

// ============================================================================
// Visibility Settings Providers
// ============================================================================

/// Visibility settings for a student (set by teacher)
final visibilitySettingsProvider =
    FutureProvider.family<ParentVisibilitySettings?,
        ({String teacherId, String studentId})>((ref, params) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getVisibilitySettings(params.teacherId, params.studentId);
});

// ============================================================================
// Notification Settings Providers
// ============================================================================

/// Notification settings for a parent
final notificationSettingsProvider =
    FutureProvider.family<ParentNotificationSettings?, String>(
        (ref, parentId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getNotificationSettings(parentId);
});

// ============================================================================
// Billing Provider
// ============================================================================

/// Billing target parent for a student
final billingTargetProvider =
    FutureProvider.family<Parent?, String>((ref, studentId) async {
  final repository = ref.watch(parentRepositoryProvider);
  return repository.getBillingTargetForStudent(studentId);
});

// ============================================================================
// Parents Notifier (CRUD Operations)
// ============================================================================

/// Parent list notifier for CRUD operations
class ParentsNotifier extends AsyncNotifier<List<Parent>> {
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

final parentsNotifierProvider =
    AsyncNotifierProvider<ParentsNotifier, List<Parent>>(
  ParentsNotifier.new,
);

// ============================================================================
// Invitations Notifier
// ============================================================================

/// Invitation notifier for creating/managing invitations
class InvitationsNotifier
    extends FamilyAsyncNotifier<List<ParentInvitation>, String> {
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
          () => _repository.getPendingInvitationsForStudent(arg));
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
          () => _repository.getPendingInvitationsForStudent(arg));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final invitationsNotifierProvider = AsyncNotifierProvider.family<
    InvitationsNotifier, List<ParentInvitation>, String>(
  InvitationsNotifier.new,
);

// ============================================================================
// Relations Notifier
// ============================================================================

/// Relations notifier for managing parent-child relationships
class RelationsNotifier
    extends FamilyAsyncNotifier<List<ParentChildRelation>, String> {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<List<ParentChildRelation>> build(String parentId) async {
    return _repository.getRelationsForParent(parentId);
  }

  Future<ParentChildRelation> addRelation(ParentChildRelation relation) async {
    state = const AsyncValue.loading();
    try {
      final newRelation = await _repository.createRelation(relation);
      state =
          await AsyncValue.guard(() => _repository.getRelationsForParent(arg));
      return newRelation;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<ParentChildRelation> updateRelation(
      ParentChildRelation relation) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.updateRelation(relation);
      state =
          await AsyncValue.guard(() => _repository.getRelationsForParent(arg));
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
      state =
          await AsyncValue.guard(() => _repository.getRelationsForParent(arg));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final relationsNotifierProvider = AsyncNotifierProvider.family<RelationsNotifier,
    List<ParentChildRelation>, String>(
  RelationsNotifier.new,
);

// ============================================================================
// Visibility Settings Notifier
// ============================================================================

/// Visibility settings notifier for teacher to manage parent access
class VisibilitySettingsNotifier
    extends FamilyAsyncNotifier<ParentVisibilitySettings?,
        ({String teacherId, String studentId})> {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<ParentVisibilitySettings?> build(
      ({String teacherId, String studentId}) params) async {
    return _repository.getVisibilitySettings(
        params.teacherId, params.studentId);
  }

  Future<ParentVisibilitySettings> saveSettings(
      ParentVisibilitySettings settings) async {
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

final visibilitySettingsNotifierProvider = AsyncNotifierProvider.family<
    VisibilitySettingsNotifier,
    ParentVisibilitySettings?,
    ({String teacherId, String studentId})>(
  VisibilitySettingsNotifier.new,
);

// ============================================================================
// Notification Settings Notifier
// ============================================================================

/// Notification settings notifier for parent to customize their preferences
class NotificationSettingsNotifier
    extends FamilyAsyncNotifier<ParentNotificationSettings?, String> {
  ParentRepository get _repository => ref.read(parentRepositoryProvider);

  @override
  Future<ParentNotificationSettings?> build(String parentId) async {
    return _repository.getNotificationSettings(parentId);
  }

  Future<ParentNotificationSettings> saveSettings(
      ParentNotificationSettings settings) async {
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

final notificationSettingsNotifierProvider = AsyncNotifierProvider.family<
    NotificationSettingsNotifier, ParentNotificationSettings?, String>(
  NotificationSettingsNotifier.new,
);
