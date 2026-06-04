import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/practice/data/repositories/hive_practice_loop_override_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_bookmark.dart';
import 'package:lessonaza/features/practice/domain/entities/loop_memo.dart';
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

    test('round-trips studentMemos (#510)', () async {
      final repo = HivePracticeLoopOverrideRepository();
      final memo = LoopMemo(
        id: 'memo-1',
        atSeconds: 25,
        text: '여기 보잉',
        createdAt: DateTime(2026, 6, 4, 10, 0),
      );
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-1',
          lastPlayedAt: DateTime(2026, 6, 4),
          studentMemos: [memo],
        ),
      );
      final loaded = await repo.findFor(
        studentUserId: 'stu-1',
        sectionId: 'sec-1',
      );
      expect(loaded, isNotNull);
      expect(loaded!.studentMemos.length, 1);
      expect(loaded.studentMemos.first, equals(memo));
    });

    test(
      'migrates legacy records without studentMemos to empty list (#510)',
      () async {
        // Simulate a legacy record persisted before #510 — no `studentMemos` key.
        final box = await Hive.openBox<String>(
          HivePracticeLoopOverrideRepository.boxName,
        );
        const legacyKey = 'stu-1:sec-1';
        final legacyJson = <String, dynamic>{
          'sectionId': 'sec-1',
          'studentUserId': 'stu-1',
          'overrideStartSeconds': 30,
          'overrideEndSeconds': 60,
          'playbackSpeed': 0.75,
          'targetRepeatCount': 5,
          'completedRepeatCount': 0,
          'countInEnabled': false,
          'countInSoundEnabled': true,
          'audioMixMode': 'videoOnly',
          'lastPlayedAt': DateTime(2026, 6, 4).toIso8601String(),
          // Note: no `studentMemos` key — pre-#510 schema.
        };
        await box.put(legacyKey, jsonEncode(legacyJson));

        final repo = HivePracticeLoopOverrideRepository();
        final loaded = await repo.findFor(
          studentUserId: 'stu-1',
          sectionId: 'sec-1',
        );
        expect(loaded, isNotNull);
        expect(loaded!.studentMemos, isEmpty);
        expect(loaded.overrideStartSeconds, 30);
      },
    );

    test('round-trips bookmarks + activeBookmarkId (#511)', () async {
      final repo = HivePracticeLoopOverrideRepository();
      const b1 = LoopBookmark(
        id: 'b1',
        name: '도입',
        startSeconds: 0,
        endSeconds: 12,
        colorIndex: 0,
      );
      const b2 = LoopBookmark(
        id: 'b2',
        name: '엔딩',
        startSeconds: 60,
        endSeconds: 80,
        colorIndex: 1,
      );
      await repo.save(
        PracticeLoopOverride(
          sectionId: 'sec-1',
          studentUserId: 'stu-1',
          lastPlayedAt: DateTime(2026, 6, 4),
          bookmarks: const [b1, b2],
          activeBookmarkId: 'b2',
        ),
      );

      final loaded = await repo.findFor(
        studentUserId: 'stu-1',
        sectionId: 'sec-1',
      );
      expect(loaded, isNotNull);
      expect(loaded!.bookmarks, [b1, b2]);
      expect(loaded.activeBookmarkId, 'b2');
    });

    test(
      'migrates legacy single-override record into a "기본" bookmark (#511)',
      () async {
        // Simulate a legacy record persisted before #511 — has overrideStart /
        // overrideEnd but no `bookmarks` key.
        final box = await Hive.openBox<String>(
          HivePracticeLoopOverrideRepository.boxName,
        );
        const legacyKey = 'stu-1:sec-1';
        final legacyJson = <String, dynamic>{
          'sectionId': 'sec-1',
          'studentUserId': 'stu-1',
          'overrideStartSeconds': 30,
          'overrideEndSeconds': 60,
          'playbackSpeed': 1.0,
          'targetRepeatCount': 5,
          'completedRepeatCount': 0,
          'countInEnabled': false,
          'countInSoundEnabled': true,
          'audioMixMode': 'videoOnly',
          'lastPlayedAt': DateTime(2026, 6, 4).toIso8601String(),
          // No `bookmarks`, no `activeBookmarkId` — pre-#511 schema.
        };
        await box.put(legacyKey, jsonEncode(legacyJson));

        final repo = HivePracticeLoopOverrideRepository();
        final loaded = await repo.findFor(
          studentUserId: 'stu-1',
          sectionId: 'sec-1',
        );
        expect(loaded, isNotNull);
        expect(loaded!.bookmarks.length, 1);
        final migrated = loaded.bookmarks.single;
        expect(migrated.name, PracticeLoopOverride.defaultBookmarkName);
        expect(migrated.startSeconds, 30);
        expect(migrated.endSeconds, 60);
        expect(loaded.activeBookmarkId, migrated.id);
      },
    );

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
