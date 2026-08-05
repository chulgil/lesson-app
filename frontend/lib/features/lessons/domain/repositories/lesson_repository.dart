import '../entities/cancellation_policy_hint.dart';
import '../entities/entities.dart';

/// Repository interface for managing lesson data
abstract class LessonRepository {
  Future<List<Lesson>> getLessons();
  Future<List<Lesson>> getLessonsByStudent(String studentId);
  Future<List<Lesson>> getLessonsByDate(DateTime date);
  Future<List<Lesson>> getLessonsByDateRange(DateTime start, DateTime end);
  Future<List<Lesson>> getUpcomingLessons({int limit = 10});
  Future<List<Lesson>> getRecentLessons({int limit = 10});
  Future<Lesson?> getLesson(String id);

  /// [overflowMode] — subscription_required_spec §2.6.2 explicit handling when
  /// the target subscription has no remaining sessions:
  /// 'bonus' | 'makeup_credit' | 'renewal_pending'. null = legacy behavior.
  Future<Lesson> createLesson(Lesson lesson, {String? overflowMode});

  /// Schedule-level edit only (instrument / date / time / duration / pieces /
  /// location). Status and feedback have dedicated endpoints — sending them
  /// here is rejected by the backend (#1238), since those writes carry side
  /// effects (subscription deduction, student notification).
  Future<Lesson> updateLesson(Lesson lesson);

  /// Status transitions (#1237). The backend runs the completion deduction and
  /// counterparty notifications here, so this is the ONLY valid path. Takes the
  /// entity so the offline queue can produce an optimistic value.
  Future<Lesson> updateLessonStatus(Lesson lesson, LessonStatus status);

  /// Lesson note write (#1236). An omitted argument leaves that field
  /// untouched; an empty list/string clears it.
  Future<Lesson> updateLessonFeedback(
    Lesson lesson, {
    String? feedback,
    List<String>? keyPoints,
    String? practiceTips,
  });

  /// #1241 — deadline facts for the pre-action hint. The server applies the
  /// same rule when the status arrives, so this is advisory only.
  Future<CancellationPolicyHint> getCancellationPolicy(String lessonId);

  Future<void> deleteLesson(String id);
  Future<void> cancelLesson(String id);
  Future<void> archiveLesson(String id);
  Future<void> unarchiveLesson(String id);
}
