// #495 — RecordingComparison entity unit tests (practice §4.5.3).

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_repertoire.dart';
import 'package:lessonaza/features/practice/domain/entities/recording_comparison.dart';

PracticeRecording _rec({
  required String id,
  required DateTime createdAt,
  int durationSeconds = 60,
  int? bpm,
}) {
  return PracticeRecording(
    id: id,
    sectionId: 'sec_1',
    filePath: '/tmp/$id.m4a',
    durationSeconds: durationSeconds,
    bpm: bpm,
    createdAt: createdAt,
  );
}

void main() {
  group('RecordingComparison', () {
    final a = _rec(
      id: 'a',
      createdAt: DateTime(2026, 5, 1),
      durationSeconds: 60,
      bpm: 96,
    );
    final b = _rec(
      id: 'b',
      createdAt: DateTime(2026, 5, 8),
      durationSeconds: 75,
      bpm: 120,
    );

    test('default status is paused', () {
      final cmp = RecordingComparison(recordingA: a, recordingB: b);
      expect(cmp.status, RecordingComparisonStatus.paused);
    });

    test('bpmDelta = B.bpm - A.bpm when both present', () {
      final cmp = RecordingComparison(recordingA: a, recordingB: b);
      expect(cmp.bpmDelta, 24);
      expect(cmp.bpmChangePercent, closeTo(25.0, 0.01));
    });

    test('bpmDelta is null when either side lacks bpm', () {
      final aNoBpm = _rec(id: 'a2', createdAt: DateTime(2026, 5, 1));
      final cmp = RecordingComparison(recordingA: aNoBpm, recordingB: b);
      expect(cmp.bpmDelta, isNull);
      expect(cmp.bpmChangePercent, isNull);
    });

    test('durationDelta = B - A seconds', () {
      final cmp = RecordingComparison(recordingA: a, recordingB: b);
      expect(cmp.durationDelta, 15);
    });

    test('daysBetween reflects calendar gap', () {
      final cmp = RecordingComparison(recordingA: a, recordingB: b);
      expect(cmp.daysBetween, 7);
    });

    test('copyWith updates only provided fields and preserves the rest', () {
      final base = RecordingComparison(recordingA: a, recordingB: b);
      final playing = base.copyWith(status: RecordingComparisonStatus.playing);
      expect(playing.status, RecordingComparisonStatus.playing);
      expect(playing.recordingA, a);
      expect(playing.recordingB, b);
      // Original instance is not mutated.
      expect(base.status, RecordingComparisonStatus.paused);
    });

    test('equality compares all fields', () {
      final c1 = RecordingComparison(recordingA: a, recordingB: b);
      final c2 = RecordingComparison(recordingA: a, recordingB: b);
      final c3 = c1.copyWith(status: RecordingComparisonStatus.playing);
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1, isNot(c3));
    });
  });
}
