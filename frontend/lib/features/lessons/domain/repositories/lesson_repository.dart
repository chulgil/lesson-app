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
  Future<Lesson> createLesson(Lesson lesson);
  Future<Lesson> updateLesson(Lesson lesson);
  Future<void> deleteLesson(String id);
  Future<void> cancelLesson(String id);
  Future<void> archiveLesson(String id);
  Future<void> unarchiveLesson(String id);
}
