import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/home/presentation/providers/home_lesson_summary_provider.dart';
import 'package:lessonaza/features/home/presentation/widgets/getting_started_card.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';

void main() {
  testWidgets(
    'getting started card remains visible until all five steps finish',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeStudentsProvider.overrideWith(
              (ref) async => [
                Student(
                  id: 'student-1',
                  name: '이서연',
                  instrument: '피아노',
                  createdAt: DateTime(2026),
                ),
              ],
            ),
            homeHasLessonsProvider.overrideWith((ref) => true),
            homeHasCompletedLessonProvider.overrideWith((ref) => false),
            homeHasLessonNotesProvider.overrideWith((ref) => false),
            homeTeacherPhoneVerifiedProvider.overrideWith((ref) => false),
            homeFirstLessonIdProvider.overrideWith((ref) => 'lesson-1'),
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

      expect(find.text('GETTING STARTED'), findsOneWidget);
      expect(find.text('학생 등록하기'), findsOneWidget);
      expect(find.text('레슨 일정 만들기'), findsOneWidget);
      expect(find.text('첫 레슨 완료하기'), findsOneWidget);
      expect(find.text('첫 레슨 노트 작성'), findsOneWidget);
      expect(find.text('전화번호 인증하기'), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('getting started card hides after all five steps finish', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStudentsProvider.overrideWith(
            (ref) async => [
              Student(
                id: 'student-1',
                name: '이서연',
                instrument: '피아노',
                createdAt: DateTime(2026),
              ),
            ],
          ),
          homeHasLessonsProvider.overrideWith((ref) => true),
          homeHasCompletedLessonProvider.overrideWith((ref) => true),
          homeHasLessonNotesProvider.overrideWith((ref) => true),
          homeTeacherPhoneVerifiedProvider.overrideWith((ref) => true),
          homeFirstLessonIdProvider.overrideWith((ref) => 'lesson-1'),
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

    expect(find.text('GETTING STARTED'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
