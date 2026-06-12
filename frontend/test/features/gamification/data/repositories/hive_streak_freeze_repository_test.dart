import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lessonaza/features/gamification/data/repositories/hive_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/streak_freeze.dart';

void main() {
  late Directory tempDir;
  late Box<String> box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_streak_freeze_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<String>(HiveStreakFreezeRepository.boxName);
  });

  tearDown(() async {
    await box.close();
    await Hive.deleteBoxFromDisk(HiveStreakFreezeRepository.boxName);
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HiveStreakFreezeRepository', () {
    final today = DateTime.utc(2026, 6, 12);

    test('Box name = streak_freeze_v1 (AC-1.2)', () {
      expect(HiveStreakFreezeRepository.boxName, 'streak_freeze_v1');
    });

    group('getOrCreate — empty box first entry (AC-3.3)', () {
      test('returns empty record for new student', () async {
        final repo = HiveStreakFreezeRepository(box: box);
        final freeze = await repo.getOrCreate('s1');
        expect(freeze.studentId, 's1');
        expect(freeze.balance, 0);
        expect(freeze.usedAt, isEmpty);
        expect(freeze.examModeUntil, isNull);
      });

      test('persists empty record after getOrCreate', () async {
        final repo = HiveStreakFreezeRepository(box: box);
        await repo.getOrCreate('s1');
        expect(box.containsKey('s1'), isTrue);
      });

      test('corrupted JSON falls back to empty record', () async {
        await box.put('s1', '{this is not valid json');
        final repo = HiveStreakFreezeRepository(box: box);
        final freeze = await repo.getOrCreate('s1');
        expect(freeze.balance, 0);
        expect(freeze.usedAt, isEmpty);
      });
    });

    group('JSON round-trip persistence', () {
      test('grantWeekly persists across new repository instance', () async {
        final repo1 = HiveStreakFreezeRepository(box: box);
        await repo1.grantWeekly('s1', amount: 3);

        final repo2 = HiveStreakFreezeRepository(box: box);
        final reloaded = await repo2.getOrCreate('s1');
        expect(reloaded.balance, 3);
      });

      test('apply persists usedAt list with DateTime fidelity', () async {
        final repo1 = HiveStreakFreezeRepository(box: box);
        await repo1.grantWeekly('s1', amount: 2);
        await repo1.apply('s1', today);

        final repo2 = HiveStreakFreezeRepository(box: box);
        final reloaded = await repo2.getOrCreate('s1');
        expect(reloaded.balance, 1);
        expect(reloaded.usedAt, [today]);
      });

      test('setExamMode persists examModeUntil', () async {
        final until = today.add(const Duration(days: 14));
        final repo1 = HiveStreakFreezeRepository(box: box);
        await repo1.setExamMode('s1', until);

        final repo2 = HiveStreakFreezeRepository(box: box);
        final reloaded = await repo2.getOrCreate('s1');
        expect(reloaded.examModeUntil, until);
      });

      test('setExamMode null clears examModeUntil persistently', () async {
        final until = today.add(const Duration(days: 7));
        final repo1 = HiveStreakFreezeRepository(box: box);
        await repo1.setExamMode('s1', until);
        await repo1.setExamMode('s1', null);

        final repo2 = HiveStreakFreezeRepository(box: box);
        final reloaded = await repo2.getOrCreate('s1');
        expect(reloaded.examModeUntil, isNull);
      });
    });

    group('Multi-student isolation', () {
      test('separate records per studentId key', () async {
        final repo = HiveStreakFreezeRepository(box: box);
        await repo.grantWeekly('s1', amount: 2);
        await repo.grantWeekly('s2', amount: 4);
        await repo.apply('s2', today);

        final s1 = await repo.getOrCreate('s1');
        final s2 = await repo.getOrCreate('s2');
        expect(s1.balance, 2);
        expect(s2.balance, 3);
        expect(s2.usedAt, [today]);
      });
    });

    group('Behavior parity with Mock', () {
      test('apply no-op when balance=0', () async {
        final repo = HiveStreakFreezeRepository(box: box);
        final result = await repo.apply('s1', today);
        expect(result.balance, 0);
        expect(result.usedAt, isEmpty);
      });

      test('apply no-op when examMode active', () async {
        final repo = HiveStreakFreezeRepository(box: box);
        await repo.grantWeekly('s1', amount: 2);
        await repo.setExamMode('s1', today.add(const Duration(days: 7)));
        final result = await repo.apply('s1', today);
        expect(result.balance, 2);
        expect(result.usedAt, isEmpty);
      });

      test('grantWeekly clamps to maxBalance', () async {
        final repo = HiveStreakFreezeRepository(box: box);
        await repo.grantWeekly('s1', amount: 3);
        final granted = await repo.grantWeekly('s1', amount: 3);
        expect(granted.balance, StreakFreeze.maxBalance);
      });
    });
  });
}
