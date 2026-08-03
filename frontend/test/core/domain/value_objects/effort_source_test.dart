import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/effort_source.dart';

void main() {
  group('EffortSource', () {
    test('enumerates music (discipline 0) effort sources in order', () {
      expect(EffortSource.values, const [
        EffortSource.metronome,
        EffortSource.tuner,
        EffortSource.youtube,
        EffortSource.recording,
        EffortSource.manual,
      ]);
    });
  });
}
