// Widget smoke test for the quest unlock celebration sheet (감사 §4.5 B3).
//
// HARD-GATE (.claude/rules/design-principles.md): top-level widget renders
// without runtime layout crashes. Animation runs via pumpAndSettle so we
// also assert that the post-animation final state matches the spec.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/core/theme/app_theme.dart';
import 'package:lessonaza/features/onboarding/presentation/widgets/quest_unlock_celebration_sheet.dart';

void main() {
  testWidgets('QuestUnlockCelebrationSheet renders title, message, and CTA', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: QuestUnlockCelebrationSheet()),
      ),
    );
    // pumpAndSettle to let the 400ms scale + fade animation complete.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.questUnlockCelebrationTitle), findsOneWidget);
    expect(find.text(AppStrings.questUnlockCelebrationMessage), findsOneWidget);
    expect(find.text(AppStrings.questUnlockCelebrationAction), findsOneWidget);
  });

  testWidgets('QuestUnlockCelebrationSheet pops on CTA tap', (tester) async {
    var popped = false;
    final observer = _PopRecorder(onPopped: () => popped = true);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorObservers: [observer],
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => const Scaffold(
                                  body: QuestUnlockCelebrationSheet(),
                                ),
                          ),
                        ),
                    child: const Text('open'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.questUnlockCelebrationAction));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
  });
}

class _PopRecorder extends NavigatorObserver {
  _PopRecorder({required this.onPopped});

  final VoidCallback onPopped;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPopped();
    super.didPop(route, previousRoute);
  }
}
