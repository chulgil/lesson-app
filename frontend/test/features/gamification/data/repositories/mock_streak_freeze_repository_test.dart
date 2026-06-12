import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/streak_freeze.dart';

void main() {
  group('MockStreakFreezeRepository', () {
    late MockStreakFreezeRepository repo;
    final today = DateTime.utc(2026, 6, 12);

    setUp(() {
      repo = MockStreakFreezeRepository();
    });

    group('getOrCreate', () {
      test('returns empty record for new student', () async {
        final freeze = await repo.getOrCreate('s1');
        expect(freeze.studentId, 's1');
        expect(freeze.balance, 0);
        expect(freeze.usedAt, isEmpty);
        expect(freeze.examModeUntil, isNull);
      });

      test('returns persisted record on second call', () async {
        await repo.getOrCreate('s1');
        await repo.grantWeekly('s1');
        final second = await repo.getOrCreate('s1');
        expect(second.balance, 2);
      });

      test('different students get independent records', () async {
        await repo.grantWeekly('s1');
        await repo.grantWeekly('s2', amount: 1);
        final s1 = await repo.getOrCreate('s1');
        final s2 = await repo.getOrCreate('s2');
        expect(s1.balance, 2);
        expect(s2.balance, 1);
      });
    });

    group('grantWeekly', () {
      test('default amount 2 from empty', () async {
        final granted = await repo.grantWeekly('s1');
        expect(granted.balance, 2);
      });

      test('clamps to maxBalance on overflow', () async {
        await repo.grantWeekly('s1', amount: 3);
        final granted = await repo.grantWeekly('s1', amount: 3);
        expect(granted.balance, StreakFreeze.maxBalance);
      });

      test('custom amount respected', () async {
        final granted = await repo.grantWeekly('s1', amount: 1);
        expect(granted.balance, 1);
      });

      test('persists to underlying store', () async {
        await repo.grantWeekly('s1', amount: 2);
        final persisted = await repo.getOrCreate('s1');
        expect(persisted.balance, 2);
      });
    });

    group('apply', () {
      test('decrements balance + appends usedAt', () async {
        await repo.grantWeekly('s1', amount: 2);
        final applied = await repo.apply('s1', today);
        expect(applied.balance, 1);
        expect(applied.usedAt, [today]);
      });

      test('no-op when balance == 0', () async {
        final result = await repo.apply('s1', today);
        expect(result.balance, 0);
        expect(result.usedAt, isEmpty);
      });

      test('no-op when examMode active', () async {
        await repo.grantWeekly('s1', amount: 2);
        await repo.setExamMode('s1', today.add(const Duration(days: 7)));
        final result = await repo.apply('s1', today);
        expect(
          result.balance,
          2,
          reason: 'balance unchanged when examMode active',
        );
        expect(result.usedAt, isEmpty);
      });

      test('persists after apply', () async {
        await repo.grantWeekly('s1', amount: 2);
        await repo.apply('s1', today);
        final persisted = await repo.getOrCreate('s1');
        expect(persisted.balance, 1);
        expect(persisted.usedAt, [today]);
      });
    });

    group('setExamMode', () {
      test('activates exam mode', () async {
        final until = today.add(const Duration(days: 14));
        final result = await repo.setExamMode('s1', until);
        expect(result.examModeUntil, until);
      });

      test('null clears exam mode', () async {
        await repo.setExamMode('s1', today.add(const Duration(days: 7)));
        final cleared = await repo.setExamMode('s1', null);
        expect(cleared.examModeUntil, isNull);
      });

      test('preserves balance + usedAt', () async {
        await repo.grantWeekly('s1', amount: 2);
        await repo.apply('s1', today.subtract(const Duration(days: 3)));
        final result = await repo.setExamMode(
          's1',
          today.add(const Duration(days: 7)),
        );
        expect(result.balance, 1);
        expect(result.usedAt, [today.subtract(const Duration(days: 3))]);
      });
    });

    group('async latency simulation', () {
      test('all methods return Future (non-sync)', () async {
        final future = repo.getOrCreate('s1');
        expect(future, isA<Future<StreakFreeze>>());
        await future;
      });
    });
  });
}
