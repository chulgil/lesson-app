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

  group('#768 ③ 보강 충돌 경고 + 요약', () {
    BulkClosure overlapping() {
      final same = DateTime(2026, 8, 22, 15, 0);
      return _buildClosure(
        lessons: [
          _buildLesson(id: 'l1', studentName: '박학생', makeupAt: same),
          _buildLesson(id: 'l2', studentName: '이학생', makeupAt: same),
        ],
      );
    }

    testWidgets('겹치는 두 보강은 충돌 배지 2개 + 안내를 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: overlapping(),
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('시간 겹침'), findsNWidgets(2));
      expect(find.text('2건 보강 시각이 겹칩니다. 확인해 주세요.'), findsOneWidget);
    });

    testWidgets('전체 확정 시 최종 확인 요약 다이얼로그가 뜬다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: overlapping(),
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.ancestor(
          of: find.text('전체 확정'),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('보강 일정 확인'), findsOneWidget);
    });

    testWidgets('375 폭에서 overflow 없이 렌더', (tester) async {
      tester.view.physicalSize = const Size(375, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: MakeupLessonInputScreen(
            closure: overlapping(),
            onSaveAll: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
