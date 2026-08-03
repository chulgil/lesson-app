import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/domain/value_objects/discipline_registry.dart';
import 'package:lessonaza/features/auth/auth_facade.dart'
    show activeDisciplineProvider;
import 'package:lessonaza/features/students/presentation/screens/add_student_screen.dart';

// #1072: AddStudentScreen's InstrumentSelector now reads the active
// discipline; pin music so the picker matches and no Hive box opens.
List<Override> _musicOverrides() => [
  activeDisciplineProvider.overrideWith((ref) => DisciplineRegistry.music),
];

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
            overrides: _musicOverrides(),
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
        ProviderScope(
          overrides: _musicOverrides(),
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
          ProviderScope(
            overrides: _musicOverrides(),
            child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '[UX7-32] additional info ExpansionTile present and no crash on expand',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _musicOverrides(),
            child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // ExpansionTile with key 'additionalInfoExpansionTile' is present
        expect(
          find.byKey(const Key('additionalInfoExpansionTile')),
          findsOneWidget,
        );

        // Tap the expansion tile header to expand it
        await tester.tap(find.byKey(const Key('additionalInfoExpansionTile')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '[UX7-32] required sections always visible — basic info, instrument, schedule, save button',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: _musicOverrides(),
            child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Required sections present in widget tree
        expect(find.text('기본 정보'), findsOneWidget);
        expect(find.text('악기'), findsOneWidget);
        expect(find.text('레벨 및 수강료'), findsOneWidget);
        expect(find.text('레슨 일정'), findsOneWidget);
        // Save button present
        expect(find.text('학생 추가'), findsOneWidget);
        // Additional info collapsible tile present
        expect(find.text('추가 정보'), findsOneWidget);
      },
    );

    testWidgets('[UX7-32] no crash on 320px with expansion tile expand', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _musicOverrides(),
          child: MaterialApp(home: Scaffold(body: AddStudentScreen())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Expand and verify no crash
      await tester.tap(find.byKey(const Key('additionalInfoExpansionTile')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
