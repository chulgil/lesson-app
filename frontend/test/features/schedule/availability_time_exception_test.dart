import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/data/repositories/mock_teacher_availability_repository.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';

// ═══════════════════════════════════════════════════════════════════════════
// P1-1 Phase B — TimeException × travel_time §7 4 케이스 검증
// Spec: docs/specs/schedule/travel_time_spec.md §7.2
// ═══════════════════════════════════════════════════════════════════════════
//
// 현재 동작 (`_computeSlotsForDate` line 524-529):
//   exception.containsDate(date) === true → return [] (하루 전체 차단)
//
// 기대 동작:
//   - holiday/vacation 에 startTime/endTime 이 있으면 해당 시간대만 차단
//   - 차단 시간대에 incoming travelTime 이 침범하는 슬롯도 차단
//   - 차단 시간대 직후 outgoing travelTime 만큼 슬롯 시작 가능
//   - startTime/endTime 모두 null 이면 기존대로 하루 전체 차단 (역호환)
// ═══════════════════════════════════════════════════════════════════════════

const _teacherId = 'test_teacher';

DateTime _nextWeekday(DateTime from, int weekday) {
  var date = from.add(const Duration(days: 1));
  while (date.weekday != weekday) {
    date = date.add(const Duration(days: 1));
  }
  return DateTime(date.year, date.month, date.day);
}

WeeklySchedule _allDaySchedule(int dayOfWeek0Based) => WeeklySchedule(
  id: 'sched_$dayOfWeek0Based',
  dayOfWeek: dayOfWeek0Based,
  startTime: '10:00',
  endTime: '18:00',
  createdAt: DateTime(2026, 1, 1),
);

TimeException _holiday(DateTime date, {String? startTime, String? endTime}) =>
    TimeException(
      id: 'ex_${date.toIso8601String()}_${startTime ?? "all"}',
      type: ExceptionType.holiday,
      startDate: date,
      endDate: date,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime(2026, 1, 1),
    );

TimeException _vacation(DateTime date, {String? startTime, String? endTime}) =>
    TimeException(
      id: 'ex_v_${date.toIso8601String()}_${startTime ?? "all"}',
      type: ExceptionType.vacation,
      startDate: date,
      endDate: date,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime(2026, 1, 1),
    );

TeacherAvailability _availability({
  required List<TimeException> exceptions,
  int dayOfWeek0Based = 0, // Monday
  int slotDurationMinutes = 60,
  int slotStartInterval = 60,
  int breakTimeBetweenLessons = 10,
}) => TeacherAvailability(
  id: 'av_test',
  teacherId: _teacherId,
  slotDurationMinutes: slotDurationMinutes,
  slotStartInterval: slotStartInterval,
  breakTimeBetweenLessons: breakTimeBetweenLessons,
  weeklySchedules: [_allDaySchedule(dayOfWeek0Based)],
  exceptions: exceptions,
  createdAt: DateTime(2026, 1, 1),
);

bool _hasSlotAt(List<AvailabilitySlot> slots, int hour, int minute) {
  return slots.any(
    (s) =>
        s.startTime.hour == hour &&
        s.startTime.minute == minute &&
        s.status == AvailabilitySlotStatus.available,
  );
}

