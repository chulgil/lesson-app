import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/services/practice_audio_mix_service.dart';
import 'package:lessonaza/features/practice/domain/value_objects/audio_mix_mode.dart';

void main() {
  group('AudioMixModePolicy — §5.3', () {
    test('videoOnly does not require recording path', () {
      expect(
        AudioMixModePolicy.requiresRecordingPath(AudioMixMode.videoOnly),
        false,
      );
    });

    test('all recording modes require recording path', () {
      const recording = [
        AudioMixMode.recordOnly,
        AudioMixMode.mixed,
        AudioMixMode.videoMuted,
        AudioMixMode.headphoneOnly,
        AudioMixMode.metronomeMixed,
      ];
      for (final m in recording) {
        expect(
          AudioMixModePolicy.requiresRecordingPath(m),
          true,
          reason: m.name,
        );
      }
    });

    test('mixed, headphoneOnly, metronomeMixed recommend headphones', () {
      expect(AudioMixModePolicy.recommendsHeadphones(AudioMixMode.mixed), true);
      expect(
        AudioMixModePolicy.recommendsHeadphones(AudioMixMode.headphoneOnly),
        true,
      );
      expect(
        AudioMixModePolicy.recommendsHeadphones(AudioMixMode.metronomeMixed),
        true,
      );
    });

    test('videoMuted requests player volume 0', () {
      expect(
        AudioMixModePolicy.videoShouldBeMuted(AudioMixMode.videoMuted),
        true,
      );
      expect(AudioMixModePolicy.videoShouldBeMuted(AudioMixMode.mixed), false);
    });

    test('recordOnly pauses the video', () {
      expect(
        AudioMixModePolicy.videoShouldBePaused(AudioMixMode.recordOnly),
        true,
      );
      expect(
        AudioMixModePolicy.videoShouldBePaused(AudioMixMode.videoOnly),
        false,
      );
    });
  });
}
