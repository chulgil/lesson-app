import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/booking/presentation/extensions/lesson_booking_visual_extensions.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';

void main() {
  group('Lesson booking presentation extensions', () {
    test('provide labels for booking enums', () {
      expect(LessonType.trial.label, '체험');
      expect(ScheduleType.fixed.description, '매주 같은 요일/시간에 레슨');
      expect(BookingStatus.expired.studentMessage, '응답 대기 시간이 지났어요');
      expect(LessonGoal.major.description, '전공자로 실력을 키우고 싶어요');
      expect(ExperienceLevel.some.label, '1-3년');
    });

    test('formats booking display values', () {
      final booking = LessonBooking(
        id: 'booking-1',
        teacherId: 'teacher-1',
        teacherName: '김선생',
        studentName: '이지훈',
        lessonType: LessonType.trial,
        status: BookingStatus.changeRequested,
        lessonDate: DateTime(2026, 3, 27),
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 14, minute: 45),
        fee: 50000,
        createdAt: DateTime(2026, 3, 1),
        requestedDate: DateTime(2026, 3, 28),
        requestedStartTime: const ClockTime(hour: 16, minute: 0),
        requestedEndTime: const ClockTime(hour: 17, minute: 0),
      );

      expect(booking.formattedDate, '3/27(금)');
      expect(booking.fullFormattedDate, '2026년 3월 27일 금요일');
      expect(booking.timeRange, '14:00 - 14:45');
      expect(booking.formattedFee, '50,000원');
      expect(booking.formattedRequestedDate, '3/28(토)');
      expect(booking.requestedTimeRange, '16:00 - 17:00');
    });

    test('returns student-facing display message for unavailable states', () {
      final booking = _booking(
        status: BookingStatus.unavailable,
        unavailableMessage: defaultUnavailableMessage,
      );
      final expired = _booking(status: BookingStatus.expired);

      expect(booking.displayMessage, defaultUnavailableMessage);
      expect(expired.displayMessage, '응답 대기 시간이 지났어요');
    });

    test('formats schedule option display values', () {
      const option = ScheduleOption(
        id: 'option-1',
        priority: 2,
        dayOfWeek: 3,
        startTime: ClockTime(hour: 10, minute: 0),
        endTime: ClockTime(hour: 11, minute: 0),
        secondDayOfWeek: 5,
        secondStartTime: ClockTime(hour: 14, minute: 0),
        secondEndTime: ClockTime(hour: 15, minute: 0),
      );

      expect(option.priorityLabel, '2순위');
      expect(option.dayName, '수요일');
      expect(option.secondShortDayName, '금');
      expect(option.regularLessonSummary, '수 10:00 - 11:00 + 금 14:00 - 15:00');
    });

    test('formats time slot display values', () {
      final slot = TimeSlot(
        id: 'slot-1',
        dayOfWeek: 5,
        startTime: const ClockTime(hour: 14, minute: 0),
        endTime: const ClockTime(hour: 14, minute: 45),
        specificDate: DateTime(2026, 3, 27),
      );

      expect(slot.dayName, '금');
      expect(slot.fullDayName, '금요일');
      expect(slot.timeRange, '14:00 - 14:45');
      expect(slot.displayLabel, '3/27(금) 14:00 - 14:45');
    });
  });
}

LessonBooking _booking({
  required BookingStatus status,
  String? unavailableMessage,
}) {
  return LessonBooking(
    id: 'booking-$status',
    teacherId: 'teacher-1',
    teacherName: '김선생',
    studentName: '이지훈',
    lessonType: LessonType.trial,
    status: status,
    lessonDate: DateTime(2026, 3, 27),
    startTime: const ClockTime(hour: 14, minute: 0),
    endTime: const ClockTime(hour: 14, minute: 45),
    fee: 50000,
    createdAt: DateTime(2026, 3, 1),
    unavailableMessage: unavailableMessage,
  );
}
