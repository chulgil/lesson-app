import 'package:hive/hive.dart';

import '../../domain/entities/daily_practice.dart';
import '../../domain/entities/growth_heatmap.dart';
import '../../domain/repositories/growth_heatmap_repository.dart';
import '../services/growth_heatmap_chunk_cache.dart';

/// Hive 기반 [GrowthHeatmapRepository] 구현 — Job 2 Task 2.2.
///
/// P1 의 [MockGrowthHeatmapRepository] 를 대체. 스펙 §17 P95 < 500ms 만족을
/// 위해 [GrowthHeatmapChunkCache] (30일 chunk × 13 box) 위에 구축.
///
/// **누적 합산 의미론**: 같은 날 [recordPractice] 호출 시 기존 evidence 의
/// 5 필드와 합산 (mock_growth_heatmap_repository 패리티). PracticeRecordingService
/// 가 evidence 1개씩 호출하는 단일 진입점 패턴 일관.
class HiveGrowthHeatmapRepository implements GrowthHeatmapRepository {
  HiveGrowthHeatmapRepository({required Box<String> box})
    : _cache = GrowthHeatmapChunkCache(box: box);

  final GrowthHeatmapChunkCache _cache;

  @override
  Future<GrowthHeatmap> getHeatmap(
    String studentId, {
    int yearsBack = 1,
  }) async {
    final days = await _cache.loadYear(studentId, asOf: DateTime.now());
    return GrowthHeatmap(studentId: studentId, days: days);
  }

  @override
  Future<void> recordPractice(
    String studentId,
    DateTime date,
    DailyPractice evidence,
  ) async {
    final normDate = DateTime.utc(date.year, date.month, date.day);
    final yearMap = await _cache.loadYear(studentId, asOf: DateTime.now());
    final existing = yearMap[normDate] ?? const DailyPractice();
    final merged = DailyPractice(
      metronomeMinutes: existing.metronomeMinutes + evidence.metronomeMinutes,
      tunerMinutes: existing.tunerMinutes + evidence.tunerMinutes,
      youtubeMinutes: existing.youtubeMinutes + evidence.youtubeMinutes,
      recordingCount: existing.recordingCount + evidence.recordingCount,
      manualMinutes: existing.manualMinutes + evidence.manualMinutes,
    );
    await _cache.upsertDay(studentId, normDate, merged);
  }
}
