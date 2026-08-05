import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/lessons/lessons_facade.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/lesson_action_sheet.dart';
import 'package:lessonaza/features/students/students_facade.dart';

/// §2.7 (AC-5.3) — 미가입 학생 수강권 레슨: "일정 변경(챗)" 대신 "일정 수정 (직접)".
const _studentId = 'st1';

Student _student({DateTime? connectedAt}) => Student(
  id: _studentId,
  name: '수기 학생',
  instrument: '바이올린',
  level: StudentLevel.beginner,
  status: StudentStatus.trial,
  monthlyFee: 0,
  connectedAt: connectedAt,
  createdAt: DateTime(2026, 1, 1),
);

Lesson _subscriptionLesson() => Lesson(
  id: 'l1',
  studentId: _studentId,
  studentName: '수기 학생',
  instrument: '바이올린',
  subscriptionId: 'sub1',
  date: DateTime.now().add(const Duration(days: 7)),
  startTime: '14:00',
  duration: 60,
  status: LessonStatus.scheduled,
  createdAt: DateTime(2026, 8, 1),
);

Future<void> _openSheet(WidgetTester tester, {DateTime? connectedAt}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentsProvider.overrideWith(
          (ref) async => [_student(connectedAt: connectedAt)],
        ),
      ],
      child: MaterialApp(
        home: Consumer(
          builder:
              (context, ref, _) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed:
                        () => showLessonActionSheet(
                          context: context,
                          ref: ref,
                          lesson: _subscriptionLesson(),
                        ),
                    child: const Text('open'),
                  ),
                ),
              ),
        ),
      ),
    ),
  );
  // studentsProvider resolve 후 시트 열기 (sync read 라 선로딩 필요).
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('미가입 학생: [일정 수정 (직접)] 노출, 챗 일정 변경 숨김', (tester) async {
    await _openSheet(tester);

    expect(find.text(AppStrings.scheduleEditDirectLabel), findsOneWidget);
    expect(find.text(AppStrings.scheduleChangeLabel), findsNothing);
  });

  testWidgets('가입 학생: 기존 [일정 변경](챗) 유지 (회귀)', (tester) async {
    await _openSheet(tester, connectedAt: DateTime(2026, 6, 1));

    expect(find.text(AppStrings.scheduleChangeLabel), findsOneWidget);
    expect(find.text(AppStrings.scheduleEditDirectLabel), findsNothing);
  });
}
