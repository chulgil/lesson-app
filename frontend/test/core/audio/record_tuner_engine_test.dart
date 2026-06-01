import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/audio/record_tuner_engine.dart';

void main() {
  test('record stream config uses the engine sample rate', () {
    final config = RecordTunerEngine.recordConfigFor(
      const RecordTunerConfig(sampleRate: 48000),
    );

    expect(config.sampleRate, 48000);
  });
}
