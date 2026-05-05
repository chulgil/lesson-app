import '../entities/recording.dart';

/// Repository for managing recording data with local storage.
abstract class RecordingRepository {
  /// Get all recordings for a repertoire.
  Future<List<Recording>> getRecordingsForRepertoire(String repertoireId);

  /// Get all recordings for a student.
  Future<List<Recording>> getRecordingsForStudent(String studentId);

  /// Get a recording by ID.
  Future<Recording?> getRecording(String id);

  /// Get the representative recording for a repertoire.
  Future<Recording?> getRepresentativeRecording(String repertoireId);

  /// Save a recording.
  Future<void> saveRecording(Recording recording);

  /// Delete a recording.
  Future<void> deleteRecording(String id);

  /// Set a recording as representative.
  Future<void> setRepresentative(String id);

  /// Clear representative status for a repertoire.
  Future<void> clearRepresentative(String repertoireId);

  /// Mark recording as shared.
  Future<void> markAsShared(String id);

  /// Clean up orphaned recordings (DB entries without actual files).
  /// Returns the number of cleaned up recordings.
  Future<int> cleanupOrphanedRecordings();

  /// Migrate and recover recording paths.
  /// Tries to fix paths that became invalid due to container UUID changes.
  /// Returns the number of recovered recordings.
  Future<int> migrateAndRecoverPaths();
}
