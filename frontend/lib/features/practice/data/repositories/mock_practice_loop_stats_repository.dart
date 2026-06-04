import '../../domain/entities/practice_loop_stats.dart';
import '../../domain/repositories/practice_loop_stats_repository.dart';

/// Mock repository for dev / offline preview (#512).
///
/// Stores in-memory rows keyed by student id — sufficient for the
/// dashboard preview + sync round-trip in DEV mode.
class MockPracticeLoopStatsRepository implements PracticeLoopStatsRepository {
  final Map<String, List<PracticeLoopStats>> _byStudent = {};

  @override
  Future<({int totalRepeats, List<PracticeLoopStats> rows})> listForStudent({
    required String studentId,
    required PracticeLoopStatsWindow window,
  }) async {
    final rows = List<PracticeLoopStats>.from(_byStudent[studentId] ?? const [])
      ..sort((a, b) => b.repeatCount.compareTo(a.repeatCount));
    final total = rows.fold<int>(0, (sum, r) => sum + r.repeatCount);
    return (totalRepeats: total, rows: rows);
  }

  @override
  Future<List<StudentRepeatStats>> summary({
    required PracticeLoopStatsWindow window,
  }) async {
    final summaries = <StudentRepeatStats>[];
    for (final entry in _byStudent.entries) {
      if (entry.value.isEmpty) continue;
      final total = entry.value.fold<int>(0, (s, r) => s + r.repeatCount);
      final last = entry.value
          .map((r) => r.lastPlayedAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      summaries.add(
        StudentRepeatStats(
          studentId: entry.key,
          studentName: null,
          totalRepeats: total,
          lastPlayedAt: last,
        ),
      );
    }
    summaries.sort((a, b) => b.totalRepeats.compareTo(a.totalRepeats));
    return summaries;
  }

  @override
  Future<PracticeLoopStatsSyncResult> syncStudent({
    required List<PendingLoopStatsSync> entries,
  }) async {
    // Mock mode treats every entry as a successful upsert.
    return PracticeLoopStatsSyncResult(upserted: entries.length);
  }
}
