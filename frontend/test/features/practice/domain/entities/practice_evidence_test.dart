import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_evidence.dart';

void main() {
  group('PracticeSource', () {
    test('has 5 values matching DailyPractice paths', () {
      expect(PracticeSource.values.length, 5);
      expect(
        PracticeSource.values,
        containsAll([
          PracticeSource.metronome,
          PracticeSource.tuner,
          PracticeSource.youtube,
          PracticeSource.recording,
          PracticeSource.manual,
        ]),
      );
    });
  });

  group('PracticeEvidence', () {
    test('exposes source / durationMinutes / occurredAt / metadata', () {
      final ev = PracticeEvidence(
        source: PracticeSource.metronome,
        durationMinutes: 5,
        occurredAt: DateTime(2026, 6, 11, 9, 30),
        metadata: const {'bpm': 100},
      );
      expect(ev.source, PracticeSource.metronome);
      expect(ev.durationMinutes, 5);
      expect(ev.occurredAt, DateTime(2026, 6, 11, 9, 30));
      expect(ev.metadata['bpm'], 100);
      expect(ev.videoId, isNull);
    });

    test('videoId can be set (youtube case)', () {
      final ev = PracticeEvidence(
        source: PracticeSource.youtube,
        durationMinutes: 10,
        occurredAt: DateTime(2026, 6, 11),
        metadata: const {},
        videoId: 'dQw4w9WgXcQ',
      );
      expect(ev.videoId, 'dQw4w9WgXcQ');
    });

    test('json round-trip preserves all fields', () {
      final ev = PracticeEvidence(
        source: PracticeSource.youtube,
        durationMinutes: 10,
        occurredAt: DateTime(2026, 6, 11, 9, 30),
        metadata: const {'bpm': 100, 'instrument': 'violin'},
        videoId: 'abc',
      );
      final restored = PracticeEvidence.fromJson(ev.toJson());
      expect(restored.source, PracticeSource.youtube);
      expect(restored.durationMinutes, 10);
      expect(restored.occurredAt, DateTime(2026, 6, 11, 9, 30));
      expect(restored.videoId, 'abc');
      expect(restored.metadata['bpm'], 100);
      expect(restored.metadata['instrument'], 'violin');
    });

    test('copyWith updates only specified fields', () {
      final base = PracticeEvidence(
        source: PracticeSource.metronome,
        durationMinutes: 5,
        occurredAt: DateTime(2026, 6, 11),
        metadata: const {},
      );
      final updated = base.copyWith(durationMinutes: 10);
      expect(updated.source, PracticeSource.metronome);
      expect(updated.durationMinutes, 10);
      expect(updated.occurredAt, DateTime(2026, 6, 11));
    });
  });
}
