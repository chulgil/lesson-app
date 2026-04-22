import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/repositories/parent_repository.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/parent_child_relation.dart';
import '../../domain/entities/parent_notification_settings.dart';
import '../../domain/entities/parent_visibility_settings.dart';

/// Remote implementation of [ParentRepository] using FastAPI backend.
class RemoteParentRepository implements ParentRepository {
  final ApiClient _apiClient;

  RemoteParentRepository(this._apiClient);

  // ============================================================
  // Parent CRUD
  // ============================================================

  @override
  Future<List<Parent>> getParents() async {
    final response = await _apiClient.get('/parents');
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => _parentFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Parent?> getParent(String id) async {
    try {
      final response = await _apiClient.get('/parents/$id');
      return _parentFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Parent?> getParentByUserId(String userId) async {
    try {
      final response = await _apiClient.get('/parents/me');
      return _parentFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Parent> createParent(Parent parent) async {
    final response = await _apiClient.post(
      '/parents',
      data: _parentToJson(parent),
    );
    return _parentFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Parent> updateParent(Parent parent) async {
    final response = await _apiClient.put(
      '/parents/me',
      data: _parentToJson(parent),
    );
    return _parentFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteParent(String id) async {
    await _apiClient.delete('/parents/$id');
  }

  // ============================================================
  // Parent Invitation
  // ============================================================

  @override
  Future<ParentInvitation> createInvitation(ParentInvitation invitation) async {
    final response = await _apiClient.post(
      '/parents/invitations',
      data: _invitationToJson(invitation),
    );
    return _invitationFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ParentInvitation?> getInvitationByCode(String code) async {
    try {
      final response = await _apiClient.get(
        '/parents/invitations',
        queryParameters: {'code': code},
      );
      return _invitationFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> markInvitationUsed(String invitationId) async {
    await _apiClient.patch('/parents/invitations/$invitationId/use');
  }

  @override
  Future<List<ParentInvitation>> getPendingInvitationsForStudent(
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/parents/invitations',
      queryParameters: {'student_id': studentId, 'status': 'pending'},
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => _invitationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // Parent-Child Relations
  // ============================================================

  @override
  Future<List<ParentChildRelation>> getRelationsForParent(
    String parentId,
  ) async {
    final response = await _apiClient.get('/parents/me/children');
    final items = response.data as List<dynamic>;
    return items
        .map((e) => _relationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ParentChildRelation>> getRelationsForStudent(
    String studentId,
  ) async {
    final response = await _apiClient.get(
      '/parents/relations',
      queryParameters: {'student_id': studentId},
    );
    final items = response.data['items'] as List<dynamic>;
    return items
        .map((e) => _relationFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ParentChildRelation?> getRelation(
    String parentId,
    String studentId,
  ) async {
    final relations = await getRelationsForParent(parentId);
    try {
      return relations.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParentChildRelation> createRelation(
    ParentChildRelation relation,
  ) async {
    final response = await _apiClient.post(
      '/parents/me/children',
      data: {'invite_code': relation.studentId},
    );
    return _relationFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ParentChildRelation> updateRelation(
    ParentChildRelation relation,
  ) async {
    final response = await _apiClient.put(
      '/parents/relations/${relation.id}',
      data: _relationToJson(relation),
    );
    return _relationFromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRelation(String relationId) async {
    await _apiClient.delete('/parents/relations/$relationId');
  }

  // ============================================================
  // Visibility Settings
  // ============================================================

  @override
  Future<ParentVisibilitySettings?> getVisibilitySettings(
    String teacherId,
    String studentId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/parents/visibility-settings',
        queryParameters: {'teacher_id': teacherId, 'student_id': studentId},
      );
      return _visibilityFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParentVisibilitySettings> saveVisibilitySettings(
    ParentVisibilitySettings settings,
  ) async {
    final response = await _apiClient.put(
      '/parents/visibility-settings',
      data: _visibilityToJson(settings),
    );
    return _visibilityFromJson(response.data as Map<String, dynamic>);
  }

  // ============================================================
  // Notification Settings
  // ============================================================

  @override
  Future<ParentNotificationSettings?> getNotificationSettings(
    String parentId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/parents/notification-settings',
        queryParameters: {'parent_id': parentId},
      );
      return _notificationSettingsFromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ParentNotificationSettings> saveNotificationSettings(
    ParentNotificationSettings settings,
  ) async {
    final response = await _apiClient.put(
      '/parents/notification-settings',
      data: _notificationSettingsToJson(settings),
    );
    return _notificationSettingsFromJson(response.data as Map<String, dynamic>);
  }

  // ============================================================
  // Billing
  // ============================================================

  @override
  Future<Parent?> getBillingTargetForStudent(String studentId) async {
    try {
      final response = await _apiClient.get(
        '/parents/billing-target',
        queryParameters: {'student_id': studentId},
      );
      return _parentFromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Manual JSON helpers (entities don't have @JsonSerializable)
  // ============================================================

  Parent _parentFromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      profileColor: _parseColor(json['profile_color'] as String?),
      status: _parseParentStatus(json['status'] as String?),
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> _parentToJson(Parent parent) {
    return {
      'name': parent.name,
      'phone': parent.phone,
      'email': parent.email,
      'profile_image_url': parent.profileImageUrl,
      'profile_color': parent.profileColor.toARGB32().toRadixString(16),
    };
  }

  ParentInvitation _invitationFromJson(Map<String, dynamic> json) {
    return ParentInvitation(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String?,
      source: _parseInvitationSource(json['source'] as String?),
      parentPhone: json['parent_phone'] as String? ?? '',
      parentEmail: json['parent_email'] as String?,
      invitationCode: json['invitation_code'] as String? ?? '',
      expiresAt:
          json['expires_at'] != null
              ? DateTime.parse(json['expires_at'] as String)
              : DateTime.now().add(const Duration(days: 7)),
      isUsed: json['is_used'] as bool? ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> _invitationToJson(ParentInvitation invitation) {
    return {
      'student_id': invitation.studentId,
      'teacher_id': invitation.teacherId,
      'source': invitation.source.name,
      'parent_phone': invitation.parentPhone,
      'parent_email': invitation.parentEmail,
    };
  }

  ParentChildRelation _relationFromJson(Map<String, dynamic> json) {
    return ParentChildRelation(
      id: json['id'] as String,
      parentId: json['parent_id'] as String,
      studentId: json['student_id'] as String,
      isPrimaryGuardian: json['is_primary_guardian'] as bool? ?? true,
      isBillingTarget: json['is_billing_target'] as bool? ?? true,
      status: _parseRelationStatus(json['status'] as String?),
      linkedAt:
          json['linked_at'] != null
              ? DateTime.parse(json['linked_at'] as String)
              : DateTime.now(),
      unlinkedAt:
          json['unlinked_at'] != null
              ? DateTime.parse(json['unlinked_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> _relationToJson(ParentChildRelation relation) {
    return {
      'parent_id': relation.parentId,
      'student_id': relation.studentId,
      'is_primary_guardian': relation.isPrimaryGuardian,
      'is_billing_target': relation.isBillingTarget,
      'status': relation.status.name,
    };
  }

  ParentVisibilitySettings _visibilityFromJson(Map<String, dynamic> json) {
    return ParentVisibilitySettings(
      id: json['id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      studentId: json['student_id'] as String? ?? '',
      canViewSchedule: json['can_view_schedule'] as bool? ?? true,
      canViewAssignments: json['can_view_assignments'] as bool? ?? true,
      canViewPractice: json['can_view_practice'] as bool? ?? true,
      canViewLessonNotes: json['can_view_lesson_notes'] as bool? ?? true,
      canViewRecordings: json['can_view_recordings'] as bool? ?? false,
      canViewDetailedFeedback:
          json['can_view_detailed_feedback'] as bool? ?? false,
      canViewChat: json['can_view_chat'] as bool? ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> _visibilityToJson(ParentVisibilitySettings settings) {
    return {
      'teacher_id': settings.teacherId,
      'student_id': settings.studentId,
      'can_view_schedule': settings.canViewSchedule,
      'can_view_assignments': settings.canViewAssignments,
      'can_view_practice': settings.canViewPractice,
      'can_view_lesson_notes': settings.canViewLessonNotes,
      'can_view_recordings': settings.canViewRecordings,
      'can_view_detailed_feedback': settings.canViewDetailedFeedback,
      'can_view_chat': settings.canViewChat,
    };
  }

  ParentNotificationSettings _notificationSettingsFromJson(
    Map<String, dynamic> json,
  ) {
    return ParentNotificationSettings(
      id: json['id'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? '',
      paymentDueSoon: json['payment_due_soon'] as bool? ?? true,
      lessonChange: json['lesson_change'] as bool? ?? true,
      lessonCancel: json['lesson_cancel'] as bool? ?? true,
      lessonStart: json['lesson_start'] as bool? ?? false,
      lessonEnd: json['lesson_end'] as bool? ?? false,
      newAssignment: json['new_assignment'] as bool? ?? true,
      assignmentIncomplete: json['assignment_incomplete'] as bool? ?? true,
      practiceComplete: json['practice_complete'] as bool? ?? false,
      streakAchievement: json['streak_achievement'] as bool? ?? false,
      teacherMessage: json['teacher_message'] as bool? ?? true,
      lessonNoteUpdate: json['lesson_note_update'] as bool? ?? false,
      weeklyReport: json['weekly_report'] as bool? ?? true,
      monthlyReport: json['monthly_report'] as bool? ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
    );
  }

  Map<String, dynamic> _notificationSettingsToJson(
    ParentNotificationSettings settings,
  ) {
    return {
      'parent_id': settings.parentId,
      'payment_due_soon': settings.paymentDueSoon,
      'lesson_change': settings.lessonChange,
      'lesson_cancel': settings.lessonCancel,
      'lesson_start': settings.lessonStart,
      'lesson_end': settings.lessonEnd,
      'new_assignment': settings.newAssignment,
      'assignment_incomplete': settings.assignmentIncomplete,
      'practice_complete': settings.practiceComplete,
      'streak_achievement': settings.streakAchievement,
      'teacher_message': settings.teacherMessage,
      'lesson_note_update': settings.lessonNoteUpdate,
      'weekly_report': settings.weeklyReport,
      'monthly_report': settings.monthlyReport,
    };
  }

  Color _parseColor(String? value) {
    if (value == null) return AppColors.paperAccent;
    try {
      return Color(int.parse(value, radix: 16));
    } catch (_) {
      return AppColors.paperAccent;
    }
  }

  ParentStatus _parseParentStatus(String? value) {
    if (value == null) return ParentStatus.active;
    try {
      return ParentStatus.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return ParentStatus.active;
    }
  }

  InvitationSource _parseInvitationSource(String? value) {
    if (value == null) return InvitationSource.student;
    try {
      return InvitationSource.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return InvitationSource.student;
    }
  }

  ParentChildRelationStatus _parseRelationStatus(String? value) {
    if (value == null) return ParentChildRelationStatus.active;
    try {
      return ParentChildRelationStatus.values.firstWhere(
        (e) => e.name == value,
      );
    } catch (_) {
      return ParentChildRelationStatus.active;
    }
  }
}
