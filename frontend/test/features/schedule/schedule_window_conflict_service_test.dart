import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/schedule/domain/entities/teacher_availability.dart';
import 'package:lessonaza/features/schedule/domain/services/schedule_window_conflict_service.dart';

/// #526 — ScheduleWindowConflictService validates a candidate proposal/booking
/// window against the teacher's OWN schedule (vacation + operating hours),
/// independent of existing lessons. Pure logic, so it is tested directly.
void main() {
  // 2026-07-06 is a Monday (weekday0 = 0); 2026-07-07 is a Tuesday.
  final monday = DateTime(2026, 7, 6);
  final tuesday = DateTime(2026, 7, 7);

  WeeklySchedule mondayHours(String start, String end) => WeeklySchedule(
    id: 'ws-mon',
    dayOfWeek: 0, // Monday
    startTime: start,
    endTime: end,
    createdAt: DateTime(2026, 1, 1),
  );

  TimeException vacation({
    required DateTime startDate,
    required DateTime endDate,
    String? startTime,
    String? endTime,
  }) => TimeException(
    id: 'exc-1',
    type: ExceptionType.vacation,
    startDate: startDate,
    endDate: endDate,
    startTime: startTime,
    endTime: endTime,
    createdAt: DateTime(2026, 1, 1),
  );

  TeacherAvailability availability({
    List<WeeklySchedule> weeklySchedules = const [],
    List<TimeException> exceptions = const [],
  }) => TeacherAvailability(
    id: 't1',
    teacherId: 't1',
    weeklySchedules: weeklySchedules,
    exceptions: exceptions,
    createdAt: DateTime(2026, 1, 1),
  );

  group('null availability', () {
    test('treats missing availability as no conflict', () {
      final result = ScheduleWindowConflictService.check(
        availability: null,
        date: monday,
        startMinutes: 14 * 60,
        endMinutes: 15 * 60,
      );
      expect(result, ScheduleWindowConflict.none);
    });
  });

  group('operating hours', () {
    test('window fully inside operating hours → none', () {
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
        ),
        date: monday,
        startMinutes: 14 * 60,
        endMinutes: 15 * 60,
      );
      expect(result, ScheduleWindowConflict.none);
    });

    test('window starting before operating hours → outside', () {
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
        ),
        date: monday,
        startMinutes: 9 * 60,
        endMinutes: 10 * 60,
      );
      expect(result, ScheduleWindowConflict.outsideOperatingHours);
    });

    test('window ending after operating hours → outside', () {
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
        ),
        date: monday,
        startMinutes: 17 * 60 + 30,
        endMinutes: 18 * 60 + 30,
      );
      expect(result, ScheduleWindowConflict.outsideOperatingHours);
    });

    test('boundary: window flush against hours edges → none', () {
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
        ),
        date: monday,
        startMinutes: 10 * 60,
        endMinutes: 11 * 60,
      );
      expect(result, ScheduleWindowConflict.none);
    });

    test('weekday with no active schedule → outside', () {
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
        ),
        // Tuesday has no schedule configured.
        date: tuesday,
        startMinutes: 14 * 60,
        endMinutes: 15 * 60,
      );
      expect(result, ScheduleWindowConflict.outsideOperatingHours);
    });
  });

  group('vacation', () {
    test('whole-day vacation blocks any in-hours window', () {
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
          exceptions: [vacation(startDate: monday, endDate: monday)],
        ),
        date: monday,
        startMinutes: 14 * 60,
        endMinutes: 15 * 60,
      );
      expect(result, ScheduleWindowConflict.vacation);
    });

    test('partial-day vacation blocks only overlapping window', () {
      final avail = availability(
        weeklySchedules: [mondayHours('10:00', '18:00')],
        exceptions: [
          vacation(
            startDate: monday,
            endDate: monday,
            startTime: '13:00',
            endTime: '16:00',
          ),
        ],
      );
      // Overlaps the blocked 13:00–16:00 window.
      expect(
        ScheduleWindowConflictService.check(
          availability: avail,
          date: monday,
          startMinutes: 14 * 60,
          endMinutes: 15 * 60,
        ),
        ScheduleWindowConflict.vacation,
      );
      // Outside the blocked window but still in operating hours → none.
      expect(
        ScheduleWindowConflictService.check(
          availability: avail,
          date: monday,
          startMinutes: 10 * 60,
          endMinutes: 11 * 60,
        ),
        ScheduleWindowConflict.none,
      );
    });

    test('vacation takes precedence over outside-hours', () {
      // Window is BOTH inside a whole-day vacation AND outside operating hours.
      final result = ScheduleWindowConflictService.check(
        availability: availability(
          weeklySchedules: [mondayHours('10:00', '18:00')],
          exceptions: [vacation(startDate: monday, endDate: monday)],
        ),
        date: monday,
        startMinutes: 20 * 60,
        endMinutes: 21 * 60,
      );
      expect(result, ScheduleWindowConflict.vacation);
    });
  });
}
