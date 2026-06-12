import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/gamification/presentation/screens/student_gamification_onboarding_screen.dart';

Future<void> _pump(
  WidgetTester tester,
  void Function(String, bool) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(home: StudentGamificationOnboardingScreen(onResult: onResult)),
  );
}

void main() {
  testWidgets(
    'renders greeting / 4 instrument chips / recommendation / 2 CTAs',
    (tester) async {
      await _pump(tester, (_, __) {});
      expect(find.byKey(const ValueKey('onboarding_greeting')), findsOneWidget);
      expect(find.text('안녕! 무슨 악기 해?'), findsOneWidget);
      expect(find.byKey(const ValueKey('instrument_바이올린')), findsOneWidget);
      expect(find.byKey(const ValueKey('instrument_피아노')), findsOneWidget);
      expect(find.byKey(const ValueKey('instrument_기타')), findsOneWidget);
      expect(find.byKey(const ValueKey('instrument_기타...')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('onboarding_recommendation')),
        findsOneWidget,
      );
      expect(find.text('"스케일 5분"'), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding_accept')), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding_decline')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('both CTAs disabled until instrument selected', (tester) async {
    await _pump(tester, (_, __) {});
    final accept = tester.widget<FilledButton>(
      find.byKey(const ValueKey('onboarding_accept')),
    );
    final decline = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('onboarding_decline')),
    );
    expect(accept.onPressed, isNull);
    expect(decline.onPressed, isNull);
  });

  testWidgets('selecting instrument enables both CTAs', (tester) async {
    await _pump(tester, (_, __) {});
    await tester.tap(find.byKey(const ValueKey('instrument_바이올린')));
    await tester.pump();
    final accept = tester.widget<FilledButton>(
      find.byKey(const ValueKey('onboarding_accept')),
    );
    expect(accept.onPressed, isNotNull);
  });

  testWidgets('accept CTA fires onResult with accepted=true', (tester) async {
    String? capturedInst;
    bool? capturedAccepted;
    await _pump(tester, (inst, accepted) {
      capturedInst = inst;
      capturedAccepted = accepted;
    });
    await tester.tap(find.byKey(const ValueKey('instrument_피아노')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_accept')));
    await tester.pump();
    expect(capturedInst, '피아노');
    expect(capturedAccepted, true);
  });

  testWidgets('decline CTA fires onResult with accepted=false', (tester) async {
    bool? capturedAccepted;
    await _pump(tester, (_, accepted) {
      capturedAccepted = accepted;
    });
    await tester.tap(find.byKey(const ValueKey('instrument_바이올린')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('onboarding_decline')));
    await tester.pump();
    expect(capturedAccepted, false);
  });

  testWidgets('renders on mobile viewport 375x667 without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375 * 3, 667 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    await _pump(tester, (_, __) {});
    expect(tester.takeException(), isNull);
  });
}
