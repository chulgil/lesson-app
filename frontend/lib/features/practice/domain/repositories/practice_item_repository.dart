import '../entities/practice_item.dart';

/// Repository interface for practice items (이번 주 연습)
abstract class PracticeItemRepository {
  /// Get all practice items for a lesson
  Future<List<PracticeItem>> getByLessonId(String lessonId);

  /// Get all practice items for a student
  Future<List<PracticeItem>> getByStudentId(String studentId);

  /// Get practice items for a student within a date range (for weekly view)
  Future<List<PracticeItem>> getByStudentIdAndDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get a single practice item by ID
  Future<PracticeItem?> getById(String id);

  /// Create a new practice item
  Future<PracticeItem> create(PracticeItem item);

  /// Update a practice item
  Future<PracticeItem> update(PracticeItem item);

  /// Delete a practice item
  Future<void> delete(String id);

  /// Toggle completion status
  Future<PracticeItem> toggleComplete(String id);

  /// Toggle like status (teacher feedback)
  Future<PracticeItem> toggleLike(String id);

  /// Increment practice count
  Future<PracticeItem> incrementCount(String id);

  /// Decrement practice count
  Future<PracticeItem> decrementCount(String id);

  /// Get incomplete items for a student (for dashboard)
  Future<List<PracticeItem>> getIncompleteByStudentId(String studentId);

  /// Get items awaiting teacher confirmation (completed but not liked)
  Future<List<PracticeItem>> getAwaitingFeedback(String teacherId);
}
