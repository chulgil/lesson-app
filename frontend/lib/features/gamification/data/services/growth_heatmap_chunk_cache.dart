import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/daily_practice.dart';

/// GrowthHeatmap 30일 chunk × 13 box 캐시 — 스펙 §17 P95<500ms 만족.
///
/// 플랜 Job 2 Task 2.1 / AC-2.
///
/// **저장 형식**: 단일 `Box<String>` (`growth_heatmap_v1`) +
/// 키 `heatmap_chunk_{studentId}_{chunkIndex}` + 값 JSON string.
///
/// **chunk 매핑**: epoch (1970-01-01 UTC) 기준 30일 단위. 같은 calendar day
/// 는 같은 chunk (time of day 무시).
///
/// **invalidation 격리**: `upsertDay` 호출 시 단일 chunk 만 write — 다른 12
/// chunk 의 raw bytes 변경 0.
class GrowthHeatmapChunkCache {
  GrowthHeatmapChunkCache({required Box<String> box}) : _box = box;

  /// Box name = `growth_heatmap_v1` (글로서리 §15 P2).
  static const String boxName = 'growth_heatmap_v1';

  /// 30일 = 1 chunk.
  static const int chunkSizeDays = 30;

  /// 13 chunk × 30일 = 390일 (1년 + 25일 버퍼).
  static const int chunkCount = 13;

  static final DateTime _epochUtc = DateTime.utc(1970, 1, 1);

  final Box<String> _box;

  /// [date] → chunk index (epoch 기준 30일 단위). time of day 무시.
  static int chunkIndex(DateTime date) {
    final utcDate = DateTime.utc(date.year, date.month, date.day);
    final daysSinceEpoch = utcDate.difference(_epochUtc).inDays;
    return daysSinceEpoch ~/ chunkSizeDays;
  }

  String _key(String studentId, int chunkIdx) =>
      'heatmap_chunk_${studentId}_$chunkIdx';

  Map<DateTime, DailyPractice> _decodeChunk(String? raw) {
    if (raw == null) return {};
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in json.entries)
          DateTime.parse(entry.key): DailyPractice.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      };
    } catch (_) {
      return {};
    }
  }

  String _encodeChunk(Map<DateTime, DailyPractice> chunk) => jsonEncode({
    for (final entry in chunk.entries)
      entry.key.toIso8601String(): entry.value.toJson(),
  });

  /// [asOf] 시점에서 직전 [chunkCount] 개 chunk 의 일별 데이터 병합 반환.
  ///
  /// 비기능 §17 — P95 < 500ms (Hive 로컬 + 13 box read).
  Future<Map<DateTime, DailyPractice>> loadYear(
    String studentId, {
    required DateTime asOf,
  }) async {
    final endChunk = chunkIndex(asOf);
    final startChunk = endChunk - chunkCount + 1;
    final merged = <DateTime, DailyPractice>{};
    for (var i = startChunk; i <= endChunk; i++) {
      final raw = _box.get(_key(studentId, i));
      merged.addAll(_decodeChunk(raw));
    }
    return merged;
  }

  /// [date] 의 chunk 만 write — 단일 chunk invalidation 격리 보장.
  ///
  /// 같은 chunk 의 다른 날 데이터는 보존, 같은 날 호출 시 덮어쓰기.
  Future<void> upsertDay(
    String studentId,
    DateTime date,
    DailyPractice evidence,
  ) async {
    final idx = chunkIndex(date);
    final key = _key(studentId, idx);
    final chunk = _decodeChunk(_box.get(key));
    final normDate = DateTime.utc(date.year, date.month, date.day);
    chunk[normDate] = evidence;
    await _box.put(key, _encodeChunk(chunk));
  }
}
