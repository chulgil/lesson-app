import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart'
    show currentTeacherIdProvider;
import 'package:lessonaza/features/practice/data/repositories/mock_practice_item_repository.dart';
import 'package:lessonaza/features/practice/domain/entities/practice_item.dart';
import 'package:lessonaza/features/practice/presentation/providers/practice_item_providers.dart';
import 'package:lessonaza/features/practice/presentation/screens/awaiting_feedback_screen.dart';
import 'package:lessonaza/features/students/domain/entities/student.dart';
import 'package:lessonaza/features/students/students_facade.dart'
    show studentsProvider;

PracticeItem _item({
  required String id,
  required String studentId,
  required String title,
  required int completedHoursAgo,
  String lessonId = 'lesson_x',
}) {
  final now = DateTime.now();
  return PracticeItem(
    id: id,
    lessonId: lessonId,
    studentId: studentId,
    teacherId: 'teacher_1',
    type: PracticeType.repertoire,
    title: title,
    isCompleted: true,
    practiceCount: 1,
    completedAt: now.subtract(Duration(hours: completedHoursAgo)),
    createdAt: now.subtract(const Duration(days: 1)),
  );
}

Student _student(String id, String name) =>
    Student(id: id, name: name, instrument: '피아노', createdAt: DateTime(2026));

Widget _harness(List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: const MaterialApp(home: AwaitingFeedbackScreen()),
);

void main() {
  group('AwaitingFeedbackScreen', () {
    testWidgets('smoke — renders without layout/render exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness([
          awaitingFeedbackProvider.overrideWith(
            (ref) async => [
              _item(
                id: 'a',
                studentId: 's1',
                title: 'Canon A섹션',
                completedHoursAgo: 2,
              ),
            ],
          ),
          studentsProvider.overrideWith((ref) async => [_student('s1', '이서연')]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('groups items by student and shows group header with count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness([
          awaitingFeedbackProvider.overrideWith(
            (ref) async => [
              _item(
                id: 'a',
                studentId: 's1',
                title: 'Canon A섹션',
                completedHoursAgo: 2,
              ),
              _item(
                id: 'b',
                studentId: 's1',
                title: 'G Major 음계',
                completedHoursAgo: 5,
              ),
              _item(
                id: 'c',
                studentId: 's2',
                title: 'Gavotte 통주',
                completedHoursAgo: 1,
              ),
            ],
          ),
          studentsProvider.overrideWith(
            (ref) async => [_student('s1', '이서연'), _student('s2', '박도윤')],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      // Two student group headers with per-student counts.
      expect(
        find.text(AppStrings.awaitingFeedbackStudentCount('이서연', 2)),
        findsOneWidget,
      );
      expect(
        find.text(AppStrings.awaitingFeedbackStudentCount('박도윤', 1)),
        findsOneWidget,
      );
      // All three item titles render.
      expect(find.text('Canon A섹션'), findsOneWidget);
      expect(find.text('G Major 음계'), findsOneWidget);
      expect(find.text('Gavotte 통주'), findsOneWidget);
    });

    testWidgets('empty state uses EmptyStateWidget "모두 확인했어요"', (tester) async {
      await tester.pumpWidget(
        _harness([
          awaitingFeedbackProvider.overrideWith(
            (ref) async => <PracticeItem>[],
          ),
          studentsProvider.overrideWith((ref) async => <Student>[]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.awaitingFeedbackEmpty), findsOneWidget);
    });

    testWidgets('reaction tap removes the row from the queue (real invalidate)', (
      tester,
    ) async {
      // Fresh mock so the real awaitingFeedbackProvider computes against it and
      // toggleLike → invalidate re-fetches, dropping the reacted item.
      final repo = MockPracticeItemRepository();
      await tester.pumpWidget(
        _harness([
          practiceItemRepositoryProvider.overrideWithValue(repo),
          currentTeacherIdProvider.overrideWithValue('teacher_1'),
          studentsProvider.overrideWith((ref) async => <Student>[]),
        ]),
      );
      await tester.pumpAndSettle();

      // Mock seeds several completed-without-like items for teacher_1.
      final reactionButtons = find.byIcon(Icons.favorite_border);
      expect(reactionButtons, findsWidgets);
      final beforeCount = tester.widgetList(reactionButtons).length;
      expect(beforeCount, greaterThan(0));

      await tester.tap(reactionButtons.first);
      await tester.pumpAndSettle();

      final afterCount =
          tester.widgetList(find.byIcon(Icons.favorite_border)).length;
      expect(afterCount, beforeCount - 1);
    });
  });
}
