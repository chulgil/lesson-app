import 'package:uuid/uuid.dart';

import '../entities/parent.dart';
import '../entities/parent_child_relation.dart';
import '../entities/parent_visibility_settings.dart';
import '../entities/parent_notification_settings.dart';

/// Repository for managing parent data and relationships
abstract class ParentRepository {
  // Parent CRUD
  Future<List<Parent>> getParents();
  Future<Parent?> getParent(String id);
  Future<Parent?> getParentByUserId(String userId);
  Future<Parent> createParent(Parent parent);
  Future<Parent> updateParent(Parent parent);
  Future<void> deleteParent(String id);

  // Parent Invitation
  Future<ParentInvitation> createInvitation(ParentInvitation invitation);
  Future<ParentInvitation?> getInvitationByCode(String code);
  Future<void> markInvitationUsed(String invitationId);
  Future<List<ParentInvitation>> getPendingInvitationsForStudent(
      String studentId);

  // Parent-Child Relations
  Future<List<ParentChildRelation>> getRelationsForParent(String parentId);
  Future<List<ParentChildRelation>> getRelationsForStudent(String studentId);
  Future<ParentChildRelation?> getRelation(String parentId, String studentId);
  Future<ParentChildRelation> createRelation(ParentChildRelation relation);
  Future<ParentChildRelation> updateRelation(ParentChildRelation relation);
  Future<void> deleteRelation(String relationId);

  // Visibility Settings
  Future<ParentVisibilitySettings?> getVisibilitySettings(
      String teacherId, String studentId);
  Future<ParentVisibilitySettings> saveVisibilitySettings(
      ParentVisibilitySettings settings);

  // Notification Settings
  Future<ParentNotificationSettings?> getNotificationSettings(String parentId);
  Future<ParentNotificationSettings> saveNotificationSettings(
      ParentNotificationSettings settings);

  // Billing
  Future<Parent?> getBillingTargetForStudent(String studentId);
}

/// Mock implementation for development
class MockParentRepository implements ParentRepository {
  final _uuid = const Uuid();
  final List<Parent> _parents = [];
  final List<ParentInvitation> _invitations = [];
  final List<ParentChildRelation> _relations = [];
  final List<ParentVisibilitySettings> _visibilitySettings = [];
  final List<ParentNotificationSettings> _notificationSettings = [];

  MockParentRepository() {
    _initMockData();
  }

  void _initMockData() {
    // No dummy data - users create their own parent relationships
  }

  // === Parent CRUD ===

  @override
  Future<List<Parent>> getParents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_parents);
  }

  @override
  Future<Parent?> getParent(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _parents.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Parent?> getParentByUserId(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _parents.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Parent> createParent(Parent parent) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newParent = parent.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _parents.add(newParent);
    return newParent;
  }

  @override
  Future<Parent> updateParent(Parent parent) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _parents.indexWhere((p) => p.id == parent.id);
    if (index == -1) {
      throw Exception('Parent not found');
    }
    final updated = parent.copyWith(updatedAt: DateTime.now());
    _parents[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteParent(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _parents.removeWhere((p) => p.id == id);
    // Also remove related data
    _relations.removeWhere((r) => r.parentId == id);
    _notificationSettings.removeWhere((n) => n.parentId == id);
  }

  // === Invitation ===

  @override
  Future<ParentInvitation> createInvitation(ParentInvitation invitation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newInvitation = invitation.copyWith(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    _invitations.add(newInvitation);
    return newInvitation;
  }

  @override
  Future<ParentInvitation?> getInvitationByCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _invitations.firstWhere((i) => i.invitationCode == code);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> markInvitationUsed(String invitationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index != -1) {
      _invitations[index] = _invitations[index].copyWith(isUsed: true);
    }
  }

  @override
  Future<List<ParentInvitation>> getPendingInvitationsForStudent(
      String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _invitations
        .where((i) => i.studentId == studentId && i.isValid)
        .toList();
  }

  // === Relations ===

  @override
  Future<List<ParentChildRelation>> getRelationsForParent(
      String parentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _relations.where((r) => r.parentId == parentId).toList();
  }

  @override
  Future<List<ParentChildRelation>> getRelationsForStudent(
      String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _relations.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<ParentChildRelation?> getRelation(
      String parentId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _relations.firstWhere(
          (r) => r.parentId == parentId && r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParentChildRelation> createRelation(
      ParentChildRelation relation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newRelation = relation.copyWith(
      id: _uuid.v4(),
      linkedAt: DateTime.now(),
    );
    _relations.add(newRelation);
    return newRelation;
  }

  @override
  Future<ParentChildRelation> updateRelation(
      ParentChildRelation relation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _relations.indexWhere((r) => r.id == relation.id);
    if (index == -1) {
      throw Exception('Relation not found');
    }
    _relations[index] = relation;
    return relation;
  }

  @override
  Future<void> deleteRelation(String relationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _relations.removeWhere((r) => r.id == relationId);
  }

  // === Visibility Settings ===

  @override
  Future<ParentVisibilitySettings?> getVisibilitySettings(
      String teacherId, String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _visibilitySettings.firstWhere(
          (s) => s.teacherId == teacherId && s.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParentVisibilitySettings> saveVisibilitySettings(
      ParentVisibilitySettings settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _visibilitySettings.indexWhere((s) =>
        s.teacherId == settings.teacherId &&
        s.studentId == settings.studentId);

    final updated = settings.copyWith(updatedAt: DateTime.now());
    if (index == -1) {
      final newSettings = updated.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );
      _visibilitySettings.add(newSettings);
      return newSettings;
    } else {
      _visibilitySettings[index] = updated;
      return updated;
    }
  }

  // === Notification Settings ===

  @override
  Future<ParentNotificationSettings?> getNotificationSettings(
      String parentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _notificationSettings.firstWhere((s) => s.parentId == parentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParentNotificationSettings> saveNotificationSettings(
      ParentNotificationSettings settings) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index =
        _notificationSettings.indexWhere((s) => s.parentId == settings.parentId);

    final updated = settings.copyWith(updatedAt: DateTime.now());
    if (index == -1) {
      final newSettings = updated.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );
      _notificationSettings.add(newSettings);
      return newSettings;
    } else {
      _notificationSettings[index] = updated;
      return updated;
    }
  }

  // === Billing ===

  @override
  Future<Parent?> getBillingTargetForStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final relation = _relations.firstWhere(
        (r) => r.studentId == studentId && r.isBillingTarget && r.isActive,
      );
      return _parents.firstWhere((p) => p.id == relation.parentId);
    } catch (_) {
      return null;
    }
  }
}
