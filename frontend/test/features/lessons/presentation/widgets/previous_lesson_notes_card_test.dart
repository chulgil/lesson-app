import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/providers/lesson_note_providers.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/previous_lesson_notes_card.dart';

/// #1215 — 레슨 노트 작성 중 지난 노트 참조.
/// 선생님이 이번 레슨 노트를 쓸 때 같은 학생의 직전 노트가 읽기 전용으로
/// 보이는지, 현재 레슨/미래 레슨/빈 피드백이 참조에서 제외되는지 검증한다.
const _studentId = 's1';

Lesson _lesson({required String id, required DateTime date, String? feedback}) {
  return Lesson(
    id: id,
    studentId: _studentId,
    studentName: '민지',
    instrument: 'violin',
    date: date,
    startTime: '15:00',
    feedback: feedback,
    createdAt: date,
  );
}

final _current = _lesson(
  id: 'current',
  date: DateTime(2026, 7, 22),
  feedback: '오늘 작성 중인 노트',
);

final _prior1 = _lesson(
  id: 'p1',
  date: DateTime(2026, 7, 15),
  feedback: '스타카토를 더 짧게',
);

final _prior2 = _lesson(
  id: 'p2',
  date: DateTime(2026, 7, 8),
  feedback: '활 배분을 일정하게',
);

final _prior3 = _lesson(
  id: 'p3',
  date: DateTime(2026, 7, 1),
  feedback: '3번 손가락 음정 확인',
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Lesson> notes,
  double width = 375,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentLessonNotesProvider(
          _studentId,
        ).overrideWith((ref) async => notes),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: PreviousLessonNotesCard(lesson: _current),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PreviousLessonNotesCard', () {
    testWidgets('지난 노트가 없으면 섹션 자체를 렌더하지 않는다', (tester) async {
      await _pump(tester, notes: [_current]);

      expect(find.text(AppStrings.previousLessonNotesTitle), findsNothing);
      expect(find.text('오늘 작성 중인 노트'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('접힌 상태에서 직전 노트 1건만 미리보기', (tester) async {
      await _pump(tester, notes: [_current, _prior1, _prior2]);

      expect(find.text(AppStrings.previousLessonNotesTitle), findsOneWidget);
      expect(find.text('스타카토를 더 짧게'), findsOneWidget);
      // 접힌 상태에서는 그 이전 노트를 노출하지 않는다.
      expect(find.text('활 배분을 일정하게'), findsNothing);
      // 현재 레슨의 노트는 참조 대상이 아니다 (편집기에 이미 있음).
      expect(find.text('오늘 작성 중인 노트'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('펼치면 직전 2건까지만 노출', (tester) async {
      await _pump(tester, notes: [_current, _prior1, _prior2, _prior3]);

      await tester.tap(find.text(AppStrings.previousLessonNotesTitle));
      await tester.pumpAndSettle();

      expect(find.text('스타카토를 더 짧게'), findsOneWidget);
      expect(find.text('활 배분을 일정하게'), findsOneWidget);
      // 3건째부터는 노출하지 않는다 (전체는 노트 이력 화면).
      expect(find.text('3번 손가락 음정 확인'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('현재 레슨 이후 날짜의 노트는 참조하지 않는다', (tester) async {
      final future = _lesson(
        id: 'future',
        date: DateTime(2026, 7, 29),
        feedback: '다음 주 노트',
      );

      await _pump(tester, notes: [future, _current]);

      expect(find.text(AppStrings.previousLessonNotesTitle), findsNothing);
      expect(find.text('다음 주 노트'), findsNothing);
    });

    testWidgets('피드백이 비어 있는 지난 레슨은 참조하지 않는다', (tester) async {
      final blank = _lesson(
        id: 'blank',
        date: DateTime(2026, 7, 15),
        feedback: '   ',
      );

      await _pump(tester, notes: [blank, _current]);

      expect(find.text(AppStrings.previousLessonNotesTitle), findsNothing);
    });

    testWidgets('좁은 제약(200px)에서 펼쳐도 렌더 예외가 없다', (tester) async {
      await _pump(tester, notes: [_current, _prior1, _prior2], width: 200);

      await tester.tap(find.text(AppStrings.previousLessonNotesTitle));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
