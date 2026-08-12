// M-1 — shared slot chip list extracted from LessonBookingScreen._SlotChips
// and BookingRescheduleScreen._buildSlotChips
// (schedule_change_unification_spec.md §3.4).
// ux-rules HARD-GATE: top-level widget smoke test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/domain/value_objects/clock_time.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_colors.dart';
import 'package:lessonaza/features/schedule/domain/entities/availability_slot.dart';
import 'package:lessonaza/features/schedule/presentation/widgets/availability/availability_slot_chip_list.dart';

AvailabilitySlot _slot(String id, int hour, {bool isRecommended = false}) =>
    AvailabilitySlot(
      id: id,
      teacherId: 't1',
      date: DateTime(2026, 6, 10),
      startTime: ClockTime(hour: hour, minute: 0),
      endTime: ClockTime(hour: hour + 1, minute: 0),
      durationMinutes: 50,
      isRecommended: isRecommended,
    );

void main() {
  testWidgets('오전/오후 슬롯을 그룹핑해 예외 없이 렌더', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilitySlotChipList(
            slots: [_slot('a', 10), _slot('b', 14)],
            selectedId: null,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.timeAM), findsOneWidget);
    expect(find.text(AppStrings.timePM), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
  });

  testWidgets('오전 슬롯만 있으면 오후 라벨은 렌더하지 않음', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilitySlotChipList(
            slots: [_slot('a', 9)],
            selectedId: null,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.timeAM), findsOneWidget);
    expect(find.text(AppStrings.timePM), findsNothing);
  });

  testWidgets('칩 탭 → onSelect 콜백이 선택된 슬롯과 함께 호출됨', (tester) async {
    AvailabilitySlot? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilitySlotChipList(
            slots: [_slot('a', 10)],
            selectedId: null,
            onSelect: (s) => selected = s,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('10:00'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'a');
  });

  testWidgets('선택된 슬롯 칩은 paperAccent 채움으로 렌더', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilitySlotChipList(
            slots: [_slot('a', 10)],
            selectedId: 'a',
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppColors.paperAccent);
  });

  testWidgets('추천 슬롯(isRecommended)은 비선택 상태에서 별 아이콘 노출', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvailabilitySlotChipList(
            slots: [_slot('a', 10, isRecommended: true)],
            selectedId: null,
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });
}
