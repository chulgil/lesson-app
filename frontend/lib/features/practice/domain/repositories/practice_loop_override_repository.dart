import '../entities/practice_loop_override.dart';

/// Repository interface for storing student-side YouTube loop overrides.
///
/// Implementation: Hive-backed, user-scoped key `{studentUserId}:{sectionId}`.
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §5.1
abstract class PracticeLoopOverrideRepository {
  /// Returns the override for ([studentUserId], [sectionId]) or null.
  Future<PracticeLoopOverride?> findFor({
    required String studentUserId,
    required String sectionId,
  });

  /// Upserts an override.
  Future<void> save(PracticeLoopOverride override);

  /// Deletes the override (resets to teacher default).
  Future<void> delete({
    required String studentUserId,
    required String sectionId,
  });

  /// Returns all overrides for a student (e.g. for migration or cleanup).
  Future<List<PracticeLoopOverride>> findAllForStudent(String studentUserId);
}
