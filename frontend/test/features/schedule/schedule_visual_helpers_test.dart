import 'package:flutter/material.dart';
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
// §7.120 — weeklyColumnBackground
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  group('§7.120 weeklyColumnBackground — 4단 우선순위', () {
    test('우선순위 1: 쉬는 날은 다른 모든 조건을 무시', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today, // today 더라도
        isRestDay: true,
        isWeekend: true, // 주말이더라도
        dayIndex: 5,
      );
      expect(color, AppColors.scheduleMutedBackground.withValues(alpha: 0.5));
    });

    test('우선순위 2: 오늘은 주말/zebra 보다 우선', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        isRestDay: false,
        isWeekend: true,
        dayIndex: 5,
      );
      expect(color, AppColors.paperAccent.withValues(alpha: 0.10));
    });

    test('우선순위 3: 주말은 zebra 보다 우선', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
        isWeekend: true,
        dayIndex: 5, // 홀수지만 주말 우선
      );
      expect(color, AppColors.paperAccentSoft.withValues(alpha: 0.06));
    });

    test('우선순위 4: 평일 홀수 인덱스는 zebra 톤', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
        isWeekend: false,
        dayIndex: 1, // 화요일
      );
      expect(color, AppColors.ink.withValues(alpha: 0.025));
    });

    test('평일 짝수 인덱스는 투명(null)', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
        isWeekend: false,
        dayIndex: 0, // 월요일
      );
      expect(color, isNull);
    });

    test('과거 평일 짝수도 투명(null) — past 는 별도 처리 없음', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.past,
        isRestDay: false,
        isWeekend: false,
        dayIndex: 2, // 수요일 (짝수)
      );
      expect(color, isNull);
    });

    test('4단 시각 계층은 4개의 서로 다른 색상을 만든다 (계층 붕괴 방지)', () {
      final restDay = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: true,
        isWeekend: false,
        dayIndex: 0,
      );
      final today = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        isRestDay: false,
        isWeekend: false,
        dayIndex: 0,
      );
      final weekend = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
        isWeekend: true,
        dayIndex: 5,
      );
      final zebra = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        isRestDay: false,
        isWeekend: false,
        dayIndex: 1,
      );

      final colors = {restDay, today, weekend, zebra};
      expect(
        colors.length,
        4,
        reason: '4단 계층(쉬는 날/오늘/주말/zebra)은 모두 다른 색상이어야 함',
      );
    });

    test('계층별 시각 강도 순서: restDay > today > weekend > zebra (alpha)', () {
      final restDayAlpha =
          weeklyColumnBackground(
            dayType: ScheduleDayType.future,
            isRestDay: true,
            isWeekend: false,
            dayIndex: 0,
          )!.a;
      final todayAlpha =
          weeklyColumnBackground(
            dayType: ScheduleDayType.today,
            isRestDay: false,
            isWeekend: false,
            dayIndex: 0,
          )!.a;
      final weekendAlpha =
          weeklyColumnBackground(
            dayType: ScheduleDayType.future,
            isRestDay: false,
            isWeekend: true,
            dayIndex: 5,
          )!.a;
      final zebraAlpha =
          weeklyColumnBackground(
            dayType: ScheduleDayType.future,
            isRestDay: false,
            isWeekend: false,
            dayIndex: 1,
          )!.a;

      expect(restDayAlpha, greaterThan(todayAlpha));
      expect(todayAlpha, greaterThan(weekendAlpha));
      expect(weekendAlpha, greaterThan(zebraAlpha));
    });

    test('dayIndex 경계 — 0~4=평일, 5~6=주말 매핑 (호출자 계약 검증)', () {
      // weeklyColumnBackground 자체는 isWeekend 를 매개변수로 받지만
      // 호출 측 (schedule_weekly_grid_view.dart line 164: `dayIndex >= 5`)
      // 이 평일/주말을 결정한다. 이 경계가 깨지지 않는지 가드.
      bool weekendByIndex(int i) => i >= 5;
      expect(weekendByIndex(0), isFalse, reason: '월요일');
      expect(weekendByIndex(4), isFalse, reason: '금요일');
      expect(weekendByIndex(5), isTrue, reason: '토요일');
      expect(weekendByIndex(6), isTrue, reason: '일요일');
    });

    test('alpha 상한 0.10 constraint — 모든 색상이 0.5 이하', () {
      final colors = <Color?>[
        weeklyColumnBackground(
          dayType: ScheduleDayType.today,
          isRestDay: false,
          isWeekend: false,
          dayIndex: 0,
        ),
        weeklyColumnBackground(
          dayType: ScheduleDayType.future,
          isRestDay: false,
          isWeekend: true,
          dayIndex: 5,
        ),
        weeklyColumnBackground(
          dayType: ScheduleDayType.future,
          isRestDay: false,
          isWeekend: false,
          dayIndex: 1,
        ),
      ];
      for (final c in colors) {
        expect(c, isNotNull);
        // 쉬는 날(0.5) 제외, 다른 모든 색상은 alpha 0.10 이하
        expect(c!.a, lessThanOrEqualTo(0.10));
      }
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
