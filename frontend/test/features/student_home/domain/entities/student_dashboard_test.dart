import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/student_home/domain/entities/student_dashboard.dart';

void main() {
  group('StudentTab', () {
    test('home has correct label', () {
      expect(StudentTab.home.label, '홈');
    });

    test('lessons has correct label', () {
      expect(StudentTab.lessons.label, '레슨');
    });

    test('practice has correct label', () {
      expect(StudentTab.practice.label, '연습');
    });

    test('profile has correct label', () {
      expect(StudentTab.profile.label, '프로필');
    });

    test('home has tabIndex 0', () {
      expect(StudentTab.home.tabIndex, 0);
    });

    test('lessons has tabIndex 1', () {
      expect(StudentTab.lessons.tabIndex, 1);
    });

    test('practice has tabIndex 2', () {
      expect(StudentTab.practice.tabIndex, 2);
    });

    test('profile has tabIndex 3', () {
      expect(StudentTab.profile.tabIndex, 3);
    });

    test('tabIndex values are sequential', () {
      for (int i = 0; i < StudentTab.values.length; i++) {
        expect(StudentTab.values[i].tabIndex, i);
      }
    });
  });

  group('WeeklyPracticeStatus', () {
    test('empty status has correct default values', () {
      const status = WeeklyPracticeStatus.empty;
      expect(status.dayLabels, ['월', '화', '수', '목', '금', '토', '일']);
      expect(status.progress.length, 7);
      expect(status.progress.every((p) => p == 0.0), isTrue);
      expect(status.todayIndex, 0);
      expect(status.practicedDays, 0);
      expect(status.totalPracticeTime, Duration.zero);
      expect(status.achievementRate, 0.0);
    });

    test('creates instance with custom values', () {
      const status = WeeklyPracticeStatus(
        dayLabels: ['월', '화', '수', '목', '금', '토', '일'],
        progress: [1.0, 0.8, 0.5, 0.0, 0.0, 0.0, 0.0],
        todayIndex: 3,
        practicedDays: 3,
        totalPracticeTime: Duration(hours: 2, minutes: 30),
        achievementRate: 0.75,
      );

      expect(status.todayIndex, 3);
      expect(status.practicedDays, 3);
      expect(status.totalPracticeTime.inMinutes, 150);
      expect(status.achievementRate, 0.75);
    });
  });

  group('TeacherFeedback', () {
    test('creates instance correctly', () {
      final feedback = TeacherFeedback(
        id: 'feedback_1',
        teacherName: '김선생님',
        teacherInitial: '김',
        feedbackDate: DateTime(2025, 1, 10),
        content: '이번 주 연습 잘 했어요!',
        tags: ['보잉 개선', '예습 필요'],
      );

      expect(feedback.id, 'feedback_1');
      expect(feedback.teacherName, '김선생님');
      expect(feedback.teacherInitial, '김');
      expect(feedback.content, '이번 주 연습 잘 했어요!');
      expect(feedback.tags.length, 2);
    });
  });

  group('NextLessonInfo', () {
    test('creates instance correctly', () {
      final info = NextLessonInfo(
        teacherName: '김선생님',
        teacherInitial: '김',
        instrument: '바이올린',
        lessonDate: DateTime(2025, 1, 15, 14, 0),
        daysUntil: 5,
      );

      expect(info.teacherName, '김선생님');
      expect(info.instrument, '바이올린');
      expect(info.daysUntil, 5);
    });

    test('dDayLabel shows D-Day when daysUntil is 0', () {
      final info = NextLessonInfo(
        teacherName: '김선생님',
        teacherInitial: '김',
        instrument: '바이올린',
        lessonDate: DateTime.now(),
        daysUntil: 0,
      );

      expect(info.dDayLabel, 'D-Day');
    });

    test('dDayLabel shows D-N when daysUntil > 0', () {
      final info = NextLessonInfo(
        teacherName: '김선생님',
        teacherInitial: '김',
        instrument: '바이올린',
        lessonDate: DateTime.now().add(const Duration(days: 3)),
        daysUntil: 3,
      );

      expect(info.dDayLabel, 'D-3');
    });

    test('formattedDate returns correct format', () {
      // Wednesday, January 15, 2025 at 14:00
      final info = NextLessonInfo(
        teacherName: '김선생님',
        teacherInitial: '김',
        instrument: '바이올린',
        lessonDate: DateTime(2025, 1, 15, 14, 0),
        daysUntil: 5,
      );

      expect(info.formattedDate, contains('1월 15일'));
      expect(info.formattedDate, contains('14:00'));
    });
  });
}
