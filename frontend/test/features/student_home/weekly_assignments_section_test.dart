import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/practice/practice_facade.dart';
import 'package:lessonaza/features/student_home/presentation/widgets/weekly_assignments_section.dart';

PracticeItem _item({
  required String id,
  required String title,
  PracticePriority priority = PracticePriority.should,
  bool isCompleted = false,
}) {
  return PracticeItem(
    id: id,
    lessonId: 'lesson_1',
    studentId: 'student_1',
    teacherId: 'teacher_1',
    type: PracticeType.technique,
    title: title,
    priority: priority,
    isCompleted: isCompleted,
    createdAt: DateTime(2026, 6, 23),
  );
}

void main() {
  group('WeeklyAssignmentsSection', () {
    testWidgets('과제 있을 때 제목과 항목 노출', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final items = [
        _item(id: '1', title: '스케일 C장조', priority: PracticePriority.must),
        _item(id: '2', title: '하농 1번'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyPracticeItemsProvider(
              'student_1',
            ).overrideWith((ref) async => items),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WeeklyAssignmentsSection(studentId: 'student_1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('이번 주 과제'), findsOneWidget);
      expect(find.text('스케일 C장조'), findsOneWidget);
      expect(find.text('하농 1번'), findsOneWidget);
    });

    testWidgets('과제 0건이면 빈 상태 안내 노출', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyPracticeItemsProvider(
              'student_1',
            ).overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WeeklyAssignmentsSection(studentId: 'student_1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('이번 주 과제가 없습니다'), findsOneWidget);
    });

    testWidgets('완료된 항목은 미리보기에서 제외', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final items = [
        _item(id: '1', title: '미완료 과제'),
        _item(id: '2', title: '완료된 과제', isCompleted: true),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyPracticeItemsProvider(
              'student_1',
            ).overrideWith((ref) async => items),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WeeklyAssignmentsSection(studentId: 'student_1'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('미완료 과제'), findsOneWidget);
      expect(find.text('완료된 과제'), findsNothing);
    });

    testWidgets('Column 좁은 제약에서 overflow 없음', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final items = List.generate(5, (i) => _item(id: '$i', title: '과제 $i'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyPracticeItemsProvider(
              'student_1',
            ).overrideWith((ref) async => items),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: WeeklyAssignmentsSection(studentId: 'student_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