void main() {
  late MockTeacherAvailabilityRepository repo;
  late DateTime targetDate; // Future Monday

  setUp(() async {
    repo = MockTeacherAvailabilityRepository();
    // Pick the next Monday in the future to avoid past-time skip logic.
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    targetDate = _nextWeekday(tomorrow, DateTime.monday);
  });

  group('§7.2 Case 1 — 부분 차단 holiday (startTime/endTime)', () {
    test('holiday 13:00-14:00 → 13:00 슬롯만 차단, 다른 슬롯은 유지', () async {
      await repo.saveAvailability(
        _availability(
          exceptions: [
            _holiday(targetDate, startTime: '13:00', endTime: '14:00'),
          ],
        ),
      );

      final slots = await repo.getAvailableSlotsForDate(_teacherId, targetDate);

      // 10:00, 11:00, 12:00 → 모두 available
      expect(
        _hasSlotAt(slots, 10, 0),
        isTrue,
        reason: '10시 슬롯은 차단 시간대(13-14) 밖, available 이어야 함',
      );
      expect(_hasSlotAt(slots, 11, 0), isTrue);
      expect(_hasSlotAt(slots, 12, 0), isTrue);

      // 13:00 슬롯 → 차단 (13:00-14:00 과 겹침)
      expect(
        _hasSlotAt(slots, 13, 0),
        isFalse,
        reason: '13시 슬롯은 차단 시간대와 겹침, 제외되어야 함',
      );

      // 14:00, 15:00, 16:00, 17:00 → available
      expect(
        _hasSlotAt(slots, 14, 0),
        isTrue,
        reason: '14시 슬롯은 차단 종료, available',
      );
      expect(_hasSlotAt(slots, 15, 0), isTrue);
      expect(_hasSlotAt(slots, 16, 0), isTrue);
      expect(_hasSlotAt(slots, 17, 0), isTrue);
    });
  });

  group('§7.2 Case 2 — 반차 vacation (오후만 휴무)', () {
    test('vacation 12:00-18:00 → 오전 슬롯 유지, 오후 차단', () async {
      await repo.saveAvailability(
        _availability(
          exceptions: [
            _vacation(targetDate, startTime: '12:00', endTime: '18:00'),
          ],
        ),
      );

      final slots = await repo.getAvailableSlotsForDate(_teacherId, targetDate);

      // 10:00, 11:00 → available (오전, 차단 시간대 12-18 밖)
      expect(_hasSlotAt(slots, 10, 0), isTrue, reason: '10시는 오전, 반차 영향 없음');
      expect(_hasSlotAt(slots, 11, 0), isTrue);

      // 12:00 ~ 17:00 → 모두 차단
      expect(_hasSlotAt(slots, 12, 0), isFalse, reason: '12시부터 반차 시작');
      expect(_hasSlotAt(slots, 13, 0), isFalse);
      expect(_hasSlotAt(slots, 14, 0), isFalse);
      expect(_hasSlotAt(slots, 15, 0), isFalse);
      expect(_hasSlotAt(slots, 16, 0), isFalse);
      expect(_hasSlotAt(slots, 17, 0), isFalse);
    });
  });

  group('§7.2 Case 3 — 차단 경계 × incoming travelTime 침범', () {
    test('holiday 14:00-15:00 + student travelTime 20분 → '
        '13:30 슬롯의 effective range[13:10-14:30] 가 차단 영역과 겹침 → 제외', () async {
      await repo.saveAvailability(
        _availability(
          exceptions: [
            _holiday(targetDate, startTime: '14:00', endTime: '15:00'),
          ],
          slotStartInterval: 30, // 30분 간격으로 슬롯 생성
        ),
      );

      // student_1 = 20분 travelTime (mock 기본 설정)
      final slots = await repo.getAvailableSlotsForDate(
        _teacherId,
        targetDate,
        currentStudentId: 'student_1',
      );

      // 13:30 슬롯: 시작 13:30, travelTime 20분 → effective start 13:10, end 14:30
      // 차단 14:00-15:00 과 겹침 → 차단되어야 함
      expect(
        _hasSlotAt(slots, 13, 30),
        isFalse,
        reason: '13:30 슬롯은 incoming travel 침범으로 차단되어야 함',
      );

      // 13:00 슬롯: 시작 13:00, end 14:00 → 차단 시작과 정확히 끝남, 겹침 없음
      // (newEffectiveEnd=14:00, blockedStart=14:00 → 14<14 거짓이므로 OK)
      expect(
        _hasSlotAt(slots, 13, 0),
        isTrue,
        reason: '13:00 슬롯(end=14:00)은 차단 시작과 만남, 겹침 없음',
      );

      // 14:00, 14:30 슬롯 → 차단 시간대 안에 있으니 차단
      expect(_hasSlotAt(slots, 14, 0), isFalse);
      expect(_hasSlotAt(slots, 14, 30), isFalse);
    });
  });

  group('§7.2 Case 4 — 차단 종료 직후 outgoing travelTime', () {
    test('holiday 12:00-13:00 + student travelTime 30분 → '
        '13:00 슬롯의 effective start 12:30 가 차단 영역에 침범 → 제외, '
        '13:30+ 는 사용 가능', () async {
      await repo.saveAvailability(
        _availability(
          exceptions: [
            _holiday(targetDate, startTime: '12:00', endTime: '13:00'),
          ],
          slotStartInterval: 30,
        ),
      );

      // student_4 = 30분 travelTime (mock 기본 설정)
      final slots = await repo.getAvailableSlotsForDate(
        _teacherId,
        targetDate,
        currentStudentId: 'student_4',
      );

      // 13:00 슬롯: travel 30분 → effective start 12:30 < 차단 종료 13:00 → 차단
      expect(
        _hasSlotAt(slots, 13, 0),
        isFalse,
        reason: '13:00 슬롯은 travel 30분 침범으로 차단되어야 함',
      );

      // 13:30 슬롯: effective start 13:00 = 차단 종료 → 겹침 없음
      // (newEffectiveStart=13:00, blockedEnd=13:00 → 13<13 거짓이므로 OK)
      expect(
        _hasSlotAt(slots, 13, 30),
        isTrue,
        reason: '13:30 슬롯(effective start 13:00)은 차단 종료와 만남, OK',
      );
    });
  });

  group('역호환 — startTime/endTime null 이면 하루 전체 차단', () {
    test('holiday 시간 미지정 → 하루 전체 슬롯 0건 (기존 동작 유지)', () async {
      await repo.saveAvailability(
        _availability(
          exceptions: [_holiday(targetDate)], // startTime/endTime 둘 다 null
        ),
      );

      final slots = await repo.getAvailableSlotsForDate(_teacherId, targetDate);

      expect(slots, isEmpty, reason: 'startTime/endTime 미지정 시 기존대로 하루 전체 차단');
    });
  });
}
