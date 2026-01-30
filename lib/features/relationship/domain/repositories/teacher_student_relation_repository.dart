import '../entities/notification_setting.dart';
import '../entities/relationship_status.dart';
import '../entities/teacher_student_relation.dart';

/// Repository interface for teacher-student relationships.
///
/// Manages subscription-based relationships between teachers and students.
/// See: docs/specs/invite/subscription_based_relationship.md
abstract class TeacherStudentRelationRepository {
  // ============================================================
  // Query Methods
  // ============================================================

  /// Get relationship by ID
  Future<TeacherStudentRelation?> getById(String id);

  /// Get relationship between teacher and student
  Future<TeacherStudentRelation?> getRelation(
    String teacherId,
    String studentId,
  );

  /// Get all relationships for a teacher
  Future<List<TeacherStudentRelation>> getByTeacher(String teacherId);

  /// Get all relationships for a student
  Future<List<TeacherStudentRelation>> getByStudent(String studentId);

  /// Get relationships by status for a teacher
  Future<List<TeacherStudentRelation>> getByTeacherAndStatus(
    String teacherId,
    RelationshipStatus status,
  );

  /// Get active relationships for a teacher
  Future<List<TeacherStudentRelation>> getActiveByTeacher(String teacherId);

  /// Get expired relationships for a teacher
  Future<List<TeacherStudentRelation>> getExpiredByTeacher(String teacherId);

  /// Get past relationships for a teacher
  Future<List<TeacherStudentRelation>> getPastByTeacher(String teacherId);

  /// Get manually registered (offline) students for a teacher
  Future<List<TeacherStudentRelation>> getManuallyRegisteredByTeacher(
    String teacherId,
  );

  /// Get trial-booked relationships for a teacher
  Future<List<TeacherStudentRelation>> getTrialBookedByTeacher(
    String teacherId,
  );

  // ============================================================
  // Command Methods
  // ============================================================

  /// Create a new relationship
  Future<TeacherStudentRelation> create(TeacherStudentRelation relation);

  /// Update an existing relationship
  Future<TeacherStudentRelation> update(TeacherStudentRelation relation);

  /// Delete a relationship (only for cancelled trials)
  Future<void> delete(String id);

  // ============================================================
  // Status Transition Methods
  // ============================================================

  /// Handle subscription issued event
  /// Transitions to active status
  Future<TeacherStudentRelation> onSubscriptionIssued({
    required String teacherId,
    required String studentId,
    required String subscriptionId,
  });

  /// Handle subscription expired event
  /// Transitions to expired status with 30-day grace period
  Future<TeacherStudentRelation> onSubscriptionExpired({
    required String teacherId,
    required String studentId,
  });

  /// Handle trial booked event
  /// Creates relationship with trialBooked status
  Future<TeacherStudentRelation> onTrialBooked({
    required String teacherId,
    required String studentId,
    required String bookingId,
  });

  /// Handle trial cancelled event
  /// Deletes the relationship if only trial was booked
  Future<void> onTrialCancelled({
    required String teacherId,
    required String studentId,
  });

  /// Handle explicit relationship termination
  /// Transitions to past status
  Future<TeacherStudentRelation> onRelationshipTerminated({
    required String teacherId,
    required String studentId,
    required String terminatedBy,
    String? reason,
  });

  /// Process expired relationships to past (daily batch)
  /// Transitions expired relationships (30+ days) to past
  Future<int> processExpiredToPast();

  // ============================================================
  // Schedule Recording Methods (for re-enrollment restoration)
  // ============================================================

  /// Record/update the regular lesson schedule for a relationship.
  /// Called when regular lessons are confirmed or schedule is changed.
  Future<TeacherStudentRelation> recordSchedule({
    required String teacherId,
    required String studentId,
    required int lessonDay,
    required String lessonTime,
    int? lessonDuration,
  });

  /// Get the previous schedule for a student-teacher pair (if exists).
  /// Returns null if no previous schedule was recorded.
  Future<({int? lessonDay, String? lessonTime, int? lessonDuration})?>
      getPreviousSchedule({
    required String teacherId,
    required String studentId,
  });

  // ============================================================
  // Notification Settings
  // ============================================================

  /// Get notification setting for a relationship
  Future<NotificationSetting?> getNotificationSetting(
    String userId,
    String targetUserId,
  );

  /// Create or update notification setting
  Future<NotificationSetting> saveNotificationSetting(
    NotificationSetting setting,
  );

  /// Delete notification setting
  Future<void> deleteNotificationSetting(String id);
}
