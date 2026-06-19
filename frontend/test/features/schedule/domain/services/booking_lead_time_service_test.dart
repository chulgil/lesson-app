// #850 — BookingLeadTimeService 순수 필터 규칙.
// 같은 술어(slot.startDateTime < now + minBookingHours)가 슬롯 프로바이더와
// lesson_booking_screen submit 방어 양쪽에서 재사용된다.

import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/domain/services/booking_lead_time_service.dart';

void main() {
  // 기준 현재시각: 2026-06-10 12:00.
  final now = DateTime(2026, 6, 10, 12, 0);

  AvailabilitySlot slotAt(DateTime start) => AvailabilitySlot(
    id: start.toIso8601String(),
    teacherId: 't1',
    date: DateTime(start.year, start.month, start.day),
    startTime: ClockTime(hour: start.hour, minute: start.minute),
    endTime: ClockTime(hour: start.hour + 1, minute: start.minute),
    durationMinutes: 60,
  );

  final imminent = slotAt(DateTime(2026, 6, 10, 15, 0)); // +3h
  final atCutoff = slotAt(DateTime(2026, 6, 11, 12, 0)); // +24h (경계)
  final farFuture = slotAt(DateTime(2026, 6, 12, 10, 0)); // +46h
  final all = [imminent, atCutoff, farFuture];

  group('BookingLeadTimeService.filterByLeadTime', () {
    test('minBookingHours == 0 → 전부 노출 (제한 없음)', () {
      final result = BookingLeadTimeService.filterByLeadTime(
        slots: all,
        minBookingHours: 0,
        now: now,
      );
      expect(result, equals(all));
    });

    test('minBookingHours < 0 → 방어적으로 필터 없음', () {
      final result = BookingLeadTimeService.filterByLeadTime(
        slots: all,
        minBookingHours: -5,
        now: now,
      );
      expect(result, equals(all));
    });

    test('minBookingHours == 24 → 임박 슬롯 제외, 경계는 유지', () {
      final result = BookingLeadTimeService.filterByLeadTime(
        slots: all,
        minBookingHours: 24,
        now: now,
      );
      // +3h 슬롯은 cutoff(+24h) 이전 → 제외.
      expect(result, isNot(contains(imminent)));
      // 정확히 cutoff 인 슬롯은 "before" 아님 → 유지.
      expect(result, contains(atCutoff));
      expect(result, contains(farFuture));
      expect(result.length, 2);
    });

    test('빈 슬롯 → 빈 결과', () {
      final result = BookingLeadTimeService.filterByLeadTime(
        slots: const [],
        minBookingHours: 24,
        now: now,
      );
      expect(result, isEmpty);
    });
  });
}
