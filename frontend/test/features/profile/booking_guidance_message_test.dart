import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/profile/domain/entities/teacher_settings.dart';

void main() {
  group('TeacherSettings.bookingGuidanceMessage', () {
    test('defaults to null when not set', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
      );

      expect(settings.bookingGuidanceMessage, isNull);
    });

    test('stores custom message when set', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
        bookingGuidanceMessage: '평일 오전에 연락주시면 빠른 상담 가능합니다.',
      );

      expect(settings.bookingGuidanceMessage, '평일 오전에 연락주시면 빠른 상담 가능합니다.');
    });

    test('copyWith updates bookingGuidanceMessage', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = settings.copyWith(
        bookingGuidanceMessage: '주말 레슨도 가능합니다.',
      );

      expect(updated.bookingGuidanceMessage, '주말 레슨도 가능합니다.');
      expect(updated.id, 'teacher_1'); // other fields preserved
    });

    test('copyWith can clear message to null', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
        bookingGuidanceMessage: '커스텀 메시지',
      );

      // Setting to empty string acts as "clear"
      final cleared = settings.copyWith(bookingGuidanceMessage: '');

      expect(cleared.bookingGuidanceMessage, '');
    });

    test('effectiveGuidanceMessage returns default when null', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
      );

      expect(settings.effectiveGuidanceMessage,
          '희망레슨시간은 상담가능하니 편하게 메시지 주세요.');
    });

    test('effectiveGuidanceMessage returns default when empty', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
        bookingGuidanceMessage: '',
      );

      expect(settings.effectiveGuidanceMessage,
          '희망레슨시간은 상담가능하니 편하게 메시지 주세요.');
    });

    test('effectiveGuidanceMessage returns custom when set', () {
      final settings = TeacherSettings(
        id: 'teacher_1',
        instruments: ['바이올린'],
        createdAt: DateTime(2026, 1, 1),
        bookingGuidanceMessage: '평일 오전에 연락주세요.',
      );

      expect(settings.effectiveGuidanceMessage, '평일 오전에 연락주세요.');
    });
  });
}
