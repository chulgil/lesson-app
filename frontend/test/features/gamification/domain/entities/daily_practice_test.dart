import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice.dart';

void main() {
  group('DailyPractice', () {
    test('default 0 for all fields, totalMinutes = 0', () {
      const empty = DailyPractice();
      expect(empty.metronomeMinutes, 0);
      expect(empty.tunerMinutes, 0);
      expect(empty.youtubeMinutes, 0);
      expect(empty.recordingCount, 0);
      expect(empty.manualMinutes, 0);
      expect(empty.totalMinutes, 0);
    });

    test(
      'totalMinutes sums metronome + tuner + youtube + manual (excludes recordingCount)',
      () {
        const dp = DailyPractice(
          metronomeMinutes: 5,
          tunerMinutes: 3,
          youtubeMinutes: 10,
          recordingCount: 2,
          manualMinutes: 7,
        );
        expect(dp.totalMinutes, 25);
      },
    );

    test('copyWith updates only specified fields', () {
      const base = DailyPractice(metronomeMinutes: 5);
      final updated = base.copyWith(tunerMinutes: 3, recordingCount: 1);
      expect(updated.metronomeMinutes, 5);
      expect(updated.tunerMinutes, 3);
      expect(updated.recordingCount, 1);
      expect(updated.youtubeMinutes, 0);
      expect(updated.manualMinutes, 0);
    });

    test('json round-trip preserves all 5 fields', () {
      const base = DailyPractice(
        metronomeMinutes: 5,
        tunerMinutes: 3,
        youtubeMinutes: 10,
        recordingCount: 2,
        manualMinutes: 7,
      );
      final restored = DailyPractice.fromJson(base.toJson());
      expect(restored.metronomeMinutes, 5);
      expect(restored.tunerMinutes, 3);
      expect(restored.youtubeMinutes, 10);
      expect(restored.recordingCount, 2);
      expect(restored.manualMinutes, 7);
    });
  });
}
