import '../../../../core/network/api_client.dart';
import '../../../../core/network/paginated_response.dart';
import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/relationship_status.dart';
import '../../domain/entities/teacher_student_relation.dart';
import '../../domain/repositories/teacher_student_relation_repository.dart';

/// Remote implementation of [TeacherStudentRelationRepository] using FastAPI backend.
///
/// Backend routes have no prefix — paths are `/relationships/...`.
class RemoteTeacherStudentRelationRepository
    implements TeacherStudentRelationRepository {
  final ApiClient _apiClient;

  RemoteTeacherStudentRelationRepository(this._apiClient);

  // ============================================================
  // Query Methods
  // ============================================================

  @override
  Future<TeacherStudentRelation?> getById(String id) async {
    final response = await _apiClient.get('/relationships/$id');
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<TeacherStudentRelation?> getRelation(
    String teacherId,
    String studentId,
  ) async {
    final all = await getByTeacher(teacherId);
    try {
      return all.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TeacherStudentRelation>> getByTeacher(String teacherId) async {
    final response = await _apiClient.get('/relationships');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TeacherStudentRelation.fromJson(json),
    );
    return paginated.items.where((r) => r.teacherId == teacherId).toList();
  }

  @override
  Future<List<TeacherStudentRelation>> getByStudent(String studentId) async {
    final response = await _apiClient.get('/relationships');
    final paginated = PaginatedResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => TeacherStudentRelation.fromJson(json),
    );
    return paginated.items.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<List<TeacherStudentRelation>> getByTeacherAndStatus(
    String teacherId,
    RelationshipStatus status,
  ) async {
    final all = await getByTeacher(teacherId);
    return all.where((r) => r.status == status).toList();
  }

  @override
  Future<List<TeacherStudentRelation>> getActiveByTeacher(
    String teacherId,
  ) async {
    return getByTeacherAndStatus(teacherId, RelationshipStatus.active);
  }

  @override
  Future<List<TeacherStudentRelation>> getExpiredByTeacher(
    String teacherId,
  ) async {
    return getByTeacherAndStatus(teacherId, RelationshipStatus.expired);
  }

  @override
  Future<List<TeacherStudentRelation>> getPastByTeacher(
    String teacherId,
  ) async {
    return getByTeacherAndStatus(teacherId, RelationshipStatus.past);
  }

  @override
  Future<List<TeacherStudentRelation>> getManuallyRegisteredByTeacher(
    String teacherId,
  ) async {
    final all = await getByTeacher(teacherId);
    return all.where((r) => r.isManuallyRegistered).toList();
  }

  @override
  Future<List<TeacherStudentRelation>> getTrialBookedByTeacher(
    String teacherId,
  ) async {
    return getByTeacherAndStatus(teacherId, RelationshipStatus.trialBooked);
  }

  // ============================================================
  // Command Methods
  // ============================================================

  @override
  Future<TeacherStudentRelation> create(TeacherStudentRelation relation) async {
    final response = await _apiClient.post(
      '/relationships/invite',
      data: {'student_id': relation.studentId, 'method': 'sms'},
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<TeacherStudentRelation> update(TeacherStudentRelation relation) async {
    final response = await _apiClient.patch(
      '/relationships/${relation.id}/status',
      data: {'status': relation.status.name},
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _apiClient.patch(
      '/relationships/$id/status',
      data: {'status': 'past'},
    );
  }

  // ============================================================
  // Status Transition Methods (server-side operations)
  // ============================================================

  @override
  Future<TeacherStudentRelation> onSubscriptionIssued({
    required String teacherId,
    required String studentId,
    required String subscriptionId,
  }) async {
    final relation = await getRelation(teacherId, studentId);
    if (relation == null) throw Exception('Relation not found');
    final response = await _apiClient.patch(
      '/relationships/${relation.id}/status',
      data: {'status': 'active', 'subscription_id': subscriptionId},
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<TeacherStudentRelation> onSubscriptionExpired({
    required String teacherId,
    required String studentId,
  }) async {
    final relation = await getRelation(teacherId, studentId);
    if (relation == null) throw Exception('Relation not found');
    final response = await _apiClient.patch(
      '/relationships/${relation.id}/status',
      data: {'status': 'expired'},
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<TeacherStudentRelation> onTrialBooked({
    required String teacherId,
    required String studentId,
    required String bookingId,
  }) async {
    final response = await _apiClient.post(
      '/relationships/invite',
      data: {'student_id': studentId, 'method': 'trial_booking'},
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<void> onTrialCancelled({
    required String teacherId,
    required String studentId,
  }) async {
    final relation = await getRelation(teacherId, studentId);
    if (relation != null) {
      await delete(relation.id);
    }
  }

  @override
  Future<TeacherStudentRelation> onRelationshipTerminated({
    required String teacherId,
    required String studentId,
    required String terminatedBy,
    String? reason,
  }) async {
    final relation = await getRelation(teacherId, studentId);
    if (relation == null) throw Exception('Relation not found');
    final response = await _apiClient.patch(
      '/relationships/${relation.id}/status',
      data: {'status': 'past'},
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<int> processExpiredToPast() async {
    // Server-side batch operation — no client-side action needed
    return 0;
  }

  // ============================================================
  // Schedule Recording Methods
  // ============================================================

  @override
  Future<TeacherStudentRelation> recordSchedule({
    required String teacherId,
    required String studentId,
    required int lessonDay,
    required String lessonTime,
    int? lessonDuration,
  }) async {
    final relation = await getRelation(teacherId, studentId);
    if (relation == null) throw Exception('Relation not found');
    final response = await _apiClient.patch(
      '/relationships/${relation.id}/status',
      data: {
        'last_lesson_day': lessonDay,
        'last_lesson_time': lessonTime,
        'last_lesson_duration': lessonDuration,
      },
    );
    return TeacherStudentRelation.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<({int? lessonDay, String? lessonTime, int? lessonDuration})?>
  getPreviousSchedule({
    required String teacherId,
    required String studentId,
  }) async {
    final relation = await getRelation(teacherId, studentId);
    if (relation == null || !relation.hasPreviousSchedule) return null;
    return (
      lessonDay: relation.lastLessonDay,
      lessonTime: relation.lastLessonTime,
      lessonDuration: relation.lastLessonDuration,
    );
  }

  // ============================================================
  // Notification Settings
  // ============================================================

  @override
  Future<NotificationSetting?> getNotificationSetting(
    String userId,
    String targetUserId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/relationships/notification-settings',
        queryParameters: {'user_id': userId, 'target_user_id': targetUserId},
      );
      return NotificationSetting.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<NotificationSetting> saveNotificationSetting(
    NotificationSetting setting,
  ) async {
    final response = await _apiClient.put(
      '/relationships/notification-settings',
      data: setting.toJson(),
    );
    return NotificationSetting.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteNotificationSetting(String id) async {
    await _apiClient.delete('/relationships/notification-settings/$id');
  }
}
