import '../entities/practice_loop_stats.dart';

/// Remote read API for teacher-side practice loop stats (#512).
///
/// Spec: docs/specs/practice/youtube_loop_practice_spec.md §4.
abstract class PracticeLoopStatsRepository {
  /// Per-section rows for a specific student.
  Future<({int totalRepeats, List<PracticeLoopStats> rows})> listForStudent({
    required String studentId,
    required PracticeLoopStatsWindow window,
  });

  /// Dashboard summary across all of the teacher's students.
  Future<List<StudentRepeatStats>> summary({
    required PracticeLoopStatsWindow window,
  });

  /// Idempotent batch upload of (section, count, lastPlayedAt) rows.
  /// Used by the offline sync queue (#512).
  Future<PracticeLoopStatsSyncResult> syncStudent({
    required List<PendingLoopStatsSync> entries,
  });
}
