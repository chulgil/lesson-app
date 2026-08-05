import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/domain/entities/cancellation_policy_hint.dart';
import 'package:lessonaza/features/lessons/domain/entities/lesson.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/attendance_confirmation_sheet.dart';

/// #1241 — 클라이언트 힌트. 서버가 같은 규칙으로 최종 판정하므로 이 배너는
/// "저장하면 무슨 일이 벌어지는지" 를 미리 알리는 역할만 한다.
Lesson _lesson() => Lesson(
  id: 'lesson-1241',
  studentId: 'stu-1',
  studentName: '김민지',
  teacherId: 'teacher_1',
  instrument: '바이올린',
  date: DateTime(2026, 8, 10),
  startTime: '14:00',
  status: LessonStatus.scheduled,
  subscriptionId: 'sub-1',
  createdAt: DateTime(2026, 8, 1),
);

Future<void> _pumpSheet(
  WidgetTester tester,
  CancellationPolicyHint? hint,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: AttendanceConfirmationSheet(
          lesson: _lesson(),
          cancellationHint: hint,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // 사유 선택 단계로 진입해야 힌트가 보인다.
  await tester.tap(find.text(AppStrings.lessonNotCompleted));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('마감 경과: 지각 처리 예고 배너', (tester) async {
    await _pumpSheet(
      tester,
      CancellationPolicyHint(
        deadlineHours: 24,
        deadlineAt: DateTime(2026, 8, 9, 14),
        isLateNow: true,
        enforced: true,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.cancelDeadlinePassedHint), findsOneWidget);
  });

  testWidgets('마감 이전: 차감 없이 취소 가능 안내', (tester) async {
    await _pumpSheet(
      tester,
      CancellationPolicyHint(
        deadlineHours: 24,
        deadlineAt: DateTime(2026, 8, 9, 14),
        isLateNow: false,
        enforced: true,
      ),
    );

    expect(
      find.text(AppStrings.cancelDeadlineRemainingHint(24)),
      findsOneWidget,
    );
  });

  testWidgets('정책 미설정(enforced=false): 배너 없음 — 지키지 못할 약속 금지', (tester) async {
    await _pumpSheet(
      tester,
      const CancellationPolicyHint(
        deadlineHours: 24,
        deadlineAt: null,
        isLateNow: true,
        enforced: false,
      ),
    );

    expect(find.text(AppStrings.cancelDeadlinePassedHint), findsNothing);
    expect(find.text(AppStrings.cancelDeadlineRemainingHint(24)), findsNothing);
  });

  testWidgets('힌트 조회 실패(null): 배너 없이 기존 흐름 유지 (회귀)', (tester) async {
    await _pumpSheet(tester, null);

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.cancelDeadlinePassedHint), findsNothing);
  });
}
