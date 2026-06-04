import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/practice/presentation/widgets/goal/goal_achieved_dialog.dart';

void main() {
  group('GoalAchievedDialog', () {
    testWidgets('renders daily achievement title/message without crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalAchievedDialog(scope: GoalAchievementScope.daily),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.goalAchievedDailyTitle), findsOneWidget);
      expect(find.text(AppStrings.goalAchievedDailyMessage), findsOneWidget);
      expect(find.text(AppStrings.goalAchievedConfirm), findsOneWidget);
    });

    testWidgets('renders weekly achievement title/message without crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoalAchievedDialog(scope: GoalAchievementScope.weekly),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.goalAchievedWeeklyTitle), findsOneWidget);
      expect(find.text(AppStrings.goalAchievedWeeklyMessage), findsOneWidget);
    });

    testWidgets('confirm button pops the dialog', (tester) async {
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: SizedBox()),
        ),
      );

      // Show dialog via static helper
      // ignore: unawaited_futures
      GoalAchievedDialog.show(
        navKey.currentContext!,
        scope: GoalAchievementScope.daily,
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.goalAchievedDailyTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.goalAchievedConfirm));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.goalAchievedDailyTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
