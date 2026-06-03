import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/lessons/presentation/widgets/lesson_detail/attendance_action_card.dart';

/// Widget smoke test for AttendanceActionCard (#473 미확인 레슨 액션).
///
/// 1) Renders without RenderBox/BoxConstraints crash.
/// 2) 출석 확인 + 휴강 두 액션 노출.
/// 3) 각 탭이 해당 콜백을 호출.
void main() {
  Widget harness({
    required VoidCallback onConfirm,
    required VoidCallback onDayOff,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AttendanceActionCard(
              onConfirm: onConfirm,
              onDayOff: onDayOff,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('unconfirmed: 출석 확인 + 휴강 두 액션 노출 (no crash)', (tester) async {
    await tester.pumpWidget(harness(onConfirm: () {}, onDayOff: () {}));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.attendanceConfirmAction), findsOneWidget);
    expect(find.text(AppStrings.attendanceDayOffAction), findsOneWidget);
    expect(find.text(AppStrings.attendanceConfirmSubLabel), findsOneWidget);
    expect(find.text(AppStrings.attendanceDayOffSubLabel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('출석 확인 탭 → onConfirm 호출', (tester) async {
    var confirmed = false;
    var dayOff = false;
    await tester.pumpWidget(
      harness(
        onConfirm: () => confirmed = true,
        onDayOff: () => dayOff = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.attendanceConfirmAction));
    await tester.pump();

    expect(confirmed, isTrue);
    expect(dayOff, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('휴강 탭 → onDayOff 호출', (tester) async {
    var confirmed = false;
    var dayOff = false;
    await tester.pumpWidget(
      harness(
        onConfirm: () => confirmed = true,
        onDayOff: () => dayOff = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.attendanceDayOffAction));
    await tester.pump();

    expect(dayOff, isTrue);
    expect(confirmed, isFalse);
    expect(tester.takeException(), isNull);
  });
}
