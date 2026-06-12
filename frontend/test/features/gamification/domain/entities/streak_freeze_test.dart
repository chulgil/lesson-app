import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/streak_freeze.dart';

void main() {
  group('StreakFreeze', () {
    final baseDate = DateTime.utc(2026, 6, 12);
    final base = StreakFreeze(
      studentId: 's1',
      balance: 2,
      usedAt: const [],
      examModeUntil: null,
    );

    group('constructor', () {
      test('balance clamps to 0 when below', () {
        final freeze = StreakFreeze(
          studentId: 's1',
          balance: -1,
          usedAt: const [],
          examModeUntil: null,
        );
        expect(freeze.balance, 0);
      });

      test('balance clamps to 4 when above', () {
        final freeze = StreakFreeze(
          studentId: 's1',
          balance: 99,
          usedAt: const [],
          examModeUntil: null,
        );
        expect(freeze.balance, 4);
      });

      test('balance preserved when in range 0-4', () {
        for (final b in [0, 1, 2, 3, 4]) {
          final freeze = StreakFreeze(
            studentId: 's1',
            balance: b,
            usedAt: const [],
            examModeUntil: null,
          );
          expect(freeze.balance, b);
        }
      });

      test('empty defaults via factory', () {
        final empty = StreakFreeze.empty('s1');
        expect(empty.studentId, 's1');
        expect(empty.balance, 0);
        expect(empty.usedAt, isEmpty);
        expect(empty.examModeUntil, isNull);
      });
    });

    group('canApply', () {
      test('true when balance > 0 and examMode not active', () {
        expect(base.canApply(asOf: baseDate), isTrue);
      });

      test('false when balance == 0', () {
        final zero = base.copyWith(balance: 0);
        expect(zero.canApply(asOf: baseDate), isFalse);
      });

      test('false when examMode active (asOf < examModeUntil)', () {
        final examActive = base.copyWith(
          examModeUntil: baseDate.add(const Duration(days: 7)),
        );
        expect(examActive.canApply(asOf: baseDate), isFalse);
      });

      test('true when examMode expired (asOf > examModeUntil)', () {
        final examExpired = base.copyWith(
          examModeUntil: baseDate.subtract(const Duration(days: 1)),
        );
        expect(examExpired.canApply(asOf: baseDate), isTrue);
      });
    });

    group('apply', () {
      test('decrements balance and appends usedAt', () {
        final applied = base.apply(baseDate);
        expect(applied.balance, 1);
        expect(applied.usedAt, [baseDate]);
      });

      test('preserves studentId and examModeUntil', () {
        final examUntil = baseDate.add(const Duration(days: 3));
        final withExam = base.copyWith(examModeUntil: examUntil);
        final applied = withExam.apply(baseDate);
        expect(applied.studentId, 's1');
        expect(applied.examModeUntil, examUntil);
      });

      test('throws StateError when balance == 0', () {
        final zero = base.copyWith(balance: 0);
        expect(() => zero.apply(baseDate), throwsStateError);
      });
    });

    group('grantWeekly', () {
      test('default amount 2 increases balance', () {
        final zero = base.copyWith(balance: 0);
        final granted = zero.grantWeekly();
        expect(granted.balance, 2);
      });

      test('clamps to 4 when overflow', () {
        final near = base.copyWith(balance: 3);
        final granted = near.grantWeekly(amount: 2);
        expect(granted.balance, 4);
      });

      test('custom amount respected', () {
        final zero = base.copyWith(balance: 0);
        final granted = zero.grantWeekly(amount: 1);
        expect(granted.balance, 1);
      });

      test('preserves usedAt and examModeUntil', () {
        final usedDate = baseDate.subtract(const Duration(days: 2));
        final withState = base.copyWith(
          balance: 1,
          usedAt: [usedDate],
          examModeUntil: baseDate.add(const Duration(days: 5)),
        );
        final granted = withState.grantWeekly();
        expect(granted.usedAt, [usedDate]);
        expect(granted.examModeUntil, baseDate.add(const Duration(days: 5)));
      });
    });

    group('json round-trip', () {
      test('preserves all fields including usedAt list', () {
        final original = base.copyWith(
          balance: 3,
          usedAt: [
            baseDate.subtract(const Duration(days: 7)),
            baseDate.subtract(const Duration(days: 14)),
          ],
          examModeUntil: baseDate.add(const Duration(days: 10)),
        );
        final json = original.toJson();
        final restored = StreakFreeze.fromJson(json);
        expect(restored.studentId, original.studentId);
        expect(restored.balance, original.balance);
        expect(restored.usedAt, original.usedAt);
        expect(restored.examModeUntil, original.examModeUntil);
      });

      test('handles null examModeUntil', () {
        final json = base.toJson();
        final restored = StreakFreeze.fromJson(json);
        expect(restored.examModeUntil, isNull);
      });
    });

    group('immutability', () {
      test('apply returns new instance, base unchanged', () {
        final originalBalance = base.balance;
        base.apply(baseDate);
        expect(base.balance, originalBalance);
        expect(base.usedAt, isEmpty);
      });

      test('grantWeekly returns new instance, base unchanged', () {
        final originalBalance = base.balance;
        base.grantWeekly();
        expect(base.balance, originalBalance);
      });
    });
  });
}
