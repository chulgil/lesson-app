import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/data/repositories/mock_streak_freeze_repository.dart';
import 'package:lessonaza/features/gamification/domain/entities/streak_freeze.dart';
import 'package:lessonaza/features/gamification/domain/services/streak_freeze_service.dart';

/// KST = UTC+9 (DST 없음). 일요일 자정 KST = 토요일 15:00 UTC.
///
/// 시나리오 기준일: 2026-06-12 (KST 금요일).
/// - 이번 주 일요일 자정 KST = 2026-06-07 00:00 KST = 2026-06-06 15:00 UTC
/// - 다음 주 일요일 자정 KST = 2026-06-14 00:00 KST = 2026-06-13 15:00 UTC
void main() {
  group('StreakFreezeService', () {
    late MockStreakFreezeRepository repo;
    late StreakFreezeService service;

    setUp(() {
      repo = MockStreakFreezeRepository();
      service = StreakFreezeService(repository: repo);
    });

    // 2026-06-12 (KST 금요일 09:00) = 2026-06-12 00:00 UTC
    final fridayKstMorning = DateTime.utc(2026, 6, 12, 0);
    // 이번 주 일요일 자정 KST (2026-06-07 00:00 KST = 2026-06-06 15:00 UTC)
    final thisSundayMidnightUtc = DateTime.utc(2026, 6, 6, 15);
    // 다음 주 일요일 자정 KST (2026-06-14 00:00 KST = 2026-06-13 15:00 UTC)
    final nextSundayMidnightUtc = DateTime.utc(2026, 6, 13, 15);

    group('previousSundayMidnightKstAsUtc — pure helper', () {
      test('Friday 09:00 KST → previous Sunday 00:00 KST (5 days back)', () {
        final result = StreakFreezeService.previousSundayMidnightKstAsUtc(
          fridayKstMorning,
        );
        expect(result, thisSundayMidnightUtc);
      });

      test('Saturday 23:59 KST → same week Sunday 00:00 KST (6 days back)', () {
        // 2026-06-13 23:59 KST = 2026-06-13 14:59 UTC
        final satNight = DateTime.utc(2026, 6, 13, 14, 59);
        final result = StreakFreezeService.previousSundayMidnightKstAsUtc(
          satNight,
        );
        expect(result, thisSundayMidnightUtc);
      });

      test('Sunday 00:01 KST → that Sunday 00:00 KST (0 days back)', () {
        // 2026-06-14 00:01 KST = 2026-06-13 15:01 UTC
        final sunJustAfter = DateTime.utc(2026, 6, 13, 15, 1);
        final result = StreakFreezeService.previousSundayMidnightKstAsUtc(
          sunJustAfter,
        );
        expect(result, nextSundayMidnightUtc);
      });

      test('Sunday 23:59 KST → that Sunday 00:00 KST', () {
        // 2026-06-14 23:59 KST = 2026-06-14 14:59 UTC
        final sunNight = DateTime.utc(2026, 6, 14, 14, 59);
        final result = StreakFreezeService.previousSundayMidnightKstAsUtc(
          sunNight,
        );
        expect(result, nextSundayMidnightUtc);
      });
    });

    group('weeklyGrantIfDue', () {
      test('grants +2 when lastGrantedAt is null (new student)', () async {
        final result = await service.weeklyGrantIfDue(
          studentId: 's1',
          now: fridayKstMorning,
        );
        expect(result.balance, 2);
        expect(result.lastGrantedAt, fridayKstMorning);
      });

      test('grants +2 when lastGrantedAt < this Sunday (last week)', () async {
        // 지난 주 일요일 = 이번 주 일요일 - 7일
        await repo.grantWeekly(
          's1',
          asOf: thisSundayMidnightUtc.subtract(const Duration(days: 1)),
        );
        final result = await service.weeklyGrantIfDue(
          studentId: 's1',
          now: fridayKstMorning,
        );
        expect(result.balance, 4); // 2 + 2, clamped at 4
        expect(result.lastGrantedAt, fridayKstMorning);
      });

      test(
        'no-op when lastGrantedAt >= this Sunday (already granted)',
        () async {
          // 이번 주 월요일 grant 했음
          final monGrant = thisSundayMidnightUtc.add(const Duration(days: 1));
          await repo.grantWeekly('s1', asOf: monGrant);
          final result = await service.weeklyGrantIfDue(
            studentId: 's1',
            now: fridayKstMorning,
          );
          expect(result.balance, 2);
          expect(
            result.lastGrantedAt,
            monGrant,
            reason: 'lastGrantedAt unchanged when no grant',
          );
        },
      );

      test(
        'no-op when lastGrantedAt exactly == this Sunday boundary',
        () async {
          await repo.grantWeekly('s1', asOf: thisSundayMidnightUtc);
          final result = await service.weeklyGrantIfDue(
            studentId: 's1',
            now: fridayKstMorning,
          );
          expect(
            result.balance,
            2,
            reason: 'no double grant on exact boundary',
          );
        },
      );

      test('grants again next week (lastGrantedAt is now last week)', () async {
        // 1주차 grant
        await service.weeklyGrantIfDue(studentId: 's1', now: fridayKstMorning);
        // 다음 주 진입 — 2026-06-15 KST 월요일
        final nextWeekMonday = DateTime.utc(
          2026,
          6,
          14,
          15,
          1,
        ).add(const Duration(days: 1));
        final result = await service.weeklyGrantIfDue(
          studentId: 's1',
          now: nextWeekMonday,
        );
        expect(result.balance, 4); // clamped
        expect(result.lastGrantedAt, nextWeekMonday);
      });

      test('clamps at maxBalance even when granting', () async {
        // 이미 4 보유 + 지난 주 grant
        await repo.grantWeekly(
          's1',
          amount: 4,
          asOf: thisSundayMidnightUtc.subtract(const Duration(days: 1)),
        );
        final result = await service.weeklyGrantIfDue(
          studentId: 's1',
          now: fridayKstMorning,
        );
        expect(result.balance, StreakFreeze.maxBalance);
      });
    });

    group('applyOnAbsence', () {
      test('decrements balance + appends usedAt', () async {
        await repo.grantWeekly('s1', amount: 2, asOf: fridayKstMorning);
        final missedDate = DateTime.utc(2026, 6, 11);
        final result = await service.applyOnAbsence(
          studentId: 's1',
          missedDate: missedDate,
        );
        expect(result.balance, 1);
        expect(result.usedAt, [missedDate]);
      });

      test('no-op when balance == 0', () async {
        final result = await service.applyOnAbsence(
          studentId: 's1',
          missedDate: DateTime.utc(2026, 6, 11),
        );
        expect(result.balance, 0);
        expect(result.usedAt, isEmpty);
      });

      test('no-op when examMode active', () async {
        await repo.grantWeekly('s1', amount: 2, asOf: fridayKstMorning);
        await repo.setExamMode(
          's1',
          fridayKstMorning.add(const Duration(days: 7)),
        );
        final result = await service.applyOnAbsence(
          studentId: 's1',
          missedDate: fridayKstMorning,
        );
        expect(result.balance, 2);
        expect(result.usedAt, isEmpty);
      });
    });

    group('setExamMode', () {
      test('sets examModeUntil via repository', () async {
        final until = fridayKstMorning.add(const Duration(days: 14));
        final result = await service.setExamMode(studentId: 's1', until: until);
        expect(result.examModeUntil, until);
      });

      test('null clears examMode', () async {
        await service.setExamMode(
          studentId: 's1',
          until: fridayKstMorning.add(const Duration(days: 7)),
        );
        final result = await service.setExamMode(studentId: 's1', until: null);
        expect(result.examModeUntil, isNull);
      });

      test('preserves balance and usedAt', () async {
        await repo.grantWeekly('s1', amount: 2, asOf: fridayKstMorning);
        await repo.apply('s1', fridayKstMorning);
        final result = await service.setExamMode(
          studentId: 's1',
          until: fridayKstMorning.add(const Duration(days: 7)),
        );
        expect(result.balance, 1);
        expect(result.usedAt, [fridayKstMorning]);
      });
    });

    group('isGrantDue — public predicate', () {
      test('true when lastGrantedAt is null', () {
        expect(
          StreakFreezeService.isGrantDue(
            lastGrantedAt: null,
            now: fridayKstMorning,
          ),
          isTrue,
        );
      });

      test('true when lastGrantedAt before this Sunday', () {
        expect(
          StreakFreezeService.isGrantDue(
            lastGrantedAt: thisSundayMidnightUtc.subtract(
              const Duration(seconds: 1),
            ),
            now: fridayKstMorning,
          ),
          isTrue,
        );
      });

      test('false when lastGrantedAt == this Sunday boundary', () {
        expect(
          StreakFreezeService.isGrantDue(
            lastGrantedAt: thisSundayMidnightUtc,
            now: fridayKstMorning,
          ),
          isFalse,
        );
      });

      test('false when lastGrantedAt after this Sunday', () {
        expect(
          StreakFreezeService.isGrantDue(
            lastGrantedAt: thisSundayMidnightUtc.add(
              const Duration(seconds: 1),
            ),
            now: fridayKstMorning,
          ),
          isFalse,
        );
      });
    });
  });
}
