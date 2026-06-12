import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_growth_heatmap_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';

void main() {
  DateTime utc(int y, int m, int d) => DateTime.utc(y, m, d);

  late MockGrowthHeatmapRepository repo;

  setUp(() {
    repo = MockGrowthHeatmapRepository();
  });

  group('getHeatmap', () {
    test('returns empty heatmap when no records exist', () async {
      final hm = await repo.getHeatmap('s1');
      expect(hm.studentId, 's1');
      expect(hm.days, isEmpty);
    });

    test('returns recorded days for the student', () async {
      await repo.recordPractice(
        's1',
        utc(2026, 6, 11),
        const DailyPractice(metronomeMinutes: 5),
      );
      final hm = await repo.getHeatmap('s1');
      expect(hm.days[utc(2026, 6, 11)]?.metronomeMinutes, 5);
    });

    test('does not leak between students', () async {
      await repo.recordPractice(
        's1',
        utc(2026, 6, 11),
        const DailyPractice(metronomeMinutes: 5),
      );
      final other = await repo.getHeatmap('s2');
      expect(other.days, isEmpty);
    });
  });

  group('recordPractice — same-day accumulation', () {
    test('5 fields accumulate when called multiple times same date', () async {
      await repo.recordPractice(
        's1',
        utc(2026, 6, 11),
        const DailyPractice(metronomeMinutes: 5),
      );
      await repo.recordPractice(
        's1',
        utc(2026, 6, 11),
        const DailyPractice(tunerMinutes: 3, recordingCount: 1),
      );
      await repo.recordPractice(
        's1',
        utc(2026, 6, 11),
        const DailyPractice(youtubeMinutes: 10, manualMinutes: 2),
      );
      final hm = await repo.getHeatmap('s1');
      final cell = hm.days[utc(2026, 6, 11)];
      expect(cell?.metronomeMinutes, 5);
      expect(cell?.tunerMinutes, 3);
      expect(cell?.youtubeMinutes, 10);
      expect(cell?.recordingCount, 1);
      expect(cell?.manualMinutes, 2);
      expect(cell?.totalMinutes, 20); // recordingCount 제외
    });

    test('different dates remain separate cells', () async {
      await repo.recordPractice(
        's1',
        utc(2026, 6, 11),
        const DailyPractice(metronomeMinutes: 5),
      );
      await repo.recordPractice(
        's1',
        utc(2026, 6, 12),
        const DailyPractice(metronomeMinutes: 7),
      );
      final hm = await repo.getHeatmap('s1');
      expect(hm.days[utc(2026, 6, 11)]?.metronomeMinutes, 5);
      expect(hm.days[utc(2026, 6, 12)]?.metronomeMinutes, 7);
    });
  });

  group('getHeatmap — yearsBack window', () {
    test('filters cells older than (now - yearsBack)', () async {
      await repo.recordPractice(
        's1',
        utc(2024, 1, 1),
        const DailyPractice(metronomeMinutes: 5),
      );
      await repo.recordPractice(
        's1',
        DateTime.now().toUtc(),
        const DailyPractice(metronomeMinutes: 5),
      );
      final hm = await repo.getHeatmap('s1', yearsBack: 1);
      // 2024-01-01 은 1년 이전 (테스트 시점이 2026-06 가정) — 제외
      expect(
        hm.days.keys.any((d) => d.year == 2024 && d.month == 1 && d.day == 1),
        false,
      );
      expect(hm.days.length, 1);
    });
  });
}
