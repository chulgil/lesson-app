import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/students/presentation/screens/add_student_screen.dart';

void main() {
  group('AddStudentScreen', () {
    testWidgets(
      'should not crash with RenderMetaData layout error when building form',
      (WidgetTester tester) async {
        // Build the screen at a desktop viewport (user crash repro: macOS).
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
          ),
        );

        // Pump and settle to allow all animations to complete
        await tester.pumpAndSettle();

        // Check that there are no exceptions (RenderMetaData or otherwise)
        expect(tester.takeException(), isNull);

        // Verify that key widgets are present
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      },
    );

    testWidgets('should not overflow on common mobile(375) viewport', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'should not overflow on narrow mobile(320) viewport — schedule row reflow (#750)',
      (WidgetTester tester) async {
        // Repro: smallest real device width (iPhone SE 1st-gen / split-view).
        // The schedule day-selector (7 fixed cells) and duration row overflow
        // here before reflow. Address row is already safe (>=151px) via #746.
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
