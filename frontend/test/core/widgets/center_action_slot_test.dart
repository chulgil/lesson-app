// #975 CenterActionSlot — discipline-neutral center-action injection slot.
//
// Contract (pinned by assertion, not reasoning):
//   - null centerAction  → SizedBox.shrink (zero size under loose constraints)
//   - non-null           → child verbatim, NO intervening RenderObject
//   - wrapping the music center button is layout byte-identical (same rect)
//   - injection inside a spaceAround nav row renders crash-free (2 viewports)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/core/widgets/center_action_slot.dart';
import 'package:lessonaza/core/widgets/practice_center_button.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show currentUserIdProvider;

void main() {
  group('CenterActionSlot', () {
    testWidgets('null centerAction renders SizedBox.shrink (zero size)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: CenterActionSlot()),
        ),
      );

      expect(find.byType(CenterActionSlot), findsOneWidget);
      // The only box in the subtree is the shrink fallback.
      expect(find.byType(SizedBox), findsOneWidget);
      expect(tester.getSize(find.byType(SizedBox)), Size.zero);
    });

    testWidgets('non-null centerAction renders the child with no wrapper', (
      tester,
    ) async {
      const childKey = Key('center-action-child');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CenterActionSlot(
              centerAction: SizedBox(key: childKey, width: 48, height: 48),
            ),
          ),
        ),
      );

      // Exact child present at its natural size...
      expect(find.byKey(childKey), findsOneWidget);
      expect(tester.getSize(find.byKey(childKey)), const Size(48, 48));
      // ...and the slot introduces NO intervening RenderObject: its resolved
      // render object IS the child's (a wrapper like Padding/RepaintBoundary
      // would make these two non-identical even at the same size).
      expect(
        identical(
          tester.renderObject(find.byType(CenterActionSlot)),
          tester.renderObject(find.byKey(childKey)),
        ),
        isTrue,
        reason: 'pure passthrough — no extra RenderObject around centerAction',
      );
    });

    testWidgets(
      'wrapping the center button is layout byte-identical (same rect)',
      (tester) async {
        // Reproduces the student nav row: spaceAround, 5 children, button at
        // index 2. The button rect must not move when wrapped in the slot.
        Widget navRow(Widget center) => ProviderScope(
          overrides: [currentUserIdProvider.overrideWithValue('s1')],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const SizedBox(width: 64, height: 64),
                    const SizedBox(width: 64, height: 64),
                    center,
                    const SizedBox(width: 64, height: 64),
                    const SizedBox(width: 64, height: 64),
                  ],
                ),
              ),
            ),
          ),
        );

        // Baseline: button directly in the row (origin/main shape).
        await tester.pumpWidget(navRow(const PracticeCenterButton(size: 48)));
        await tester.pumpAndSettle();
        final unwrapped = tester.getRect(find.byType(PracticeCenterButton));

        // Wrapped: button via the slot (#975 shape).
        await tester.pumpWidget(
          navRow(
            const CenterActionSlot(
              centerAction: PracticeCenterButton(size: 48),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final wrapped = tester.getRect(find.byType(PracticeCenterButton));

        expect(wrapped, unwrapped);
      },
    );

    for (final viewport in const <Size>[Size(1440, 900), Size(375, 812)]) {
      testWidgets(
        'injects PracticeCenterButton in a spaceAround row without crash '
        '@${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('s1'),
              ],
              child: const MaterialApp(
                home: Scaffold(
                  body: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(width: 64, height: 64),
                      SizedBox(width: 64, height: 64),
                      CenterActionSlot(
                        centerAction: PracticeCenterButton(size: 48),
                      ),
                      SizedBox(width: 64, height: 64),
                      SizedBox(width: 64, height: 64),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(PracticeCenterButton), findsOneWidget);
        },
      );
    }
  });
}
