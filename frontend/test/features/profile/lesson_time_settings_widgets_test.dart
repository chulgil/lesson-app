import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/booking/entities/time_slot.dart';
import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/profile/presentation/widgets/lesson_time_settings_widgets.dart';

void main() {
  testWidgets('DaySectionCard keeps a closed day visible without add button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DaySectionCard(
            dayOfWeek: 1,
            slots: const [],
            onEditSlot: (_) {},
            onDeleteSlot: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('월요일'), findsOneWidget);
    expect(find.text('휴무'), findsOneWidget);
    expect(find.text(AppStrings.profileTimeSlotAdd), findsNothing);
  });

  testWidgets('TimeSlotTile reveals edit and delete actions on right swipe', (
    tester,
  ) async {
    var edited = false;
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeSlotTile(
            slot: const TimeSlot(
              id: 'slot-1',
              dayOfWeek: 1,
              startTime: ClockTime(hour: 9, minute: 0),
              endTime: ClockTime(hour: 18, minute: 0),
            ),
            onEdit: () => edited = true,
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.drag(find.text('09:00 - 18:00'), const Offset(160, 0));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.swipeActionEdit), findsOneWidget);
    expect(find.text(AppStrings.delete), findsOneWidget);

    await tester.tap(find.text(AppStrings.swipeActionEdit));
    expect(edited, isTrue);

    await tester.drag(find.text('09:00 - 18:00'), const Offset(160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.delete));
    expect(deleted, isTrue);
  });
}
