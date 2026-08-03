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
  Future<Lesson> updateLesson(Lesson lesson);
  Future<void> deleteLesson(String id);
  Future<void> cancelLesson(String id);
  Future<void> archiveLesson(String id);
  Future<void> unarchiveLesson(String id);
}
