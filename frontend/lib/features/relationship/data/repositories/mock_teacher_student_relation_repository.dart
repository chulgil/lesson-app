import '../../domain/entities/notification_setting.dart';
import '../../domain/entities/relationship_status.dart';
import '../../domain/entities/teacher_student_relation.dart';
import '../../domain/repositories/teacher_student_relation_repository.dart';

/// Mock implementation of TeacherStudentRelationRepository.
class MockTeacherStudentRelationRepository
    implements TeacherStudentRelationRepository {
  final Map<String, TeacherStudentRelation> _relations = {};
  final Map<String, NotificationSetting> _notificationSettings = {};

  MockTeacherStudentRelationRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    final relations = [
      // ============================================================
      // Active students (with valid subscription)
      // ============================================================
      TeacherStudentRelation(
        id: 'rel_1',
        teacherId: 'teacher_1',
        studentId: 'student_1',
        status: RelationshipStatus.active,
        activeSubscriptionId: 'sub_1',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 5)),
        totalLessonCount: 12,
        lastLessonAt: now.subtract(const Duration(days: 7)),
      ),
      TeacherStudentRelation(
        id: 'rel_2',
        teacherId: 'teacher_1',
        studentId: 'student_2',
        status: RelationshipStatus.active,
        activeSubscriptionId: 'sub_2',
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 2)),
        totalLessonCount: 24,
        lastLessonAt: now.subtract(const Duration(days: 3)),
      ),

      // ============================================================
      // Trial booked (waiting for trial lesson)
      // ============================================================
      TeacherStudentRelation(
        id: 'rel_3',
        teacherId: 'teacher_1',
        studentId: 'student_3',
        status: RelationshipStatus.trialBooked,
        trialBookingId: 'booking_trial_1',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        totalLessonCount: 0,
      ),

      // ============================================================
      // Expired (within 30-day grace period) - with previous schedule
      // ============================================================
      TeacherStudentRelation(
        id: 'rel_4',
        teacherId: 'teacher_1',
        studentId: 'student_4',
        status: RelationshipStatus.expired,
        lastSubscriptionExpiredAt: now.subtract(const Duration(days: 14)),
        expiredUntil: now.add(const Duration(days: 16)),
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 14)),
        totalLessonCount: 32,
        lastLessonAt: now.subtract(const Duration(days: 21)),
        // Previous schedule for re-enrollment restoration
        lastLessonDay: 2, // 화요일
        lastLessonTime: '15:00',
        lastLessonDuration: 60,
        lastScheduleRecordedAt: now.subtract(const Duration(days: 21)),
      ),

      // ============================================================
      // Past (grace period ended) - with previous schedule
      // ============================================================
      TeacherStudentRelation(
        id: 'rel_5',
        teacherId: 'teacher_1',
        studentId: 'student_5',
        status: RelationshipStatus.past,
        lastSubscriptionExpiredAt: now.subtract(const Duration(days: 60)),
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now.subtract(const Duration(days: 30)),
        totalLessonCount: 48,
        lastLessonAt: now.subtract(const Duration(days: 65)),
        // Previous schedule for re-enrollment restoration
        lastLessonDay: 6, // 토요일
        lastLessonTime: '14:00',
        lastLessonDuration: 50,
        lastScheduleRecordedAt: now.subtract(const Duration(days: 65)),
      ),

      // ============================================================
      // Manually registered (offline student)
      // ============================================================
      TeacherStudentRelation(
        id: 'rel_6',
        teacherId: 'teacher_1',
        studentId: 'student_6',
        status: RelationshipStatus.active,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
        totalLessonCount: 8,
        lastLessonAt: now.subtract(const Duration(days: 7)),
        isManuallyRegistered: true,
        isAppConnected: false,
      ),
    ];

    for (final relation in relations) {
      _relations[relation.id] = relation;
    }

    // Initialize default notification settings
    final settings = [
      NotificationSetting.defaultSetting(
        userId: 'student_1',
        targetUserId: 'teacher_1',
      ),
      NotificationSetting.defaultSetting(
        userId: 'student_2',
        targetUserId: 'teacher_1',
      ),
    ];

    for (final setting in settings) {
      _notificationSettings[setting.id] = setting;
    }
  }

  // ============================================================
  // Query Methods
  // ============================================================

  @override
  Future<TeacherStudentRelation?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _relations[id];
  }

  @override
  Future<TeacherStudentRelation?> getRelation(
    String teacherId,
    String studentId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _relations.values.firstWhere(
        (r) => r.teacherId == teacherId && r.studentId == studentId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TeacherStudentRelation>> getByTeacher(String teacherId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _relations.values
        .where((r) => r.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<TeacherStudentRelation>> getByStudent(String studentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _relations.values
        .where((r) => r.studentId == studentId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<List<TeacherStudentRelation>> getByTeacherAndStatus(
    String teacherId,
    RelationshipStatus status,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _relations.values
        .where((r) => r.teacherId == teacherId && r.status == status)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
    await Future.delayed(const Duration(milliseconds: 100));
    return _relations.values
        .where((r) => r.teacherId == teacherId && r.isManuallyRegistered)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
    await Future.delayed(const Duration(milliseconds: 100));

    final newRelation = relation.id.isEmpty
        ? relation.copyWith(
            id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
          )
        : relation;

    _relations[newRelation.id] = newRelation;
    return newRelation;
  }

  @override
  Future<TeacherStudentRelation> update(TeacherStudentRelation relation) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (!_relations.containsKey(relation.id)) {
      throw Exception('Relation not found: ${relation.id}');
    }

    _relations[relation.id] = relation;
    return relation;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _relations.remove(id);
  }

  // ============================================================
  // Status Transition Methods
  // ============================================================

  @override
  Future<TeacherStudentRelation> onSubscriptionIssued({
    required String teacherId,
    required String studentId,
    required String subscriptionId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final relation = await getRelation(teacherId, studentId);
    final now = DateTime.now();

    if (relation == null) {
      // Create new relationship
      final newRelation = TeacherStudentRelation(
        id: 'rel_${now.millisecondsSinceEpoch}',
        teacherId: teacherId,
        studentId: studentId,
        status: RelationshipStatus.active,
        activeSubscriptionId: subscriptionId,
        createdAt: now,
        updatedAt: now,
      );
      return create(newRelation);
    } else {
      // Activate existing relationship
      final updated = relation.copyWith(
        status: RelationshipStatus.active,
        activeSubscriptionId: subscriptionId,
        expiredUntil: null,
        updatedAt: now,
      );
      return update(updated);
    }
  }

  @override
  Future<TeacherStudentRelation> onSubscriptionExpired({
    required String teacherId,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final relation = await getRelation(teacherId, studentId);
    if (relation == null) {
      throw Exception('Relation not found');
    }

    final now = DateTime.now();
    final expiredUntil = now.add(const Duration(days: 30));

    final updated = relation.copyWith(
      status: RelationshipStatus.expired,
      activeSubscriptionId: null,
      lastSubscriptionExpiredAt: now,
      expiredUntil: expiredUntil,
      updatedAt: now,
    );
    return update(updated);
  }

  @override
  Future<TeacherStudentRelation> onTrialBooked({
    required String teacherId,
    required String studentId,
    required String bookingId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final newRelation = TeacherStudentRelation(
      id: 'rel_${now.millisecondsSinceEpoch}',
      teacherId: teacherId,
      studentId: studentId,
      status: RelationshipStatus.trialBooked,
      trialBookingId: bookingId,
      createdAt: now,
      updatedAt: now,
    );
    return create(newRelation);
  }

  @override
  Future<void> onTrialCancelled({
    required String teacherId,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final relation = await getRelation(teacherId, studentId);
    if (relation?.status == RelationshipStatus.trialBooked) {
      await delete(relation!.id);
    }
  }

  @override
  Future<TeacherStudentRelation> onRelationshipTerminated({
    required String teacherId,
    required String studentId,
    required String terminatedBy,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final relation = await getRelation(teacherId, studentId);
    if (relation == null) {
      throw Exception('Relation not found');
    }

    final now = DateTime.now();
    final updated = relation.copyWith(
      status: RelationshipStatus.past,
      terminatedBy: terminatedBy,
      terminationReason: reason,
      updatedAt: now,
    );
    return update(updated);
  }

  @override
  Future<int> processExpiredToPast() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    int count = 0;

    for (final relation in _relations.values.toList()) {
      if (relation.status == RelationshipStatus.expired &&
          relation.expiredUntil != null &&
          now.isAfter(relation.expiredUntil!)) {
        final updated = relation.copyWith(
          status: RelationshipStatus.past,
          expiredUntil: null,
          updatedAt: now,
        );
        _relations[relation.id] = updated;
        count++;
      }
    }

    return count;
  }

  // ============================================================
  // Notification Settings
  // ============================================================

  @override
  Future<NotificationSetting?> getNotificationSetting(
    String userId,
    String targetUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));
    try {
      return _notificationSettings.values.firstWhere(
        (s) => s.userId == userId && s.targetUserId == targetUserId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<NotificationSetting> saveNotificationSetting(
    NotificationSetting setting,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notificationSettings[setting.id] = setting;
    return setting;
  }

  @override
  Future<void> deleteNotificationSetting(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _notificationSettings.remove(id);
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
    await Future.delayed(const Duration(milliseconds: 100));

    final relation = await getRelation(teacherId, studentId);
    if (relation == null) {
      throw Exception('Relation not found');
    }

    final updated = relation.copyWith(
      lastLessonDay: lessonDay,
      lastLessonTime: lessonTime,
      lastLessonDuration: lessonDuration ?? 60,
      lastScheduleRecordedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return update(updated);
  }

  @override
  Future<({int? lessonDay, String? lessonTime, int? lessonDuration})?>
      getPreviousSchedule({
    required String teacherId,
    required String studentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final relation = await getRelation(teacherId, studentId);
    if (relation == null || !relation.hasPreviousSchedule) {
      return null;
    }

    return (
      lessonDay: relation.lastLessonDay,
      lessonTime: relation.lastLessonTime,
      lessonDuration: relation.lastLessonDuration,
    );
  }
}
