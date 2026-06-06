import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/auth/auth_facade.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/parent_home/domain/entities/child_profile.dart';
import 'package:lessonaza/features/parent_home/presentation/providers/child_profile_provider.dart';
import 'package:lessonaza/features/parent_home/presentation/screens/parent_lessons_tab.dart';

void main() {
  group('ParentLessonsTab — smoke (#585/#584)', () {
    ChildProfile makeChild({String? linkedStudentId}) {
      final now = DateTime.now();
      return ChildProfile(
        id: 'child-1',
        parentId: 'parent-1',
        name: '민준',
        birthYear: 2016,
        instrument: 'violin',
        level: 'beginner',
        teacherId: linkedStudentId == null ? null : 'teacher-1',
        teacherName: linkedStudentId == null ? null : '김선생님',
        linkedStudentId: linkedStudentId,
        profileColorKey: 'blue',
        connectionStatus: linkedStudentId == null
            ? ChildConnectionStatus.unconnected
            : ChildConnectionStatus.connected,
        createdAt: now,
      );
    }

    Lesson makeLesson() {
      final now = DateTime.now();
      return Lesson(
        id: 'lesson-1',
        studentId: 'student-1',
        studentName: '민준',
        teacherId: 'teacher-1',
        teacherName: '김선생님',
        instrument: 'violin',
        date: now.subtract(const Duration(days: 3)),
        startTime: '14:00',
        status: LessonStatus.completed,
        feedback: '잘했어요',
        assignments: const ['스케일 연습'],
        createdAt: now.subtract(const Duration(days: 3)),
      );
    }

    Widget wrap(List<Override> overrides) => ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('parent-1'),
        ...overrides,
      ],
      child: const MaterialApp(home: Scaffold(body: ParentLessonsTab())),
    );

    testWidgets('linked child renders real lessons without exception', (
      tester,
    ) async {
      final child = makeChild(linkedStudentId: 'student-1');
      await tester.pumpWidget(
        wrap([
          childProfilesProvider(
            'parent-1',
          ).overrideWith((_) async => [child]),
          lessonsByStudentProvider(
            'student-1',
          ).overrideWith((_) async => [makeLesson()]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.parentHomeUpcomingLessons), findsOneWidget);
      expect(find.text(AppStrings.parentHomePastLessons), findsOneWidget);
    });

    testWidgets('not-linked child shows not-linked state', (tester) async {
      final child = makeChild();
      await tester.pumpWidget(
        wrap([
          childProfilesProvider(
            'parent-1',
          ).overrideWith((_) async => [child]),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.parentHomeChildNotLinked), findsOneWidget);
    });

    testWidgets('no children shows empty state', (tester) async {
      await tester.pumpWidget(
        wrap([
          childProfilesProvider('parent-1').overrideWith((_) async => []),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.parentHomeNoChildren), findsOneWidget);
    });
  });
}
