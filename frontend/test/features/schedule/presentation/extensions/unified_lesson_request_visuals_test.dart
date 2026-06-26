import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/schedule/domain/entities/unified_lesson_request.dart';
import 'package:lessonaza/features/schedule/presentation/extensions/unified_lesson_request_visuals.dart';

void main() {
  group('unified lesson request enum visuals', () {
    test('maps request type labels in presentation', () {
      expect(LessonRequestType.trial.label, '체험레슨');
      expect(LessonRequestType.regular.label, '정규레슨');
      expect(LessonRequestType.package.label, '회차권');
    });

    test('maps goal and experience labels in presentation', () {
      expect(UnifiedLessonGoal.hobby.label, '취미');
      expect(UnifiedLessonGoal.exam.label, '입시');
      expect(UnifiedLessonGoal.major.label, '전공');
      expect(UnifiedLessonGoal.other.label, '기타');

      expect(UnifiedExperienceLevel.beginner.label, '초급');
      expect(UnifiedExperienceLevel.intermediate.label, '중급');
      expect(UnifiedExperienceLevel.advanced.label, '고급');
    });
  });

  group('TimeSlotOptionVisualX', () {
    test('formats display labels in presentation', () {
      final dated = TimeSlotOption(
        id: 'slot_1',
        dayOfWeek: 5,
        date: DateTime(2026, 4, 5),
        startTime: '14:00',
        endTime: '15:00',
      );
      final weekly = TimeSlotOption(
        id: 'slot_2',
        dayOfWeek: 5,
        startTime: '14:00',
        endTime: '15:00',
      );

      expect(dated.dayLabel, '토');
      expect(dated.displayLabel, '4/5(토) 14:00 ~ 15:00');
      expect(weekly.displayLabel, '토 14:00 ~ 15:00');
    });
  });

  group('PreferredTimeSlotVisualX', () {
    test('formats display labels in presentation', () {
      final dated = PreferredTimeSlot(
        priority: 1,
        date: DateTime(2026, 3, 25),
        startTime: '10:00',
        endTime: '11:00',
      );
      const weekly = PreferredTimeSlot(
        priority: 2,
        dayOfWeek: 3,
        startTime: '16:00',
        endTime: '17:00',
      );
      const timeOnly = PreferredTimeSlot(
        priority: 3,
        startTime: '18:00',
        endTime: '19:00',
      );

      expect(dated.displayLabel, '3/25(수) 10:00 ~ 11:00');
      expect(weekly.displayLabel, '목 16:00 ~ 17:00');
      expect(timeOnly.displayLabel, '18:00 ~ 19:00');
    });
  });

  group('UnifiedLessonRequestVisualX', () {
    test('maps type display and preferred day labels in presentation', () {
      final request = UnifiedLessonRequest(
        id: 'req_1',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        type: LessonRequestType.regular,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        preferredDay: 3,
        createdAt: DateTime(2026, 3, 1),
      );

      expect(request.typeDisplayLabel, '정규레슨');
      expect(
        request.copyWith(isReturningStudent: true).typeDisplayLabel,
        '재수강',
      );
      expect(request.preferredDayLabel, '목요일');
      final noPreferredDay = UnifiedLessonRequest(
        id: 'req_2',
        studentId: 'student_1',
        teacherId: 'teacher_1',
        type: LessonRequestType.regular,
        instrument: '바이올린',
        goal: UnifiedLessonGoal.hobby,
        experience: UnifiedExperienceLevel.beginner,
        createdAt: DateTime(2026, 3, 1),
      );
      expect(noPreferredDay.preferredDayLabel, isNull);
    });

    test(
      'negotiating list-chip and status label share the same base (#547)',
      () {
        final request = UnifiedLessonRequest(
          id: 'req_neg',
          studentId: 'student_1',
          teacherId: 'teacher_1',
          type: LessonRequestType.regular,
          instrument: '바이올린',
          goal: UnifiedLessonGoal.hobby,
          experience: UnifiedExperienceLevel.beginner,
          status: UnifiedRequestStatus.negotiating,
          currentRound: 2,
          createdAt: DateTime(2026, 3, 1),
        );

        // Detail/short label has no round; chip enriches with the round but
        // both must read the same base phrase so list and detail never drift.
        expect(request.status.label, '시간 조율 중');
        expect(request.statusChipLabel, '시간 조율 중 (2회차)');
        expect(request.statusChipLabel, startsWith(request.status.label));

        // When the round is unknown the chip collapses to the exact base label.
        final noRound = request.copyWith(currentRound: 0);
        expect(noRound.statusChipLabel, noRound.status.label);
      },
    );
  });
}
