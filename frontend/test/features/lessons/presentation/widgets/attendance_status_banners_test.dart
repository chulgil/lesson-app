import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/attendance_status_banners.dart';

/// Widget smoke tests for #473 attendance status banners.
///
/// - AttendanceAutoCompleteBanner: 24h 사전 안내 배너 렌더.
/// - AttendanceDeductionResultChip: completed → 차감됨 / 휴강 → 차감 없음.
void main() {
  Widget harness(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets('AttendanceAutoCompleteBanner: 사전 안내 노출 (no crash)', (tester) async {
    await tester.pumpWidget(harness(const AttendanceAutoCompleteBanner()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.attendanceAutoCompleteNotice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DeductionResultChip(deducted: true) → 수강권 1회 차감됨', (tester) async {
    await tester.pumpWidget(
      harness(const AttendanceDeductionResultChip(deducted: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.attendanceDeductedResult), findsOneWidget);
    expect(find.text(AppStrings.attendanceNoDeductionResult), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DeductionResultChip(deducted: false) → 차감 없음', (tester) async {
    await tester.pumpWidget(
      harness(const AttendanceDeductionResultChip(deducted: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.attendanceNoDeductionResult), findsOneWidget);
    expect(find.text(AppStrings.attendanceDeductedResult), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
