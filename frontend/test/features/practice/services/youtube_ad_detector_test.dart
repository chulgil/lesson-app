import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/services/youtube_ad_detector.dart';

void main() {
  group('YoutubeAdDetector — §3.5 #509 (best effort)', () {
    test('starts with isAdPlaying false', () {
      final det = YoutubeAdDetector();
      expect(det.isAdPlaying, isFalse);
    });

    test('normal forward progress while playing does not flag an ad', () {
      final det = YoutubeAdDetector();
      det.observe(positionSeconds: 5.0, isPlaying: true);
      det.observe(positionSeconds: 6.0, isPlaying: true);
      det.observe(positionSeconds: 7.0, isPlaying: true);
      expect(det.isAdPlaying, isFalse);
    });

    test('not playing → does not flag an ad regardless of position', () {
      final det = YoutubeAdDetector();
      // Position resets to 0 while paused — should not trigger.
      det.observe(positionSeconds: 0.0, isPlaying: false);
      det.observe(positionSeconds: 0.0, isPlaying: false);
      det.observe(positionSeconds: 0.0, isPlaying: false);
      expect(det.isAdPlaying, isFalse);
    });

    test('two consecutive zero samples while playing → flags ad', () {
      final det = YoutubeAdDetector();
      // Establish prior position so the zero reset is mid-session.
      det.observe(positionSeconds: 42.0, isPlaying: true);
      // Reset to 0 while still playing → ad signal (1).
      det.observe(positionSeconds: 0.0, isPlaying: true);
      det.observe(positionSeconds: 0.1, isPlaying: true);
      expect(det.isAdPlaying, isTrue);
    });

    test('large backward jump while playing → flags ad', () {
      final det = YoutubeAdDetector();
      det.observe(positionSeconds: 42.0, isPlaying: true);
      // Jump backward by > 3s → mid-roll ad heuristic.
      det.observe(positionSeconds: 5.0, isPlaying: true);
      expect(det.isAdPlaying, isTrue);
    });

    test('large forward jump after ad clears the flag', () {
      final det = YoutubeAdDetector();
      det.observe(positionSeconds: 42.0, isPlaying: true);
      det.observe(positionSeconds: 0.0, isPlaying: true);
      det.observe(positionSeconds: 0.1, isPlaying: true);
      expect(det.isAdPlaying, isTrue);
      // Original video resumes far past the ad timeline.
      det.observe(positionSeconds: 45.0, isPlaying: true);
      expect(det.isAdPlaying, isFalse);
    });

    test('explicit seek does not get classified as an ad backward jump', () {
      final det = YoutubeAdDetector();
      det.observe(positionSeconds: 42.0, isPlaying: true);
      det.onExplicitSeek();
      // User-initiated seek back to loop start — must NOT flag.
      det.observe(positionSeconds: 10.0, isPlaying: true);
      expect(det.isAdPlaying, isFalse);
    });

    test('onResumeOrPause clears the ad flag', () {
      final det = YoutubeAdDetector();
      det.observe(positionSeconds: 42.0, isPlaying: true);
      det.observe(positionSeconds: 0.0, isPlaying: true);
      det.observe(positionSeconds: 0.0, isPlaying: true);
      expect(det.isAdPlaying, isTrue);

      det.onResumeOrPause();
      expect(det.isAdPlaying, isFalse);
    });

    test('single zero sample alone does not flag (needs consecutive)', () {
      final det = YoutubeAdDetector();
      det.observe(positionSeconds: 42.0, isPlaying: true);
      det.observe(positionSeconds: 0.0, isPlaying: true);
      // Recovered immediately — not enough for the heuristic.
      det.observe(positionSeconds: 42.5, isPlaying: true);
      expect(det.isAdPlaying, isFalse);
    });

    test('observe returns the current isAdPlaying value', () {
      final det = YoutubeAdDetector();
      final result1 = det.observe(positionSeconds: 5.0, isPlaying: true);
      expect(result1, isFalse);
      det.observe(positionSeconds: 42.0, isPlaying: true);
      final result2 = det.observe(positionSeconds: 5.0, isPlaying: true);
      // > 3s backward → ad flagged → observe returns true.
      expect(result2, isTrue);
    });
  });
}
