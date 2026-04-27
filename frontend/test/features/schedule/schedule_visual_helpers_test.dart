import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/presentation/utils/schedule_visual_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════

WeeklySchedule _schedule(
  int dayOfWeek, {
  bool isActive = true,
  String startTime = '14:00',
  String endTime = '18:00',
}) => WeeklySchedule(
  id: 'sched_$dayOfWeek',
  dayOfWeek: dayOfWeek,
  startTime: startTime,
  endTime: endTime,
  isActive: isActive,
  createdAt: DateTime(2026, 1, 1),
);

TimeException _exception({
  required ExceptionType type,
  required DateTime startDate,
  DateTime? endDate,
  String? startTime,
  String? endTime,
}) => TimeException(
  id: 'ex_${type.name}_${startDate.toIso8601String()}',
  type: type,
  startDate: startDate,
  endDate: endDate ?? startDate,
  startTime: startTime,
  endTime: endTime,
  createdAt: DateTime(2026, 1, 1),
);

TeacherAvailability _availability(
  List<WeeklySchedule> schedules, {
  List<TimeException> exceptions = const [],
}) => TeacherAvailability(
  id: 'av_1',
  teacherId: 'teacher_1',
  weeklySchedules: schedules,
  exceptions: exceptions,
  createdAt: DateTime(2026, 1, 1),
);

