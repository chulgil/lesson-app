import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/getting_started_card.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

void main() {
  testWidgets('getting started card advances through all five steps', (
    tester,
  ) async {
    await _pumpGettingStarted(tester);

    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('학생 등록하기'), findsOneWidget);

    await _pumpGettingStarted(tester, hasStudents: true);

    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('학생 등록하기'), findsNothing);
    expect(find.text('레슨 일정 만들기'), findsOneWidget);

    await _pumpGettingStarted(tester, hasStudents: true, hasLessons: true);

    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    expect(find.text('레슨 일정 만들기'), findsNothing);
    expect(find.text('첫 레슨 완료하기'), findsOneWidget);

    await _pumpGettingStarted(
      tester,
      hasStudents: true,
      hasLessons: true,
      hasCompletedLesson: true,
    );

    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('첫 레슨 완료하기'), findsNothing);
    expect(find.text('첫 레슨 노트 작성'), findsOneWidget);

    await _pumpGettingStarted(
      tester,
      hasStudents: true,
      hasLessons: true,
      hasCompletedLesson: true,
      hasLessonNotes: true,
    );

    expect(find.text('GETTING STARTED'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('첫 레슨 노트 작성'), findsNothing);
    expect(find.text('전화번호 인증하기'), findsOneWidget);

    await _pumpGettingStarted(
      tester,
      hasStudents: true,
      hasLessons: true,
      hasCompletedLesson: true,
      hasLessonNotes: true,
      isPhoneVerified: true,
    );

    expect(find.text('GETTING STARTED'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpGettingStarted(
  WidgetTester tester, {
  bool hasStudents = false,
  bool hasLessons = false,
  bool hasCompletedLesson = false,
  bool hasLessonNotes = false,
  bool isPhoneVerified = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        homeStudentsProvider.overrideWith(
          (ref) async =>
              hasStudents
                  ? [
                    Student(
                      id: 'student-1',
                      name: '이서연',
                      instrument: '피아노',
                      createdAt: DateTime(2026),
                    ),
                  ]
                  : <Student>[],
        ),
        homeHasLessonsProvider.overrideWith((ref) => hasLessons),
        homeHasCompletedLessonProvider.overrideWith(
          (ref) => hasCompletedLesson,
        ),
        homeHasLessonNotesProvider.overrideWith((ref) => hasLessonNotes),
        homeTeacherPhoneVerifiedProvider.overrideWith((ref) => isPhoneVerified),
        homeFirstLessonIdProvider.overrideWith(
          (ref) => hasLessons ? 'lesson-1' : null,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(child: GettingStartedCard()),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}
