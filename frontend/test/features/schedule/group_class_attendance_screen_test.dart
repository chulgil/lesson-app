// Interaction-driving smoke test for GroupClassAttendanceScreen.
//
// Contract (ux-rules.md HARD-GATE §731):
//   Drive the screen's primary interaction — tap "수업 종료" → confirm dialog
//   opens → tap Cancel → pumpAndSettle() → takeException() isNull.
//
// Why this screen:
//   GroupClassAttendanceScreen._finishClass() calls showDialog(NotebookAlertDialog).
//   The dialog has no StatefulWidget controllers, so the #730 pattern doesn't
//   apply directly, but the screen is a ConsumerStatefulWidget with _isSaving /
//   _attendanceState mutation on dialog close.  If the dialog close path calls
//   setState() on an unmounted State (mounted check missing), pumpAndSettle()
//   surfaces the error.  pump-only never opens the dialog, so this path is dark.
//
// Provider wiring:
//   scheduleBookingsProvider(scheduleId) → overrideWith returns [] (empty list).
//   groupClassBookingRepositoryProvider is not needed directly because the
//   notifier path (_finishClass → markBatchAttendance) is gated behind the
//   confirm dialog; we tap Cancel so the mutation is never triggered.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class_booking.dart';
import 'package:lessonaza/features/schedule/domain/entities/group_class_schedule.dart';
import 'package:lessonaza/features/schedule/presentation/providers/group_class_booking_providers.dart';
import 'package:lessonaza/features/schedule/presentation/screens/group_class_attendance_screen.dart';

const _kScheduleId = 'test-schedule-1';

final _stubGroupClass = GroupClass(
  id: 'gc-1',
  teacherId: 'teacher-1',
  name: '바이올린 그룹 레슨',
  type: GroupClassType.regular,
  maxCapacity: 6,
  durationMinutes: 60,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
);

final _stubSchedule = GroupClassSchedule(
  id: _kScheduleId,
  groupClassId: 'gc-1',
  startTime: DateTime(2026, 6, 20, 10, 0),
  endTime: DateTime(2026, 6, 20, 11, 0),
  status: ScheduleStatus.open,
  maxCapacity: 6,
  createdAt: DateTime(2026, 1, 1),
);

Widget _wrap() {
  return ProviderScope(
    overrides: [
      // Return empty booking list so the screen renders without network/auth.
      scheduleBookingsProvider(
        _kScheduleId,
      ).overrideWith((ref) async => <GroupClassBooking>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: GroupClassAttendanceScreen(
        scheduleId: _kScheduleId,
        schedule: _stubSchedule,
        groupClass: _stubGroupClass,
      ),
    ),
  );
}

void main() {
  group('GroupClassAttendanceScreen — interaction smoke (HARD-GATE §731)', () {
    testWidgets('renders AppBar title without crash', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(AppStrings.attendanceCheck), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'tap "수업 종료" → confirm dialog opens → tap cancel → no exception',
      (tester) async {
        // This exercises the dialog open + close path on a ConsumerStatefulWidget.
        // If setState() is called after unmount (mounted check missing), the
        // exception surfaces in pumpAndSettle() here.
        await tester.pumpWidget(_wrap());
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Tap the "수업 종료" ElevatedButton at the bottom of the screen.
        expect(find.text(AppStrings.finishClass), findsOneWidget);
        await tester.tap(find.text(AppStrings.finishClass));
        await tester.pumpAndSettle();

        // NotebookAlertDialog should now be visible.
        // The dialog contains the title text (finishClass) and confirm/cancel.
        expect(find.text(AppStrings.finishClassConfirm), findsOneWidget);

        // Tap Cancel to close dialog without triggering the mutation path.
        await tester.tap(find.text(AppStrings.cancel));

        // Drive exit animation — unmounted-setState bugs surface here.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