// ═══════════════════════════════════════════════════════════════════════════

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // §7.123 — weeklyColumnBackground (4단 우선순위, restKind 기반)
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.123 (Mode A) weeklyColumnBackground — 미니멀 팔레트', () {
    final restColor = AppColors.ink.withValues(alpha: 0.10);

    test('휴가 (vacation) > today: 휴식 색상 우선', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        restKind: ColumnRestKind.vacation,
      );
      expect(color, restColor);
    });

    test('휴무 (holiday) > today: 휴식 색상 우선', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        restKind: ColumnRestKind.holiday,
      );
      expect(color, restColor);
    });

    test('정기 휴무일 (regular) > today: 휴식 색상 우선', () {
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        restKind: ColumnRestKind.regular,
      );
      expect(color, restColor);
    });

    test('모든 휴식 종류는 동일 색상 ink alpha 0.10 (변별은 라벨 칩)', () {
      final vacation = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        restKind: ColumnRestKind.vacation,
      );
      final holiday = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        restKind: ColumnRestKind.holiday,
      );
      final regular = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        restKind: ColumnRestKind.regular,
      );
      expect(vacation, restColor);
      expect(holiday, restColor);
      expect(regular, restColor);
    });

    test('today + none: 본문 톤 없음 (헤더 칩만 변별)', () {
      // §1.3.2 평탄화 — today 변별은 단일 채널(헤더)에서만.
      final color = weeklyColumnBackground(
        dayType: ScheduleDayType.today,
        restKind: ColumnRestKind.none,
      );
      expect(color, isNull);
    });

    test('과거/미래 평일 (none): 투명 (null)', () {
      final past = weeklyColumnBackground(
        dayType: ScheduleDayType.past,
        restKind: ColumnRestKind.none,
      );
      final future = weeklyColumnBackground(
        dayType: ScheduleDayType.future,
        restKind: ColumnRestKind.none,
      );
      expect(past, isNull);
      expect(future, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // §7.123 — columnRestKindForDate (우선순위 vacation > holiday > regular)
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.123 columnRestKindForDate — 우선순위 판정', () {
    test('availability null → none', () {
      final kind = columnRestKindForDate(
        availability: null,
        date: DateTime(2026, 4, 27),
      );
      expect(kind, ColumnRestKind.none);
    });

    test('vacation 다일 구간 내 → vacation', () {
      final av = _availability(
        [_schedule(0)], // 월 근무
        exceptions: [
          _exception(
            type: ExceptionType.vacation,
            startDate: DateTime(2026, 4, 27),
            endDate: DateTime(2026, 5, 3),
          ),
        ],
      );
      final kind = columnRestKindForDate(
        availability: av,
        date: DateTime(2026, 4, 30), // vacation 구간 내
      );
      expect(kind, ColumnRestKind.vacation);
    });

    test('holiday 단일일 → holiday', () {
      final av = _availability(
        [_schedule(0), _schedule(1)],
        exceptions: [
          _exception(
            type: ExceptionType.holiday,
            startDate: DateTime(2026, 4, 28), // 화요일
          ),
        ],
      );
      final kind = columnRestKindForDate(
        availability: av,
        date: DateTime(2026, 4, 28),
      );
      expect(kind, ColumnRestKind.holiday);
    });

    test('vacation > holiday: 같은 날 둘 다 적용 시 vacation 우선', () {
      final date = DateTime(2026, 4, 28);
      final av = _availability(
        [_schedule(1)], // 화요일 근무
        exceptions: [
          _exception(
            type: ExceptionType.vacation,
            startDate: DateTime(2026, 4, 27),
            endDate: DateTime(2026, 5, 3),
          ),
          _exception(type: ExceptionType.holiday, startDate: date),
        ],
      );
      final kind = columnRestKindForDate(availability: av, date: date);
      expect(kind, ColumnRestKind.vacation);
    });

    test('정기 휴무일 (weeklySchedules 미등록) → regular', () {
      final av = _availability([_schedule(1), _schedule(2)]); // 화/수만
      final kind = columnRestKindForDate(
        availability: av,
        date: DateTime(2026, 4, 27), // 월요일
      );
      expect(kind, ColumnRestKind.regular);
    });

    test('holiday > regular: 정기 근무일에 단일 휴무 → holiday', () {
      final av = _availability(
        [_schedule(0)], // 월 근무
        exceptions: [
          _exception(
            type: ExceptionType.holiday,
            startDate: DateTime(2026, 4, 27),
          ),
        ],
      );
      final kind = columnRestKindForDate(
        availability: av,
        date: DateTime(2026, 4, 27),
      );
      expect(kind, ColumnRestKind.holiday);
    });

    test('정상 근무일 → none', () {
      final av = _availability([_schedule(0)]); // 월 근무
      final kind = columnRestKindForDate(
        availability: av,
        date: DateTime(2026, 4, 27),
      );
      expect(kind, ColumnRestKind.none);
    });

    test('additionalSlot 예외는 컬럼 휴식에 영향 없음', () {
      // 정기 휴무일에 additionalSlot 만 있어도 컬럼은 regular (휴식)
      final av = _availability(
        [_schedule(1)], // 화 근무
        exceptions: [
          _exception(
            type: ExceptionType.additionalSlot,
            startDate: DateTime(2026, 4, 27), // 월요일
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      final kind = columnRestKindForDate(
        availability: av,
        date: DateTime(2026, 4, 27),
      );
      expect(kind, ColumnRestKind.regular);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // §7.123 — ColumnRestKind 라벨 칩
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.123 ColumnRestKind chipLabel', () {
    test('vacation → "휴가"', () {
      expect(ColumnRestKind.vacation.chipLabel, '휴가');
    });

    test('holiday → "휴무"', () {
      expect(ColumnRestKind.holiday.chipLabel, '휴무');
    });

    test('regular → null (라벨 없음, 헤더로 변별)', () {
      expect(ColumnRestKind.regular.chipLabel, isNull);
    });

    test('none → null', () {
      expect(ColumnRestKind.none.chipLabel, isNull);
    });

    test('isRest 확장: none 만 false', () {
      expect(ColumnRestKind.none.isRest, isFalse);
      expect(ColumnRestKind.vacation.isRest, isTrue);
      expect(ColumnRestKind.holiday.isRest, isTrue);
      expect(ColumnRestKind.regular.isRest, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // §7.121 / §7.123 — isTeacherRestDay (boolean 별칭)
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.121/§7.123 isTeacherRestDay — boolean 별칭', () {
    test('availability null → false', () {
      expect(
        isTeacherRestDay(availability: null, date: DateTime(2026, 4, 27)),
        isFalse,
      );
    });

    test('정상 근무일 → false', () {
      final av = _availability([_schedule(0)]);
      expect(
        isTeacherRestDay(availability: av, date: DateTime(2026, 4, 27)),
        isFalse,
      );
    });

    test('정기 휴무일 → true', () {
      final av = _availability([_schedule(1), _schedule(2)]);
      expect(
        isTeacherRestDay(availability: av, date: DateTime(2026, 4, 27)),
        isTrue,
      );
    });

    test('§7.123 확장: vacation 도 true', () {
      final av = _availability(
        [_schedule(0)],
        exceptions: [
          _exception(
            type: ExceptionType.vacation,
            startDate: DateTime(2026, 4, 27),
            endDate: DateTime(2026, 5, 3),
          ),
        ],
      );
      expect(
        isTeacherRestDay(availability: av, date: DateTime(2026, 4, 27)),
        isTrue,
      );
    });

    test('§7.123 확장: holiday 도 true', () {
      final av = _availability(
        [_schedule(0)],
        exceptions: [
          _exception(
            type: ExceptionType.holiday,
            startDate: DateTime(2026, 4, 27),
          ),
        ],
      );
      expect(
        isTeacherRestDay(availability: av, date: DateTime(2026, 4, 27)),
        isTrue,
      );
    });

    test('일요일 (weekday=7 → dayOfWeek=6) 매핑 확인', () {
      final av = _availability([_schedule(6)]); // 일요일 근무
      expect(
        isTeacherRestDay(
          availability: av,
          date: DateTime(2026, 4, 26), // 일요일
        ),
        isFalse,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // §7.123 — isWithinWorkHours
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.123 isWithinWorkHours — 근무시간 경계', () {
    test('availability null → true (정보 없으면 정상으로 가정)', () {
      expect(
        isWithinWorkHours(
          availability: null,
          slotStart: DateTime(2026, 4, 27, 10),
        ),
        isTrue,
      );
    });

    test('휴무 요일 (active schedule 없음) → false', () {
      final av = _availability([_schedule(1)]); // 화만 근무
      expect(
        isWithinWorkHours(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 15), // 월요일
        ),
        isFalse,
      );
    });

    test('근무시간 시작 정각 (14:00) → true (inclusive)', () {
      final av = _availability([
        _schedule(0, startTime: '14:00', endTime: '18:00'),
      ]);
      expect(
        isWithinWorkHours(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 14),
        ),
        isTrue,
      );
    });

    test('근무시간 종료 정각 (18:00) → false (exclusive)', () {
      final av = _availability([
        _schedule(0, startTime: '14:00', endTime: '18:00'),
      ]);
      expect(
        isWithinWorkHours(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 18),
        ),
        isFalse,
      );
    });

    test('근무시간 중간 (15:30) → true', () {
      final av = _availability([
        _schedule(0, startTime: '14:00', endTime: '18:00'),
      ]);
      expect(
        isWithinWorkHours(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 15, 30),
        ),
        isTrue,
      );
    });

    test('근무시간 시작 전 (13:30) → false', () {
      final av = _availability([
        _schedule(0, startTime: '14:00', endTime: '18:00'),
      ]);
      expect(
        isWithinWorkHours(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 13, 30),
        ),
        isFalse,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // §7.123 — isAdditionalOpenSlot
  // ═══════════════════════════════════════════════════════════════════════

  group('§7.123 isAdditionalOpenSlot — 추가오픈 슬롯', () {
    test('availability null → false', () {
      expect(
        isAdditionalOpenSlot(
          availability: null,
          slotStart: DateTime(2026, 4, 27, 15),
        ),
        isFalse,
      );
    });

    test('additionalSlot 범위 내 → true', () {
      final av = _availability(
        [],
        exceptions: [
          _exception(
            type: ExceptionType.additionalSlot,
            startDate: DateTime(2026, 4, 27),
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      expect(
        isAdditionalOpenSlot(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 15, 30),
        ),
        isTrue,
      );
    });

    test('additionalSlot 시작 정각 → true (inclusive)', () {
      final av = _availability(
        [],
        exceptions: [
          _exception(
            type: ExceptionType.additionalSlot,
            startDate: DateTime(2026, 4, 27),
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      expect(
        isAdditionalOpenSlot(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 15),
        ),
        isTrue,
      );
    });

    test('additionalSlot 종료 정각 → false (exclusive)', () {
      final av = _availability(
        [],
        exceptions: [
          _exception(
            type: ExceptionType.additionalSlot,
            startDate: DateTime(2026, 4, 27),
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      expect(
        isAdditionalOpenSlot(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 16),
        ),
        isFalse,
      );
    });

    test('다른 날짜 → false', () {
      final av = _availability(
        [],
        exceptions: [
          _exception(
            type: ExceptionType.additionalSlot,
            startDate: DateTime(2026, 4, 27),
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      expect(
        isAdditionalOpenSlot(
          availability: av,
          slotStart: DateTime(2026, 4, 28, 15, 30),
        ),
        isFalse,
      );
    });

    test('startTime/endTime 미설정인 additionalSlot 무시', () {
      final av = _availability(
        [],
        exceptions: [
          _exception(
            type: ExceptionType.additionalSlot,
            startDate: DateTime(2026, 4, 27),
            // startTime/endTime 없음
          ),
        ],
      );
      expect(
        isAdditionalOpenSlot(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 15),
        ),
        isFalse,
      );
    });

    test('vacation/holiday 예외는 무시 (additionalSlot만 처리)', () {
      final av = _availability(
        [],
        exceptions: [
          _exception(
            type: ExceptionType.vacation,
            startDate: DateTime(2026, 4, 27),
            endDate: DateTime(2026, 5, 3),
            startTime: '15:00',
            endTime: '16:00',
          ),
        ],
      );
      expect(
        isAdditionalOpenSlot(
          availability: av,
          slotStart: DateTime(2026, 4, 27, 15, 30),
        ),
        isFalse,
      );
    });
  });
}
