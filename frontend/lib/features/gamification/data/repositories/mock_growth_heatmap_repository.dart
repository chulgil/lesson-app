import '../../domain/entities/daily_practice.dart';
import '../../domain/entities/growth_heatmap.dart';
import '../../domain/repositories/growth_heatmap_repository.dart';

/// 메모리 기반 [GrowthHeatmapRepository] 구현.
///
/// 플랜 Job 2 Task 2.3 — P1 베타 출시 우선 (O2 결정: Hive 30일 chunk × 13
/// box 전략은 후속). 비동기 시뮬레이션 100ms.
class MockGrowthHeatmapRepository implements GrowthHeatmapRepository {
  final Map<String, Map<DateTime, DailyPractice>> _store = {};

  static const _latency = Duration(milliseconds: 100);

  DateTime _normalize(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  @override
  Future<GrowthHeatmap> getHeatmap(
    String studentId, {
    int yearsBack = 1,
  }) async {
    await Future.delayed(_latency);
    final cutoff = DateTime.now().toUtc().subtract(
      Duration(days: 365 * yearsBack),
    );
    final days = _store[studentId] ?? const <DateTime, DailyPractice>{};
    final filtered = <DateTime, DailyPractice>{
      for (final entry in days.entries)
        if (!entry.key.isBefore(cutoff)) entry.key: entry.value,
    };
    return GrowthHeatmap(studentId: studentId, days: filtered);
  }

  @override
  Future<void> recordPractice(
    String studentId,
    DateTime date,
    DailyPractice evidence,
  ) async {
    await Future.delayed(_latency);
    final key = _normalize(date);
    final perStudent = _store.putIfAbsent(studentId, () => {});
    final existing = perStudent[key] ?? const DailyPractice();
    perStudent[key] = DailyPractice(
      metronomeMinutes: existing.metronomeMinutes + evidence.metronomeMinutes,
      tunerMinutes: existing.tunerMinutes + evidence.tunerMinutes,
      youtubeMinutes: existing.youtubeMinutes + evidence.youtubeMinutes,
      recordingCount: existing.recordingCount + evidence.recordingCount,
      manualMinutes: existing.manualMinutes + evidence.manualMinutes,
    );
  }
}
