import '../entities/lesson_location.dart';

/// Repository interface for LessonLocation operations.
abstract class LocationRepository {
  /// Get all locations for a class.
  Future<List<LessonLocation>> getByClassId(String classId);

  /// Get all locations owned by a teacher.
  Future<List<LessonLocation>> getByOwnerId(String ownerId);

  /// Get a single location by ID.
  Future<LessonLocation?> getById(String id);

  /// Create a new location.
  Future<LessonLocation> create(LessonLocation location);

  /// Update an existing location.
  Future<LessonLocation> update(LessonLocation location);

  /// Set a location as default for a class.
  Future<void> setDefault(String id, String classId);

  /// Deactivate a location (soft delete).
  Future<void> deactivate(String id);

  /// Reactivate a location.
  Future<void> reactivate(String id);

  /// Watch all locations for a class (stream).
  Stream<List<LessonLocation>> watchByClassId(String classId);

  /// Watch all locations owned by a teacher (stream).
  Stream<List<LessonLocation>> watchByOwnerId(String ownerId);
}
