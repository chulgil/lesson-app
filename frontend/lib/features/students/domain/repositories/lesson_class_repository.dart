import '../entities/lesson_class.dart';

/// Repository interface for LessonClass operations.
abstract class LessonClassRepository {
  /// Get all classes for a teacher.
  Future<List<LessonClass>> getByTeacherId(String teacherId);

  /// Get a single class by ID.
  Future<LessonClass?> getById(String id);

  /// Create a new class.
  Future<LessonClass> create(LessonClass lessonClass);

  /// Update an existing class.
  Future<LessonClass> update(LessonClass lessonClass);

  /// Archive a class (soft delete).
  Future<void> archive(String id);

  /// Restore an archived class.
  Future<void> restore(String id);

  /// Reorder classes.
  Future<void> reorder(List<String> orderedIds);

  /// Watch all classes for a teacher (stream).
  Stream<List<LessonClass>> watchByTeacherId(String teacherId);
}
