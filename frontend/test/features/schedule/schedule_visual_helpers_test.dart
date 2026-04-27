import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/utils/schedule_visual_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

WeeklySchedule _schedule(int dayOfWeek, {bool isActive = true}) =>
    WeeklySchedule(
      id: 'sched_$dayOfWeek',
      dayOfWeek: dayOfWeek,
      startTime: '14:00',
      endTime: '18:00',
      isActive: isActive,
      createdAt: DateTime(2026, 1, 1),
    );

TeacherAvailability _availability(List<WeeklySchedule> schedules) =>
    TeacherAvailability(
      id: 'av_1',
      teacherId: 'teacher_1',
      weeklySchedules: schedules,
      createdAt: DateTime(2026, 1, 1),
    );

// ═══════════════════════════════════════════════════════════════════════════
// §7.122 — weeklyColumnBackground (단순화 후 2단)
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  group('§7.122 weeklyColumnBackground — 2단 우선순위 (zebra/주말 제거)', () {
    test('우선순위 1: 쉬는 날은 today 보다 우선', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        isRestDay: true,
      );
      expect(color, AppColors.scheduleMutedBackground.withValues(alpha: 0.5));
    });

    test('우선순위 2: 오늘은 paperAccent 0.06 tint', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        isRestDay: false,
      );
      expect(color, AppColors.paperAccent.withValues(alpha: 0.06));
    });

    test('과거/미래 평일은 투명(null) — 디바이더가 컬럼 경계 담당', () {
      final past = weeklyColumnBackground(
        dayType: ScheduleDayType.past,
        isRestDay: false,
      );
      final future = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
      );
      expect(past, isNull);
      expect(future, isNull);
    });

    test('주말도 평일과 동일 — 헤더에서만 변별, 본문 평탄화', () {
      // §7.120 에서는 주말 0.06 alpha 였으나, §7.122 에서 제거.
      // 이유: 토/일도 레슨 카드 가독성을 위해 본문은 평탄.
      final saturday = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
      );
      final sunday = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
      );
      expect(saturday, isNull);
      expect(sunday, isNull);
    });

    test('alpha 상한 — today 색상은 0.10 이하 (카드 가독성 보호)', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        isRestDay: false,
      );
      expect(color, isNotNull);
      expect(color!.a, lessThanOrEqualTo(0.10));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // §7.121 — isTeacherRestDay
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.121 isTeacherRestDay — 휴무 판정', () {
    test('availability null → false (정상 근무로 가정)', () {
      final result = isTeacherRestDay(
        availability: null,
        date: DateTime(2026, 4, 27), // 월요일
      );
      expect(result, isFalse);
    });

    test('해당 요일에 active schedule 있음 → false', () {
      // 2026-04-27 = 월요일 (DateTime.weekday=1, dayOfWeek=0)
      final av = _availability([_schedule(0)]);
      final result = isTeacherRestDay(
        availability: av,
        date: DateTime(2026, 4, 27),
      );
      expect(result, isFalse);
    });

    test('해당 요일에 schedule 없음 → true (쉬는 날)', () {
      // 2026-04-27 = 월요일. 화/수만 근무.
      final av = _availability([_schedule(1), _schedule(2)]);
      final result = isTeacherRestDay(
        availability: av,
        date: DateTime(2026, 4, 27),
      );
      expect(result, isTrue);
    });

    test('해당 요일 schedule 있으나 isActive=false → true (휴무)', () {
      // 월요일 schedule 비활성화
      final av = _availability([_schedule(0, isActive: false)]);
      final result = isTeacherRestDay(
        availability: av,
        date: DateTime(2026, 4, 27),
      );
      expect(result, isTrue);
    });

    test('일요일 (DateTime.weekday=7 → dayOfWeek=6) 매핑 확인', () {
      // 2026-04-26 = 일요일
      final av = _availability([_schedule(6)]); // 일요일 근무
      final result = isTeacherRestDay(
        availability: av,
        date: DateTime(2026, 4, 26),
      );
      expect(result, isFalse);
    });

    test('일요일 미근무 → 휴무로 판정', () {
      // 일요일(dayOfWeek=6) 미등록. 평일만 등록.
      final av = _availability([
        _schedule(0),
        _schedule(1),
        _schedule(2),
        _schedule(3),
        _schedule(4),
      ]);
      final result = isTeacherRestDay(
        availability: av,
        date: DateTime(2026, 4, 26), // 일요일
      );
      expect(result, isTrue);
    });

    test('weeklySchedules 비어있음 → 모든 요일 휴무', () {
      final av = _availability([]);
      for (var d = 27; d <= 30; d++) {
        final result = isTeacherRestDay(
          availability: av,
          date: DateTime(2026, 4, d),
        );
        expect(result, isTrue, reason: '2026-04-$d');
      }
    });
  });
}
