import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/streak_freeze.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_with_freeze_calculator.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_streak.dart';

void main() {
  group('StreakWithFreezeCalculator — Job 5 Task 5.1 (4 시나리오)', () {
    final today = DateTime(2026, 6, 12);
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    PracticeStreak raw({int currentStreak = 0, DateTime? lastPracticeDate}) =>
        PracticeStreak(
          id: 'streak_s1',
          studentId: 's1',
          currentStreak: currentStreak,
          longestStreak: currentStreak,
          lastPracticeDate: lastPracticeDate,
          updatedAt: today,
        );

    StreakFreeze freezeOf({
      int balance = 0,
      List<DateTime> usedAt = const [],
      DateTime? examModeUntil,
    }) => StreakFreeze(
      studentId: 's1',
      balance: balance,
      usedAt: usedAt,
      examModeUntil: examModeUntil,
    );

    group('시나리오 1: 어제 활동 + freeze balance=2 → freeze 차감 X, streak +1', () {
      test('lastPracticeDate=yesterday → activity hot, freeze 적용 안 함', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 7, lastPracticeDate: yesterday),
          freeze: freezeOf(balance: 2),
          now: today,
        );
        expect(result.effectiveCurrentStreak, 7);
        expect(result.freezeShouldApply, isFalse);
        expect(result.streakBroken, isFalse);
        expect(result.examModeDormant, isFalse);
      });

      test('lastPracticeDate=today → activity hot', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 7, lastPracticeDate: today),
          freeze: freezeOf(balance: 2),
          now: today,
        );
        expect(result.effectiveCurrentStreak, 7);
        expect(result.freezeShouldApply, isFalse);
      });
    });

    group('시나리오 2: 어제 결석 + freeze balance=2 → freeze 차감 1 권고, '
        'streak 유지', () {
      test('lastPracticeDate=2일 전 → freezeShouldApply=true', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 7, lastPracticeDate: twoDaysAgo),
          freeze: freezeOf(balance: 2),
          now: today,
        );
        expect(result.freezeShouldApply, isTrue);
        expect(result.absenceDate, yesterday, reason: 'apply 대상 = 어제 (오늘 -1일)');
        expect(result.streakBroken, isFalse);
        // effective 는 raw 값 보존 — 아직 freeze 적용 안 한 시점이므로
        // currentStreak 를 +1 하지 않고 raw 그대로 (service 가 trigger 후
        // 재계산 시 정상 값 반환)
        expect(result.effectiveCurrentStreak, 7);
      });

      test('lastPracticeDate=null + balance>0 → 신규 학생, freeze 적용 안 함', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 0, lastPracticeDate: null),
          freeze: freezeOf(balance: 2),
          now: today,
        );
        expect(
          result.freezeShouldApply,
          isFalse,
          reason: '연습 이력 없는 신규 학생 — 결석 판정 X',
        );
        expect(result.streakBroken, isFalse);
      });
    });

    group('시나리오 3: 어제 결석 + freeze balance=0 → streak 끊김', () {
      test('balance=0 + 결석 → streakBroken=true', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 0, lastPracticeDate: twoDaysAgo),
          freeze: freezeOf(balance: 0),
          now: today,
        );
        expect(result.freezeShouldApply, isFalse);
        expect(result.streakBroken, isTrue);
        expect(result.effectiveCurrentStreak, 0);
      });

      test('balance=0 + 3일 전 결석 → 동일 처리', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(
            currentStreak: 0,
            lastPracticeDate: today.subtract(const Duration(days: 3)),
          ),
          freeze: freezeOf(balance: 0),
          now: today,
        );
        expect(result.streakBroken, isTrue);
      });
    });

    group('시나리오 4: 어제 결석 + examMode 활성 → freeze 차감 X, streak 동결', () {
      test('examMode 활성 + 결석 → freezeShouldApply=false + 동결 표시', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 7, lastPracticeDate: twoDaysAgo),
          freeze: freezeOf(
            balance: 2,
            examModeUntil: today.add(const Duration(days: 7)),
          ),
          now: today,
        );
        expect(
          result.freezeShouldApply,
          isFalse,
          reason: 'examMode 동안 freeze 차감 0 (canApply=false)',
        );
        expect(result.examModeDormant, isTrue);
        expect(result.streakBroken, isFalse, reason: 'examMode 동안 streak 끊김 0');
        expect(result.effectiveCurrentStreak, 7, reason: 'raw 값 보존 — 동결 표시');
      });

      test('examMode 만료 + 결석 + balance>0 → 일반 freeze 적용', () {
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 7, lastPracticeDate: twoDaysAgo),
          freeze: freezeOf(
            balance: 2,
            examModeUntil: today.subtract(const Duration(days: 1)),
          ),
          now: today,
        );
        expect(result.examModeDormant, isFalse);
        expect(result.freezeShouldApply, isTrue);
      });
    });

    group('Edge cases', () {
      test(
        'lastPracticeDate=null + balance=0 → 신규 학생 streak=0, broken=false',
        () {
          final result = StreakWithFreezeCalculator.compute(
            raw: raw(currentStreak: 0, lastPracticeDate: null),
            freeze: freezeOf(balance: 0),
            now: today,
          );
          expect(
            result.streakBroken,
            isFalse,
            reason: '연습 이력 없는 학생은 끊기지 않은 상태',
          );
          expect(result.effectiveCurrentStreak, 0);
        },
      );

      test('lastPracticeDate=오늘 새벽 (같은 KST 날짜) → 활동으로 판정', () {
        final earlyToday = DateTime(today.year, today.month, today.day, 1, 0);
        final result = StreakWithFreezeCalculator.compute(
          raw: raw(currentStreak: 5, lastPracticeDate: earlyToday),
          freeze: freezeOf(balance: 2),
          now: today,
        );
        expect(result.freezeShouldApply, isFalse);
        expect(result.streakBroken, isFalse);
      });
    });
  });
}
