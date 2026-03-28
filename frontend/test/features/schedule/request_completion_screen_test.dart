import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/screens/request_completion_screen.dart';

void main() {
  group('RequestCompletionParams', () {
    test('stores all required fields', () {
      final params = RequestCompletionParams(
        teacherName: '김선생님',
        instrument: '바이올린',
        lessonType: LessonRequestType.trial,
        preferredSlots: [
          PreferredTimeSlot(
            priority: 1,
            date: DateTime(2026, 3, 25),
            dayOfWeek: 2,
            startTime: '10:00',
            endTime: '11:00',
          ),
          PreferredTimeSlot(
            priority: 2,
            date: DateTime(2026, 3, 24),
            dayOfWeek: 1,
            startTime: '14:00',
            endTime: '15:00',
          ),
        ],
        duration: 60,
      );

      expect(params.teacherName, '김선생님');
      expect(params.instrument, '바이올린');
      expect(params.lessonType, LessonRequestType.trial);
      expect(params.preferredSlots.length, 2);
      expect(params.duration, 60);
    });

    test('lesson type label is correct', () {
      expect(LessonRequestType.trial.label, '체험레슨');
      expect(LessonRequestType.regular.label, '정규레슨');
    });

    test('preferred slot displayLabel for trial', () {
      final slot = PreferredTimeSlot(
        priority: 1,
        date: DateTime(2026, 3, 25), // Wednesday
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      );

      expect(slot.displayLabel, '3/25(수) 10:00');
    });

    test('preferred slot displayLabel for regular', () {
      const slot = PreferredTimeSlot(
        priority: 1,
        dayOfWeek: 3,
        startTime: '16:00',
        endTime: '17:00',
      );

      expect(slot.displayLabel, '매주 목요일 16:00');
    });
  });

  group('Step data validation', () {
    test('completion screen has 5 steps', () {
      // The 5 steps defined in spec:
      // 1. 레슨 신청 완료
      // 2. 선생님이 시간 확인
      // 3. 시간 확정 후 입금
      // 4. 선생님이 수강권 발급
      // 5. 레슨 시작!
      const expectedSteps = 5;
      // Access via static field
      expect(RequestCompletionScreen.stepCount, expectedSteps);
    });
  });
}
