import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/practice/data/repositories/hive_practice_loop_override_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_loop_override.dart';
import 'package:lessonaza/features/practice/domain/value_objects/audio_mix_mode.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_loop_override_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HivePracticeLoopOverrideRepository.boxName);
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HivePracticeLoopOverrideRepository — §5.1', () {
    test('returns null when no override exists', () async {
      final repo = HivePracticeLoopOverrideRepository();
      final result = await repo.findFor(
        studentUserId: 'stu-1',
        sectionId: 'sec-1',
      );
      expect(result, isNull);
    });

    test('save then findFor round trips', () async {
      final repo = HivePracticeLoopOverrideRepository();
      final o = PracticeLoopOverride(
        sectionId: 'sec-1',
        studentUserId: 'stu-1',
        overrideStartSeconds: 30,
        overrideEndSeconds: 60,
        playbackSpeed: 0.75,
        targetRepeatCount: 8,
        audioMixMode: AudioMixMode.headphoneOnly,
        lastPlayedAt: DateTime(2026, 6, 4),
      );
      await repo.save(o);
      final result = await repo.findFor(
        studentUserId: 'stu-1',
        sectionId: 'sec-1',
      );
      expect(result, isNotNull);
      expect(result!.overrideStartSeconds, 30);
      expect(result.overrideEndSeconds, 60);
      expect(result.playbackSpeed, 0.75);
      expect(result.audioMixMode, AudioMixMode.headphoneOnly);
    });

    test('different students are isolated by scoped key', () async {
      final repo = HivePracticeLoopOverrideRepository();
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-A',
          overrideStartSeconds: 10,
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      );
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-B',
          overrideStartSeconds: 99,
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      );
      final a = await repo.findFor(studentUserId: 'stu-A', sectionId: 'sec-1');
      final b = await repo.findFor(studentUserId: 'stu-B', sectionId: 'sec-1');
      expect(a!.overrideStartSeconds, 10);
      expect(b!.overrideStartSeconds, 99);
    });

    test('delete removes the override', () async {
      final repo = HivePracticeLoopOverrideRepository();
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-1',
          overrideStartSeconds: 10,
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      );
      await repo.delete(studentUserId: 'stu-1', sectionId: 'sec-1');
      final result = await repo.findFor(
        studentUserId: 'stu-1',
        sectionId: 'sec-1',
      );
      expect(result, isNull);
    });

    test('findAllForStudent returns only matching student records', () async {
      final repo = HivePracticeLoopOverrideRepository();
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-A',
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      );
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-2',
          studentUserId: 'stu-A',
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      );
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-B',
          lastPlayedAt: DateTime(2026, 6, 4),
        ),
      );
      final results = await repo.findAllForStudent('stu-A');
      expect(results.length, 2);
      expect(results.every((o) => o.studentUserId == 'stu-A'), true);
    });
  });
}
