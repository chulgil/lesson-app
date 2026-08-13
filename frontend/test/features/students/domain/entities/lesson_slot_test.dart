import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/students/domain/entities/lesson_slot.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // LessonSlot creation & getters
  // ═══════════════════════════════════════════════════════════════════════════

  group('LessonSlot', () {
    test('생성 — 기본 필드', () {
      const slot = LessonSlot(
        dayOfWeek: 1,
        startTime: '14:00',
        endTime: '15:00',
      );
      expect(slot.dayOfWeek, 1);
      expect(slot.startTime, '14:00');
      expect(slot.endTime, '15:00');
    });

    test('copyWith', () {
      const slot = LessonSlot(
        dayOfWeek: 0,
        startTime: '10:00',
        endTime: '11:00',
      );
      final updated = slot.copyWith(
        dayOfWeek: 3,
        startTime: '16:00',
        endTime: '17:00',
      );
      expect(updated.dayOfWeek, 3);
      expect(updated.startTime, '16:00');
      expect(updated.endTime, '17:00');
      // original immutable
      expect(slot.dayOfWeek, 0);
    });

    test('copyWith — 부분 변경', () {
      const slot = LessonSlot(
        dayOfWeek: 1,
        startTime: '14:00',
        endTime: '15:00',
      );
      final updated = slot.copyWith(startTime: '15:00');
      expect(updated.dayOfWeek, 1); // unchanged
      expect(updated.startTime, '15:00');
      expect(updated.endTime, '15:00'); // unchanged
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // ClassMembership.lessonSlots integration (import test)
  //
  // Display formatting (dayLabel/shortLabel/scheduleDisplay) moved to
  // presentation/extensions/student_domain_visuals.dart (#1255) — covered in
  // student_domain_visuals_test.dart, not here.
  // ═══════════════════════════════════════════════════════════════════════════

  group('LessonSlot list utilities', () {
    test('빈 리스트', () {
      const slots = <LessonSlot>[];
      expect(slots.isEmpty, isTrue);
    });

    test('주 2회 — 2개 슬롯', () {
      const slots = [
        LessonSlot(dayOfWeek: 1, startTime: '14:00', endTime: '15:00'),
        LessonSlot(dayOfWeek: 3, startTime: '16:00', endTime: '17:00'),
      ];
      expect(slots.length, 2);
      expect(slots.first.dayOfWeek, 1);
      expect(slots.last.dayOfWeek, 3);
    });
  });
}
