import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_loop_override.dart';
import 'package:lessonaza/features/practice/domain/value_objects/audio_mix_mode.dart';
import 'package:lessonaza/features/practice/domain/value_objects/practice_loop_speeds.dart';

void main() {
  group('PracticeLoopOverride — §3.2', () {
    final ts = DateTime(2026, 6, 4, 10, 0);

    test('default values are sane', () {
      final o = PracticeLoopOverride(
        sectionId: 'sec-1',
        studentUserId: 'stu-1',
        lastPlayedAt: ts,
      );
      expect(o.playbackSpeed, PracticeLoopSpeeds.defaultSpeed);
      expect(o.targetRepeatCount, 5);
      expect(o.completedRepeatCount, 0);
      expect(o.countInEnabled, false);
      expect(o.countInSoundEnabled, true);
      expect(o.audioMixMode, AudioMixMode.videoOnly);
      expect(o.hasOverride, false);
    });

    test('effective start/end falls back to teacher defaults', () {
      final o = PracticeLoopOverride(
        sectionId: 'sec-1',
        studentUserId: 'stu-1',
        lastPlayedAt: ts,
      );
      expect(o.effectiveStartSeconds(42), 42);
      expect(o.effectiveStartSeconds(null), 0);
      expect(o.effectiveEndSeconds(75), 75);
    });

    test('override values shadow teacher defaults', () {
      final o = PracticeLoopOverride(
        sectionId: 'sec-1',
        studentUserId: 'stu-1',
        overrideStartSeconds: 50,
        overrideEndSeconds: 65,
        lastPlayedAt: ts,
      );
      expect(o.effectiveStartSeconds(42), 50);
      expect(o.effectiveEndSeconds(75), 65);
      expect(o.hasOverride, true);
    });

    test('copyWith clearOverrideStart resets to null', () {
      final o = PracticeLoopOverride(
        sectionId: 'sec-1',
        studentUserId: 'stu-1',
        overrideStartSeconds: 50,
        overrideEndSeconds: 65,
        lastPlayedAt: ts,
      );
      final r = o.copyWith(clearOverrideStart: true, clearOverrideEnd: true);
      expect(r.overrideStartSeconds, isNull);
      expect(r.overrideEndSeconds, isNull);
      expect(r.hasOverride, false);
    });

    test('json round trip preserves all fields', () {
      final o = PracticeLoopOverride(
        sectionId: 'sec-1',
        studentUserId: 'stu-1',
        overrideStartSeconds: 30,
        overrideEndSeconds: 80,
        playbackSpeed: 0.75,
        targetRepeatCount: 8,
        completedRepeatCount: 3,
        countInEnabled: true,
        countInSoundEnabled: false,
        audioMixMode: AudioMixMode.headphoneOnly,
        lastPlayedAt: ts,
      );
      final json = o.toJson();
      final r = PracticeLoopOverride.fromJson(json);
      expect(r.sectionId, o.sectionId);
      expect(r.studentUserId, o.studentUserId);
      expect(r.overrideStartSeconds, 30);
      expect(r.overrideEndSeconds, 80);
      expect(r.playbackSpeed, 0.75);
      expect(r.targetRepeatCount, 8);
      expect(r.completedRepeatCount, 3);
      expect(r.countInEnabled, true);
      expect(r.countInSoundEnabled, false);
      expect(r.audioMixMode, AudioMixMode.headphoneOnly);
      expect(r.lastPlayedAt, ts);
    });
  });

  group('PracticeLoopSpeeds — §3.4', () {
    test('allowed speeds are exactly five', () {
      expect(PracticeLoopSpeeds.allowed.length, 5);
      expect(
        PracticeLoopSpeeds.allowed,
        containsAllInOrder([0.25, 0.5, 0.75, 1.0, 1.25]),
      );
    });

    test('isAllowed accepts canonical values', () {
      for (final s in PracticeLoopSpeeds.allowed) {
        expect(PracticeLoopSpeeds.isAllowed(s), true);
      }
      expect(PracticeLoopSpeeds.isAllowed(2.0), false);
    });

    test('clamp returns closest allowed', () {
      expect(PracticeLoopSpeeds.clamp(0.6), 0.5);
      expect(PracticeLoopSpeeds.clamp(0.9), 1.0);
      expect(PracticeLoopSpeeds.clamp(5.0), 1.25);
    });
  });

  group('AudioMixMode — §3.3', () {
    test('exactly 6 modes defined', () {
      expect(AudioMixMode.values.length, 6);
    });

    test('mode names are stable for serialization', () {
      expect(AudioMixMode.videoOnly.name, 'videoOnly');
      expect(AudioMixMode.headphoneOnly.name, 'headphoneOnly');
      expect(AudioMixMode.metronomeMixed.name, 'metronomeMixed');
    });
  });
}
