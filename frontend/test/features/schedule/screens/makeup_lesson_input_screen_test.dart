import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/academy/domain/entities/bulk_closure.dart';
import 'package:lessonaza/features/schedule/presentation/screens/makeup_lesson_input_screen.dart';

BulkClosure _buildClosure({List<AffectedLesson> lessons = const []}) {
  return BulkClosure(
    id: 'closure-1',
    academyId: 'academy-1',
    closureDate: DateTime(2026, 8, 15),
    reason: '공휴일 휴원',
    status: ClosureStatus.applied,
    affectedLessons: lessons,
  );
}

AffectedLesson _buildLesson({
  String id = 'l1',
  String studentName = '박학생',
  DateTime? makeupAt,
}) {
  return AffectedLesson(
    lessonId: id,
    studentId: 'student-$id',
    studentName: studentName,
    originalStartAt: DateTime(2026, 8, 15, 14, 0),
    originalEndAt: DateTime(2026, 8, 15, 15, 0),
    makeupAt: makeupAt,
  );
}

void main() {
  group('MakeupLessonInputScreen', () {
    testWidgets('renders header + lesson rows when affected lessons exist', (
      tester,
    ) async {
      final closure = _buildClosure(
        lessons: [
          _buildLesson(id: 'l1', studentName: '박학생'),
          _buildLesson(id: 'l2', studentName: '이학생'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: closure,
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('휴원 영향'), findsOneWidget);
      expect(find.textContaining('박학생'), findsOneWidget);
      expect(find.textContaining('이학생'), findsOneWidget);
      expect(find.text('2건 중 0건 입력 완료'), findsOneWidget);
    });

    testWidgets('shows empty state when no affected lessons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: _buildClosure(),
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('영향 받은 레슨이 없습니다.'), findsOneWidget);
    });

    testWidgets('progress reflects pre-existing makeup times', (tester) async {
      final closure = _buildClosure(
        lessons: [
          _buildLesson(id: 'l1', makeupAt: DateTime(2026, 8, 22, 14, 0)),
          _buildLesson(id: 'l2'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: closure,
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2건 중 1건 입력 완료'), findsOneWidget);
    });

    testWidgets('bulk confirm button is disabled when no makeup filled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: _buildClosure(lessons: [_buildLesson()]),
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final confirm = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('전체 확정'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('draft save calls onSaveAll even when no makeup filled', (
      tester,
    ) async {
      Map<String, DateTime>? received;
      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: _buildClosure(lessons: [_buildLesson()]),
            onSaveAll: (data) async => received = data,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('임시저장'));
      await tester.pumpAndSettle();

      expect(received, isNotNull);
      expect(received!.isEmpty, isTrue);
    });
  });
}
