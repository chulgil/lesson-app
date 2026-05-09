import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/audio/audio_trimmer_service.dart';
import 'package:lessonaza/features/practice/domain/entities/smart_recording.dart';

void main() {
  group('AudioTrimmerService.calculatePlayableDuration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'audio_trimmer_service_test_',
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<String> createAudioFixture({Map<String, dynamic>? metadata}) async {
      final audioFile = File('${tempDir.path}/audio.m4a');
      await audioFile.writeAsString('fixture');

      if (metadata != null) {
        final trimFile = File('${audioFile.path}.trim');
        await trimFile.writeAsString(jsonEncode(metadata));
      }

      return audioFile.path;
    }

    test('uses metadata effective duration when metadata exists', () async {
      final filePath = await createAudioFixture(
        metadata: {
          'trimStart': 1000,
          'trimEnd': 1000,
          'totalDuration': 6000,
          'contentStart': 1000,
          'contentEnd': 5500,
          'segments': [
            {'start': 1000, 'end': 2800},
            {'start': 3200, 'end': 4700},
          ],
        },
      );

      final duration = await AudioTrimmerService.instance
          .calculatePlayableDuration(
            filePath: filePath,
            totalDuration: const Duration(seconds: 6),
            trimmedStart: const Duration(milliseconds: 1000),
            trimmedEnd: const Duration(milliseconds: 1000),
            middleSilencePeriods: const [],
          );

      expect(duration, const Duration(milliseconds: 3300));
    });

    test(
      'falls back to arithmetic and clamps middle silence to content range',
      () async {
        final filePath = await createAudioFixture();

        final duration = await AudioTrimmerService.instance
            .calculatePlayableDuration(
              filePath: filePath,
              totalDuration: const Duration(seconds: 6),
              trimmedStart: const Duration(seconds: 1),
              trimmedEnd: const Duration(seconds: 1),
              middleSilencePeriods: const [
                SilencePeriod(
                  startTime: Duration(seconds: -1),
                  endTime: Duration(seconds: 2),
                ),
                SilencePeriod(
                  startTime: Duration(seconds: 5),
                  endTime: Duration(seconds: 8),
                ),
              ],
            );

        // Content window: 1s~5s, middle silence clipped to 1s~2s (1s) and 5s~5s (0s)
        // Base duration: 6 - 1 - 1 - 1 = 3 seconds.
        expect(duration, const Duration(seconds: 3));
      },
    );

    test('returns zero when trimmed duration is impossible', () async {
      final filePath = await createAudioFixture();

      final duration = await AudioTrimmerService.instance
          .calculatePlayableDuration(
            filePath: filePath,
            totalDuration: const Duration(seconds: 3),
            trimmedStart: const Duration(seconds: 2),
            trimmedEnd: const Duration(seconds: 2),
            middleSilencePeriods: const [],
          );

      expect(duration, Duration.zero);
    });
  });
}
