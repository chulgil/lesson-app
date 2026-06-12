import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';
import 'package:lessonaza/features/gamification/domain/entities/growth_heatmap.dart';

void main() {
  DateTime utc(int y, int m, int d) => DateTime.utc(y, m, d);

  group('GrowthHeatmap.weekTotal', () {
    test('empty heatmap returns 0', () {
      final hm = GrowthHeatmap(studentId: 's1', days: const {});
      expect(hm.weekTotal(utc(2026, 6, 8)), 0);
    });

    test('sums totalMinutes of 7 consecutive days from weekStart', () {
      final hm = GrowthHeatmap(
        studentId: 's1',
        days: {
          utc(2026, 6, 8): const DailyPractice(metronomeMinutes: 5),
          utc(2026, 6, 9): const DailyPractice(tunerMinutes: 3),
          utc(2026, 6, 10): const DailyPractice(youtubeMinutes: 10),
          utc(2026, 6, 11): const DailyPractice(manualMinutes: 7),
          utc(2026, 6, 14): const DailyPractice(metronomeMinutes: 2),
          utc(2026, 6, 15): const DailyPractice(
            metronomeMinutes: 100,
          ), // 다음 주 — 제외
        },
      );
      // 6/8~6/14 = 5 + 3 + 10 + 7 + 0 + 0 + 2 = 27 (recordingCount 제외)
      expect(hm.weekTotal(utc(2026, 6, 8)), 27);
    });

    test(
      'recordingCount is excluded from totalMinutes (passthrough from DailyPractice)',
      () {
        final hm = GrowthHeatmap(
          studentId: 's1',
          days: {utc(2026, 6, 8): const DailyPractice(recordingCount: 100)},
        );
        expect(hm.weekTotal(utc(2026, 6, 8)), 0);
      },
    );
  });

  group('GrowthHeatmap.streakDays', () {
    test('empty heatmap returns 0', () {
      final hm = GrowthHeatmap(studentId: 's1', days: const {});
      expect(hm.streakDays(utc(2026, 6, 11)), 0);
    });

    test('counts consecutive days backward from asOf, breaks at gap', () {
      final hm = GrowthHeatmap(
        studentId: 's1',
        days: {
          utc(2026, 6, 11): const DailyPractice(metronomeMinutes: 5),
          utc(2026, 6, 10): const DailyPractice(tunerMinutes: 3),
          utc(2026, 6, 9): const DailyPractice(youtubeMinutes: 1),
          utc(2026, 6, 8): const DailyPractice(manualMinutes: 2),
          // 6/7 빠짐 → 스트릭 4
          utc(2026, 6, 6): const DailyPractice(metronomeMinutes: 5),
        },
      );
      expect(hm.streakDays(utc(2026, 6, 11)), 4);
    });

    test(
      'zero-minute day breaks streak (recordingCount alone does not count)',
      () {
        final hm = GrowthHeatmap(
          studentId: 's1',
          days: {
            utc(2026, 6, 11): const DailyPractice(metronomeMinutes: 5),
            utc(2026, 6, 10): const DailyPractice(
              recordingCount: 3,
            ), // totalMinutes=0
            utc(2026, 6, 9): const DailyPractice(metronomeMinutes: 5),
          },
        );
        expect(hm.streakDays(utc(2026, 6, 11)), 1);
      },
    );

    test('returns 0 if asOf day has no practice', () {
      final hm = GrowthHeatmap(
        studentId: 's1',
        days: {utc(2026, 6, 10): const DailyPractice(metronomeMinutes: 5)},
      );
      expect(hm.streakDays(utc(2026, 6, 11)), 0);
    });
  });

  group('GrowthHeatmap json round-trip', () {
    test('preserves studentId and days map (DateTime key as ISO8601)', () {
      final hm = GrowthHeatmap(
        studentId: 's1',
        days: {
          utc(2026, 6, 11): const DailyPractice(
            metronomeMinutes: 5,
            tunerMinutes: 3,
            youtubeMinutes: 10,
            recordingCount: 2,
            manualMinutes: 7,
          ),
          utc(2026, 6, 10): const DailyPractice(metronomeMinutes: 1),
        },
      );
      final restored = GrowthHeatmap.fromJson(hm.toJson());
      expect(restored.studentId, 's1');
      expect(restored.days.length, 2);
      expect(restored.days[utc(2026, 6, 11)]?.totalMinutes, 25);
      expect(restored.days[utc(2026, 6, 11)]?.recordingCount, 2);
      expect(restored.days[utc(2026, 6, 10)]?.metronomeMinutes, 1);
    });

    test('empty days map round-trips', () {
      final hm = GrowthHeatmap(studentId: 's1', days: const {});
      final restored = GrowthHeatmap.fromJson(hm.toJson());
      expect(restored.studentId, 's1');
      expect(restored.days, isEmpty);
    });
  });
}
