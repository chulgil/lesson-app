import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/data/services/growth_heatmap_chunk_cache.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_heatmap_repo_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(GrowthHeatmapChunkCache.boxName);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(GrowthHeatmapChunkCache.boxName);
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveGrowthHeatmapRepository', () {
    test('빈 box → empty GrowthHeatmap (AC-3.3 parity)', () async {
      final repo = HiveGrowthHeatmapRepository(box: box);
      final heatmap = await repo.getHeatmap('s1');
      expect(heatmap.studentId, 's1');
      expect(heatmap.days, isEmpty);
    });

    test('recordPractice → getHeatmap round-trip', () async {
      final repo = HiveGrowthHeatmapRepository(box: box);
      final today = DateTime.utc(2026, 6, 12);

      await repo.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 25),
      );

      final heatmap = await repo.getHeatmap('s1');
      expect(heatmap.days.length, 1);
      expect(heatmap.days.values.single.metronomeMinutes, 25);
    });

    test('같은 날 recordPractice 누적 합산 (mock 패리티)', () async {
      final repo = HiveGrowthHeatmapRepository(box: box);
      final today = DateTime.utc(2026, 6, 12);

      await repo.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 10),
      );
      await repo.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 15, tunerMinutes: 5),
      );

      final heatmap = await repo.getHeatmap('s1');
      expect(heatmap.days.length, 1);
      final entry = heatmap.days.values.single;
      expect(entry.metronomeMinutes, 25, reason: '10+15 누적');
      expect(entry.tunerMinutes, 5);
    });

    test('여러 날 데이터 → getHeatmap 정확 반환', () async {
      final repo = HiveGrowthHeatmapRepository(box: box);
      final today = DateTime.utc(2026, 6, 12);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastMonth = today.subtract(const Duration(days: 35));

      await repo.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 10),
      );
      await repo.recordPractice(
        's1',
        yesterday,
        const DailyPractice(tunerMinutes: 15),
      );
      await repo.recordPractice(
        's1',
        lastMonth,
        const DailyPractice(youtubeMinutes: 20),
      );

      final heatmap = await repo.getHeatmap('s1');
      expect(heatmap.days.length, 3);
    });

    test('학생 격리 — s1 데이터는 s2 조회에 안 들어감', () async {
      final repo = HiveGrowthHeatmapRepository(box: box);
      final today = DateTime.utc(2026, 6, 12);

      await repo.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 50),
      );
      await repo.recordPractice(
        's2',
        today,
        const DailyPractice(tunerMinutes: 30),
      );

      final s1 = await repo.getHeatmap('s1');
      final s2 = await repo.getHeatmap('s2');
      expect(s1.days.values.single.metronomeMinutes, 50);
      expect(s2.days.values.single.tunerMinutes, 30);
    });

    test('영속성 — 새 repository 인스턴스에서도 read 가능', () async {
      final today = DateTime.utc(2026, 6, 12);
      final repo1 = HiveGrowthHeatmapRepository(box: box);
      await repo1.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 42),
      );

      final repo2 = HiveGrowthHeatmapRepository(box: box);
      final heatmap = await repo2.getHeatmap('s1');
      expect(heatmap.days.values.single.metronomeMinutes, 42);
    });

    test('yearsBack 파라미터 — 1년 이상 데이터는 제외', () async {
      final repo = HiveGrowthHeatmapRepository(box: box);
      final today = DateTime.utc(2026, 6, 12);
      final tooOld = today.subtract(const Duration(days: 400));

      await repo.recordPractice(
        's1',
        today,
        const DailyPractice(metronomeMinutes: 10),
      );
      await repo.recordPractice(
        's1',
        tooOld,
        const DailyPractice(metronomeMinutes: 99),
      );

      final heatmap = await repo.getHeatmap('s1', yearsBack: 1);
      expect(heatmap.days.length, 1, reason: '1년 이전 데이터는 chunk cutoff 으로 제외');
    });
  });
}
