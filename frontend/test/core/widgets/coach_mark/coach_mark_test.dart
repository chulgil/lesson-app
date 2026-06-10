import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/widgets/coach_mark/coach_mark_controller.dart';
import 'package:lessonaza/core/widgets/coach_mark/coach_mark_overlay.dart';
import 'package:lessonaza/core/widgets/coach_mark/coach_mark_scope.dart';

// Helper: pumps two frames so that the post-frame target measurement fires
// and triggers setState before assertions.
Future<void> pumpOverlay(WidgetTester tester) async {
  await tester.pump(); // initial build
  await tester.pump(); // post-frame callback → setState → re-build with rect
}

// Helper: wraps a widget in MaterialApp with a known viewport so that
// Material widgets (buttons, TextTheme, etc.) and MediaQuery are available.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: Scaffold(body: SizedBox(width: 390, height: 844, child: child)),
    ),
  );
}

// Helper: builds a CoachMarkOverlay with a real GlobalKey attached to a Box.
Widget _overlayWithTarget({
  required GlobalKey key,
  String title = 'Test Title',
  String description = 'Test description',
  String actionLabel = 'Next',
  VoidCallback? onAction,
  VoidCallback? onDismiss,
  CoachMarkPosition position = CoachMarkPosition.below,
}) {
  return _wrap(
    Stack(
      children: [
        // Target widget
        Positioned(
          top: 200,
          left: 50,
          child: Container(
            key: key,
            width: 100,
            height: 50,
            color: Colors.blue,
          ),
        ),
        CoachMarkOverlay(
          targetKey: key,
          title: title,
          description: description,
          actionLabel: actionLabel,
          onAction: onAction ?? () {},
          onDismiss: onDismiss,
          position: position,
        ),
      ],
    ),
  );
}

void main() {
  // ── CoachMarkOverlay ──────────────────────────────────────────────────────

  group('CoachMarkOverlay', () {
    testWidgets('renders title and description', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _overlayWithTarget(
          key: key,
          title: 'Welcome',
          description: 'Tap here to continue',
          actionLabel: 'Got it',
        ),
      );
      await pumpOverlay(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Tap here to continue'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('calls onAction when action button is tapped', (tester) async {
      final key = GlobalKey();
      var actionCalled = false;

      await tester.pumpWidget(
        _overlayWithTarget(
          key: key,
          actionLabel: 'Start',
          onAction: () => actionCalled = true,
        ),
      );
      await pumpOverlay(tester);

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('shows skip button when onDismiss is provided', (tester) async {
      final key = GlobalKey();
      var dismissCalled = false;

      await tester.pumpWidget(
        _overlayWithTarget(key: key, onDismiss: () => dismissCalled = true),
      );
      await pumpOverlay(tester);

      expect(find.text('건너뛰기'), findsOneWidget);
      await tester.tap(find.text('건너뛰기'));
      await tester.pump();

      expect(dismissCalled, isTrue);
    });

    testWidgets('calls onDismiss when backdrop is tapped', (tester) async {
      final key = GlobalKey();
      var dismissCalled = false;

      await tester.pumpWidget(
        _overlayWithTarget(key: key, onDismiss: () => dismissCalled = true),
      );
      await pumpOverlay(tester);

      // Tap the scrim area (top-left corner, away from target and balloon)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(dismissCalled, isTrue);
    });

    testWidgets('smoke test: no layout errors on default viewport', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        _overlayWithTarget(
          key: key,
          title: 'Smoke',
          description: 'Should render without BoxConstraints errors',
          actionLabel: 'OK',
        ),
      );
      await pumpOverlay(tester);

      expect(tester.takeException(), isNull);
    });
  });

  // ── CoachMarkController ───────────────────────────────────────────────────

  group('CoachMarkController', () {
    CoachMarkStep step(String id) => CoachMarkStep(
      id: id,
      targetKey: GlobalKey(),
      title: 'Step $id',
      description: 'Description $id',
      actionLabel: 'Next',
    );

    test('starts at index 0 and exposes currentStep', () {
      final controller = CoachMarkController(steps: [step('a'), step('b')]);

      expect(controller.isActive, isFalse);
      expect(controller.currentStep, isNull);

      controller.start();

      expect(controller.isActive, isTrue);
      expect(controller.currentIndex, 0);
      expect(controller.currentStep?.id, 'a');
    });

    test('advances through steps with next()', () {
      final controller = CoachMarkController(
        steps: [step('a'), step('b'), step('c')],
      );

      controller.start();
      expect(controller.currentStep?.id, 'a');

      controller.next();
      expect(controller.currentStep?.id, 'b');

      controller.next();
      expect(controller.currentStep?.id, 'c');
    });

    test('dismiss() stops the sequence and resets index', () {
      final controller = CoachMarkController(steps: [step('a'), step('b')]);

      controller.start();
      controller.next();
      expect(controller.currentIndex, 1);

      controller.dismiss();

      expect(controller.isActive, isFalse);
      expect(controller.currentIndex, 0);
      expect(controller.currentStep, isNull);
    });

    test('next() past the last step calls dismiss automatically', () {
      final controller = CoachMarkController(steps: [step('only')]);

      controller.start();
      controller.next(); // past last step → dismiss

      expect(controller.isActive, isFalse);
    });

    test('notifyListeners is called on start, next, and dismiss', () {
      final controller = CoachMarkController(steps: [step('a'), step('b')]);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.start(); // +1
      controller.next(); // +1
      controller.dismiss(); // +1

      expect(notifyCount, 3);
    });
  });

  // ── CoachMarkScope ────────────────────────────────────────────────────────

  group('CoachMarkScope', () {
    testWidgets('shows overlay when controller is active', (tester) async {
      final targetKey = GlobalKey();
      final controller = CoachMarkController(
        steps: [
          CoachMarkStep(
            id: 'intro',
            targetKey: targetKey,
            title: 'Scope Title',
            description: 'Scope desc',
            actionLabel: 'OK',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachMarkScope(
              controller: controller,
              child: SizedBox(
                width: 390,
                height: 844,
                child: Stack(
                  children: [
                    Positioned(
                      top: 200,
                      left: 50,
                      child: Container(
                        key: targetKey,
                        width: 100,
                        height: 50,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Scope Title'), findsNothing);

      controller.start();
      await pumpOverlay(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Scope Title'), findsOneWidget);
    });

    testWidgets('hides overlay after dismiss()', (tester) async {
      final targetKey = GlobalKey();
      final controller = CoachMarkController(
        steps: [
          CoachMarkStep(
            id: 'intro',
            targetKey: targetKey,
            title: 'Hide Me',
            description: 'desc',
            actionLabel: 'OK',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoachMarkScope(
              controller: controller,
              child: SizedBox(
                width: 390,
                height: 844,
                child: Container(key: targetKey, color: Colors.red),
              ),
            ),
          ),
        ),
      );

      controller.start();
      await pumpOverlay(tester);
      expect(find.text('Hide Me'), findsOneWidget);

      controller.dismiss();
      await tester.pump();
      expect(find.text('Hide Me'), findsNothing);
    });
  });
}
