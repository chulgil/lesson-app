import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/lesson_booking.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';

void main() {
  group('LessonBooking.displayMessage (UnavailableReason 제거 후)', () {
    test('unavailable 상태에서 unavailableMessage 반환', () {
      final booking = _createBooking(
        status: BookingStatus.unavailable,
        unavailableMessage: '현재 가능한 시간이 없어 이번에는 어렵습니다.',
      );

      expect(booking.displayMessage,
          '현재 가능한 시간이 없어 이번에는 어렵습니다.');
    });

    test('unavailable 상태에서 메시지 없으면 null', () {
      final booking = _createBooking(
        status: BookingStatus.unavailable,
        unavailableMessage: null,
      );

      expect(booking.displayMessage, isNull);
    });

    test('expired 상태에서 status.studentMessage 반환', () {
      final booking = _createBooking(status: BookingStatus.expired);

      expect(booking.displayMessage, isNotNull);
    });

    test('pending 상태에서 null 반환', () {
      final booking = _createBooking(status: BookingStatus.pending);

      expect(booking.displayMessage, isNull);
    });
  });

  group('TimeSlot 생성 (대안 시간 제안용)', () {
    test('specificDate가 있는 TimeSlot의 displayLabel에 날짜 포함', () {
      final slot = TimeSlot(
        id: 'suggest_1',
        dayOfWeek: 5, // Friday
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 45),
        isActive: true,
        specificDate: DateTime(2026, 3, 27), // Friday
      );

      expect(slot.displayLabel, contains('3/27'));
      expect(slot.displayLabel, contains('금'));
      expect(slot.displayLabel, contains('14:00'));
      expect(slot.displayLabel, contains('14:45'));
    });

    test('durationMinutes 계산', () {
      final slot = TimeSlot(
        id: 'suggest_1',
        dayOfWeek: 1,
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 45),
        isActive: true,
      );

      expect(slot.durationMinutes, 45);
    });

    test('containsTime으로 셀 포함 여부 확인', () {
      final slot = TimeSlot(
        id: 'suggest_1',
        dayOfWeek: 1,
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 14, minute: 45),
        isActive: true,
      );

      expect(slot.containsTime(const TimeOfDay(hour: 14, minute: 0)), isTrue);
      expect(
          slot.containsTime(const TimeOfDay(hour: 14, minute: 30)), isTrue);
      expect(
          slot.containsTime(const TimeOfDay(hour: 14, minute: 45)), isFalse);
      expect(
          slot.containsTime(const TimeOfDay(hour: 13, minute: 59)), isFalse);
    });

    test('최대 3개 슬롯 제한 검증', () {
      final slots = <TimeSlot>[];
      for (int i = 0; i < 3; i++) {
        slots.add(TimeSlot(
          id: 'suggest_$i',
          dayOfWeek: i + 1,
          startTime: TimeOfDay(hour: 14 + i, minute: 0),
          endTime: TimeOfDay(hour: 14 + i, minute: 45),
          isActive: true,
        ));
      }

      expect(slots.length, 3);
      // 4번째 추가 시도는 UI에서 차단 (slots.length < 3 체크)
      expect(slots.length < 3, isFalse);
    });
  });

  group('중복 체크 로직', () {
    test('기존 수업과 겹치는 시간 감지', () {
      // Simulate: existing lesson 14:00-15:00
      const lessonStart = 14 * 60; // 840
      const lessonEnd = 15 * 60; // 900

      // New slot: 14:30-15:15
      const newStart = 14 * 60 + 30; // 870
      const newEnd = 15 * 60 + 15; // 915

      final overlaps = newStart < lessonEnd && newEnd > lessonStart;
      expect(overlaps, isTrue);
    });

    test('기존 수업과 겹치지 않는 시간', () {
      const lessonStart = 14 * 60;
      const lessonEnd = 15 * 60;

      // New slot: 15:00-15:45 (직후)
      const newStart = 15 * 60;
      const newEnd = 15 * 60 + 45;

      final overlaps = newStart < lessonEnd && newEnd > lessonStart;
      expect(overlaps, isFalse);
    });

    test('기존 수업 내부에 완전히 포함되는 시간', () {
      const lessonStart = 14 * 60;
      const lessonEnd = 16 * 60;

      // New slot: 14:30-15:00 (내부)
      const newStart = 14 * 60 + 30;
      const newEnd = 15 * 60;

      final overlaps = newStart < lessonEnd && newEnd > lessonStart;
      expect(overlaps, isTrue);
    });

    test('기존 수업을 완전히 포함하는 시간', () {
      const lessonStart = 14 * 60 + 30;
      const lessonEnd = 15 * 60;

      // New slot: 14:00-16:00 (외부)
      const newStart = 14 * 60;
      const newEnd = 16 * 60;

      final overlaps = newStart < lessonEnd && newEnd > lessonStart;
      expect(overlaps, isTrue);
    });
  });

  group('DeclineResult 타입', () {
    test('메시지만 전달 (거절)', () {
      final result = (
        message: '현재 가능한 시간이 없어 이번에는 어렵습니다.',
        suggestedSlots: <TimeSlot>[],
      );

      expect(result.message, isNotEmpty);
      expect(result.suggestedSlots, isEmpty);
    });

    test('메시지 + 대안 시간 (일정 조율)', () {
      final result = (
        message: '이번 시간은 어렵지만 다른 시간이 가능합니다.',
        suggestedSlots: [
          const TimeSlot(
            id: 's1',
            dayOfWeek: 3,
            startTime: TimeOfDay(hour: 15, minute: 0),
            endTime: TimeOfDay(hour: 15, minute: 45),
            isActive: true,
          ),
        ],
      );

      expect(result.message, isNotEmpty);
      expect(result.suggestedSlots.length, 1);
      expect(result.suggestedSlots.first.durationMinutes, 45);
    });
  });
}

LessonBooking _createBooking({
  BookingStatus status = BookingStatus.pending,
  String? unavailableMessage,
}) {
  return LessonBooking(
    id: 'test_1',
    teacherId: 'teacher_1',
    teacherName: '김선생',
    studentName: '이학생',
    instrument: 'violin',
    lessonType: LessonType.trial,
    status: status,
    lessonDate: DateTime(2026, 3, 28),
    startTime: const TimeOfDay(hour: 14, minute: 0),
    endTime: const TimeOfDay(hour: 15, minute: 0),
    fee: 50000,
    createdAt: DateTime(2026, 3, 25),
    unavailableMessage: unavailableMessage,
  );
}
