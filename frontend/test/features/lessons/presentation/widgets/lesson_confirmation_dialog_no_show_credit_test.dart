import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_confirmation_dialog.dart';

/// 노쇼 표시 시 보강 크레딧 지급 체크박스 (spec §4.2, 선생님 재량, 기본 OFF).
///
/// - noShow 사유일 때만 노출 (studentAbsent 등 다른 사유엔 없음).
/// - 기본값 OFF — 명시적으로 탭해야 LessonConfirmationResult.grantMakeupCredit=true.
Lesson _lesson() => Lesson(
  id: 'lesson-dialog-credit-1',
  studentId: 'stu-1',
  studentName: '김민지',
  instrument: '바이올린',
  date: DateTime(2026, 8, 10),
  startTime: '10:00',
  status: LessonStatus.scheduled,
  createdAt: DateTime(2026, 8, 1),
);

/// Opens the dialog and advances to the reason-selection screen. The dialog
/// stays open (its `show()` future doesn't resolve until Navigator.pop), so
/// callers can inspect/interact with the reason screen after this returns.
Future<void> _openToReasonSelection(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed:
                  () =>
                      LessonConfirmationDialog.show(context, lesson: _lesson()),
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  await tester.tap(find.text(AppStrings.lessonNotCompleted));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('노쇼 사유 선택 시 보강 크레딧 체크박스가 노출된다', (tester) async {
    await _openToReasonSelection(tester);

    await tester.tap(find.text(AppStrings.lessonNoShow));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.lessonNoShowGrantMakeupCreditLabel),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('학생 사정 불참 사유에는 체크박스가 없다', (tester) async {
    await _openToReasonSelection(tester);

    await tester.tap(find.text(AppStrings.lessonStudentAbsentReason));
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.lessonNoShowGrantMakeupCreditLabel),
      findsNothing,
    );
  });

  testWidgets('체크박스를 탭하지 않고 확인 → grantMakeupCredit=false (기본값)', (
    tester,
  ) async {
    LessonConfirmationResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await LessonConfirmationDialog.show(
                    context,
                    lesson: _lesson(),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.lessonNotCompleted));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.lessonNoShow));
    await tester.pumpAndSettle();

    // 체크박스가 늘린 콘텐츠가 SingleChildScrollView 안에 있어 확인 버튼이
    // 뷰포트 밖일 수 있다 — 스크롤해서 노출시킨 뒤 탭.
    await tester.ensureVisible(find.text(AppStrings.confirm));
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.grantMakeupCredit, isFalse);
    expect(result!.nonCompletionReason, LessonNonCompletionReason.noShow);
  });

  testWidgets('체크박스를 탭한 뒤 확인 → grantMakeupCredit=true', (tester) async {
    LessonConfirmationResult? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await LessonConfirmationDialog.show(
                    context,
                    lesson: _lesson(),
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.lessonNotCompleted));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.lessonNoShow));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.text(AppStrings.lessonNoShowGrantMakeupCreditLabel),
    );
    await tester.tap(find.text(AppStrings.lessonNoShowGrantMakeupCreditLabel));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(AppStrings.confirm));
    await tester.tap(find.text(AppStrings.confirm));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.grantMakeupCredit, isTrue);
  });
}
