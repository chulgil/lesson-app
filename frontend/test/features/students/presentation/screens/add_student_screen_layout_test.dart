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

    // NOTE: mobile(375) 가로 오버플로우(address_fields Row 58px)는 별도 이슈 #750 으로 분리.
    // #746 은 desktop RenderMetaData 크래시(사용자 실제 케이스) 해소만 머지한다.
  });
}
