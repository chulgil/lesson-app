// DailyMissionRotation 결정론 테스트 — doc 46 §4④ (P3a).
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/domain/entities/daily_mission_kind.dart';
import 'package:lessonaza/features/gamification/domain/services/daily_mission_rotation.dart';

void main() {
  group('DailyMissionRotation.missionsFor — 결정론 (doc 46 §4④)', () {
    test('같은 (날짜, 학생) → 항상 같은 3개, 순서도 동일', () {
      final now = DateTime.utc(2026, 7, 30, 3, 0);
      final first = DailyMissionRotation.missionsFor('student_1', now);
      final second = DailyMissionRotation.missionsFor('student_1', now);

      expect(first, second);
      expect(first.length, 3);
      expect(first.first, DailyMissionRotation.fixedCore);
    });

    test('고정 코어(practice15m)는 항상 포함, 로테이션 2개는 pool 의 부분집합', () {
      for (var day = 1; day <= 28; day++) {
        final now = DateTime.utc(2026, 7, day, 12, 0);
        final missions = DailyMissionRotation.missionsFor('student_1', now);

        expect(missions.first, DailyMissionKind.practice15m);
        final rotating = missions.skip(1).toSet();
        expect(rotating.length, 2, reason: '로테이션은 중복 없이 2개');
        expect(
          rotating.every(DailyMissionRotation.pool.contains),
          isTrue,
          reason: '로테이션 후보는 pool 안에서만 선택',
        );
        expect(rotating.contains(DailyMissionKind.practice15m), isFalse);
      }
    });

    test('다른 학생은 같은 날이라도 다른 조합이 나올 수 있다 (해시 시드에 studentId 포함)', () {
      final now = DateTime.utc(2026, 7, 30, 12, 0);
      final combos = <Set<DailyMissionKind>>{};
      for (var i = 0; i < 20; i++) {
        combos.add(DailyMissionRotation.missionsFor('student_$i', now).toSet());
      }
      // pool(3) 에서 2개를 고르는 경우의 수는 3가지뿐이지만, 20명 중 최소
      // 1가지 조합만 나오면 결정론이 깨진(전부 고정) 것 — 시드가 studentId 를
      // 반영한다는 증거로 2가지 이상 관측되어야 한다.
      expect(combos.length, greaterThan(1));
    });

    test('날짜가 바뀌면 로테이션이 달라질 수 있다 (2026-07-30 vs 2026-08-15)', () {
      final dayA = DateTime.utc(2026, 7, 30, 12, 0);
      final dayB = DateTime.utc(2026, 8, 15, 12, 0);

      final missionsA = DailyMissionRotation.missionsFor('student_1', dayA);
      final missionsB = DailyMissionRotation.missionsFor('student_1', dayB);

      // 항상 다르다고 보장할 수는 없다(3개 조합만 존재) — 대신 날짜별로 서로
      // 다른 조합이 실제로 관측되는 날짜쌍이 존재함을 넓은 범위에서 확인한다.
      var foundDifference = false;
      for (var day = 1; day <= 60; day++) {
        final other = DateTime.utc(2026, 7, 1).add(Duration(days: day - 1));
        final missions = DailyMissionRotation.missionsFor('student_1', other);
        if (missions.toSet() != missionsA.toSet()) {
          foundDifference = true;
          break;
        }
      }
      expect(foundDifference, isTrue);
      // sanity: dayB 계산 자체는 예외 없이 항상 3개를 반환한다.
      expect(missionsB.length, 3);
    });

    test('KST 자정 경계 — 같은 KST 달력일의 다른 시각은 동일 로테이션', () {
      // 2026-07-30 00:30 KST = 2026-07-29 15:30 UTC (아직 UTC 로는 전날)
      final earlyKst = DateTime.utc(2026, 7, 29, 15, 30);
      // 2026-07-30 23:30 KST = 2026-07-30 14:30 UTC
      final lateKst = DateTime.utc(2026, 7, 30, 14, 30);

      expect(
        DailyMissionRotation.kstCalendarDate(earlyKst),
        DailyMissionRotation.kstCalendarDate(lateKst),
        reason: '두 instant 모두 KST 달력일로는 2026-07-30',
      );
      expect(
        DailyMissionRotation.missionsFor('student_1', earlyKst),
        DailyMissionRotation.missionsFor('student_1', lateKst),
      );
    });

    test('KST 자정 경계 — 자정을 넘기면 다른 KST 달력일로 취급', () {
      // 2026-07-29 23:59 KST = 2026-07-29 14:59 UTC
      final beforeMidnight = DateTime.utc(2026, 7, 29, 14, 59);
      // 2026-07-30 00:01 KST = 2026-07-29 15:01 UTC
      final afterMidnight = DateTime.utc(2026, 7, 29, 15, 1);

      final dateBefore = DailyMissionRotation.kstCalendarDate(beforeMidnight);
      final dateAfter = DailyMissionRotation.kstCalendarDate(afterMidnight);

      expect(dateBefore, isNot(dateAfter));
      expect(dateBefore, DateTime(2026, 7, 29));
      expect(dateAfter, DateTime(2026, 7, 30));
    });
  });
}
