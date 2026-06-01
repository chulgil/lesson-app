import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/audio/pitch_detection/stability_filter.dart';

void main() {
  test('frequencyTolerance controls whether adjacent frames are stable', () {
    final filter = StabilityFilter(
      config: const StabilityConfig(
        minProbability: 0.7,
        stabilityFrames: 2,
        frequencyTolerance: 1,
      ),
    );

    final first = filter.process(
      frequency: 440,
      probability: 0.95,
      pitched: true,
    );
    final second = filter.process(
      frequency: 443,
      probability: 0.95,
      pitched: true,
    );

    expect(first.isStable, isFalse);
    expect(second.isStable, isFalse);
  });

  test('adjacent low notes are not treated as stable within hz tolerance', () {
    final filter = StabilityFilter(
      config: const StabilityConfig(
        minProbability: 0.7,
        stabilityFrames: 2,
        frequencyTolerance: 5,
      ),
    );

    filter.process(frequency: 82.41, probability: 0.95, pitched: true);
    final adjacentSemitone = filter.process(
      frequency: 87.31,
      probability: 0.95,
      pitched: true,
    );

    expect(adjacentSemitone.isStable, isFalse);
  });
}
