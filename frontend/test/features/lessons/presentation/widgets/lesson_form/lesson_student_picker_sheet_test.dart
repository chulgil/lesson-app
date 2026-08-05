import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_form_widgets.dart';

/// 경로 4 (quick_add_lesson §2.6.4) — 학생 선택 시트 [새 학생 등록] 항목.
LessonStudentInfo _info(String id, String name) => LessonStudentInfo(
  id: id,
  name: name,
  instrument: '바이올린',
  currentPiece: '초급',
  color: Colors.blue,
);

Future<void> _openPicker(
  WidgetTester tester, {
  required List<LessonStudentInfo> students,
  ValueChanged<LessonStudentInfo>? onSelected,
  VoidCallback? onAddStudent,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder:
            (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed:
                      () => showLessonStudentPicker(
                        context: context,
                        students: students,
                        selectedStudent: null,
                        onStudentSelected: onSelected ?? (_) {},
                        onAddStudentRequested: onAddStudent,
                      ),
                  child: const Text('open'),
                ),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('콜백 제공: 목록 최상단 [새 학생 등록] + 탭 시 콜백', (tester) async {
    var addRequested = false;
    await _openPicker(
      tester,
      students: [_info('s1', '김민지')],
      onAddStudent: () => addRequested = true,
    );

    final addItem = find.text(AppStrings.lessonPickerAddStudentAction);
    expect(addItem, findsOneWidget);
    expect(find.text('김민지'), findsOneWidget);

    await tester.tap(addItem);
    await tester.pumpAndSettle();
    expect(addRequested, isTrue);
  });

  testWidgets('콜백 제공 시에도 기존 학생 탭 → onStudentSelected (인덱스 시프트 회귀)', (
    tester,
  ) async {
    LessonStudentInfo? selected;
    await _openPicker(
      tester,
      students: [_info('s1', '김민지'), _info('s2', '박서준')],
      onSelected: (s) => selected = s,
      onAddStudent: () {},
    );

    await tester.tap(find.text('박서준'));
    await tester.pumpAndSettle();
    expect(selected?.id, 's2');
  });

  testWidgets('콜백 미제공(레거시 호출부): 항목 없음', (tester) async {
    await _openPicker(tester, students: [_info('s1', '김민지')]);

    expect(find.text(AppStrings.lessonPickerAddStudentAction), findsNothing);
  });

  testWidgets('빈 목록 + 콜백: 빈 상태 액션이 콜백으로 위임', (tester) async {
    var addRequested = false;
    await _openPicker(
      tester,
      students: [],
      onAddStudent: () => addRequested = true,
    );

    await tester.tap(find.text(AppStrings.studentRegisterAction));
    await tester.pumpAndSettle();
    expect(addRequested, isTrue);
  });
}
