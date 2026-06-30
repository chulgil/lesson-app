import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/effort_source.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_evidence.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_evidence_effort.dart';

void main() {
  group('PracticeSourceEffort.effortSource', () {
    test('maps each music source 1:1 to its EffortSource', () {
      expect(PracticeSource.metronome.effortSource, EffortSource.metronome);
      expect(PracticeSource.tuner.effortSource, EffortSource.tuner);
      expect(PracticeSource.youtube.effortSource, EffortSource.youtube);
      expect(PracticeSource.recording.effortSource, EffortSource.recording);
      expect(PracticeSource.manual.effortSource, EffortSource.manual);
    });

    test('every PracticeSource maps (total function, no gap)', () {
      for (final source in PracticeSource.values) {
        expect(source.effortSource, isA<EffortSource>());
      }
      expect(
        PracticeSource.values.map((s) => s.effortSource).toSet().length,
        PracticeSource.values.length,
      );
    });
  });
}
