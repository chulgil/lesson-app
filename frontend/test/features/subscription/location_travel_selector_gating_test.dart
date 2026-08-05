// #1146 — LocationTravelSelector option gating by the teacher's allowed types.
//
// The selector filters its location chips to allowedLocationTypes (derived from
// the teacher's profile lesson types). null → no gating (current behavior).
// Exactly one option → auto-selected and shown read-only (no lone chip).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/students/students_facade.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/location_travel_selector.dart';

Widget _harness({
  Set<LocationType>? allowed,
  void Function(String?)? onLocationChanged,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: LocationTravelSelector(
          membershipId: 'm1',
          studentId: 's1',
          currentTravelTime: 0,
          onLocationChanged: onLocationChanged ?? (_) {},
          onTravelTimeChanged: (_) {},
          allowedLocationTypes: allowed,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('null allowed → all private options shown (no gating)', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(allowed: null));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Private context: 학생 집 / 외부 스튜디오 / 선생님 레슨실 / 온라인.
    expect(find.byType(ChoiceChip), findsNWidgets(4));
  });

  testWidgets('allowed subset → only matching options shown', (tester) async {
    await tester.pumpWidget(
      _harness(allowed: {LocationType.teacherStudio, LocationType.online}),
    );
    await tester.pump();

    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.text('선생님 레슨실'), findsOneWidget);
    expect(find.text('온라인'), findsOneWidget);
    // Filtered out.
    expect(find.text('학생 집'), findsNothing);
    expect(find.text('외부 스튜디오'), findsNothing);
  });

  testWidgets(
    'single allowed → auto-selected, shown read-only, parent notified',
    (tester) async {
      String? notifiedLocationId;
      await tester.pumpWidget(
        _harness(
          allowed: {LocationType.teacherStudio},
          onLocationChanged: (id) => notifiedLocationId = id,
        ),
      );
      await tester.pump(); // let the post-frame auto-select notify fire

      // Collapsed: no chip to pick.
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('선생님 레슨실'), findsOneWidget);
      // Auto-selected and pushed to the parent.
      expect(notifiedLocationId, 'teacher_studio_default');
    },
  );
}
