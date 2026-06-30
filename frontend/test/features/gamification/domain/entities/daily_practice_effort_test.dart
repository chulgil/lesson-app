import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/effort_source.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_practice_effort.dart';

void main() {
  group('EffortSourceDailyPractice.toDailyPractice', () {
    test('metronome -> metronomeMinutes only', () {
      final dp = EffortSource.metronome.toDailyPractice(5);
      expect(dp.metronomeMinutes, 5);
      expect(dp.totalMinutes, 5);
      expect(dp.tunerMinutes, 0);
      expect(dp.youtubeMinutes, 0);
      expect(dp.manualMinutes, 0);
      expect(dp.recordingCount, 0);
    });

    test('tuner -> tunerMinutes only', () {
      final dp = EffortSource.tuner.toDailyPractice(3);
      expect(dp.tunerMinutes, 3);
      expect(dp.totalMinutes, 3);
      expect(dp.metronomeMinutes, 0);
    });

    test('youtube -> youtubeMinutes only', () {
      final dp = EffortSource.youtube.toDailyPractice(10);
      expect(dp.youtubeMinutes, 10);
      expect(dp.totalMinutes, 10);
    });

    test('manual -> manualMinutes only', () {
      final dp = EffortSource.manual.toDailyPractice(7);
      expect(dp.manualMinutes, 7);
      expect(dp.totalMinutes, 7);
    });

    test('recording -> recordingCount 1, ignores amount, no minutes', () {
      final dp = EffortSource.recording.toDailyPractice(99);
      expect(dp.recordingCount, 1);
      expect(dp.totalMinutes, 0);
      expect(dp.metronomeMinutes, 0);
    });
  });
}
