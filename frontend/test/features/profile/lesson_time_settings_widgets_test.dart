import 'dart:ui';

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

  testWidgets(
    'DaySectionCard reveals edit and delete actions on left swipe (우→좌)',
    (tester) async {
      var edited = false;
      var deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DaySectionCard(
              dayOfWeek: 1,
              slots: const [
                TimeSlot(
                  id: 'slot-1',
                  dayOfWeek: 1,
                  startTime: ClockTime(hour: 9, minute: 0),
                  endTime: ClockTime(hour: 18, minute: 0),
                ),
              ],
              onEditSlot: (_) => edited = true,
              onDeleteSlot: (_) => deleted = true,
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.down(tester.getCenter(find.text('월요일')));
      await tester.pump();
      await gesture.moveBy(const Offset(-160, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.swipeActionEdit), findsOneWidget);
      expect(find.text(AppStrings.delete), findsOneWidget);

      await tester.tap(find.text(AppStrings.swipeActionEdit));
      expect(edited, isTrue);

      final deleteGesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await deleteGesture.down(tester.getCenter(find.text('월요일')));
      await tester.pump();
      await deleteGesture.moveBy(const Offset(-160, 0));
      await deleteGesture.up();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.delete));
      expect(deleted, isTrue);
    },
  );

  testWidgets(
    'TimeSlotTile reveals edit and delete actions on left swipe (우→좌)',
    (tester) async {
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

      await tester.drag(find.text('09:00 - 18:00'), const Offset(-160, 0));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.swipeActionEdit), findsOneWidget);
      expect(find.text(AppStrings.delete), findsOneWidget);

      await tester.tap(find.text(AppStrings.swipeActionEdit));
      expect(edited, isTrue);

      await tester.drag(find.text('09:00 - 18:00'), const Offset(-160, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.delete));
      expect(deleted, isTrue);
    },
  );

  testWidgets('time slot editor reuses add dialog with editable day selector', (
    tester,
  ) async {
    TimeSlot? savedSlot;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => FilledButton(
                  onPressed:
                      () => showTimeSlotDialog(
                        context: context,
                        existingSlot: const TimeSlot(
                          id: 'slot-2',
                          dayOfWeek: 2,
                          startTime: ClockTime(hour: 10, minute: 30),
                          endTime: ClockTime(hour: 12, minute: 0),
                        ),
                        onSave: (slot) => savedSlot = slot,
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.profileTimeSlotEditTitle), findsOneWidget);
    expect(find.text('요일'), findsOneWidget);
    expect(find.text('시작 시간'), findsOneWidget);
    expect(find.text('종료 시간'), findsOneWidget);
    expect(find.text('화요일'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);

    await tester.tap(find.text('화요일'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('금요일').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.save));
    await tester.pumpAndSettle();

    expect(savedSlot?.id, 'slot-2');
    expect(savedSlot?.dayOfWeek, 5);
    expect(savedSlot?.startTime, const ClockTime(hour: 10, minute: 30));
    expect(savedSlot?.endTime, const ClockTime(hour: 12, minute: 0));
  });

  testWidgets('DurationOptionItem 사용 토글이 Switch 대신 라운드 박스로 렌더', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DurationOptionItem(
            duration: 50,
            isDefault: true,
            isDisabled: false,
            isCustom: false,
            isOnlyActive: false,
            onTap: () {},
            onToggle: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(Switch), findsNothing);
    expect(find.text(AppStrings.profileDurationInUse), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('DurationOptionItem 토글 박스 탭 → onToggle(반전값) 호출', (tester) async {
    bool? toggled;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DurationOptionItem(
            duration: 50,
            isDefault: false,
            isDisabled: false, // 사용중 → 탭 시 해제(false) 전달
            isCustom: false,
            isOnlyActive: false,
            onTap: () {},
            onToggle: (v) => toggled = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.profileDurationInUse));
    await tester.pumpAndSettle();
    expect(toggled, isFalse);
  });
}
