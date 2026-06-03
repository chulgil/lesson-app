import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/core/l10n/app_strings.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';
import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/providers/subscription_providers.dart';
import 'package:lessonaza/features/subscription/presentation/screens/issue_subscription_screen.dart';

/// Counts create() calls and adds a short delay so the in-flight window is
/// observable during a double-tap.
class _CountingSubscriptionRepository extends MockSubscriptionRepository {
  int createCount = 0;

  @override
  Future<Subscription> create(Subscription subscription) async {
    createCount++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.create(subscription);
  }
}

void main() {
  testWidgets(
    'batch issue button ignores a double-tap (no duplicate issuance)',
    (tester) async {
      final repo = _CountingSubscriptionRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subscriptionRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: IssueSubscriptionScreen(
              // 2 students → batch mode, no membership lookup required.
              studentIds: ['student-1', 'student-2'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll so the (lazily built) amount field is realized, then fill it.
      // The amount field has a required validator that otherwise blocks submit.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      final amountField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == AppStrings.issueFormAmountHint,
      );
      expect(amountField, findsOneWidget);
      await tester.enterText(amountField, '100000');
      await tester.pump();

      final button = find.byType(FilledButton);
      expect(button, findsOneWidget);

      // First tap kicks off the issue. While it is in flight the button must
      // be disabled so a second tap cannot start a duplicate issue.
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 5));
      expect(
        tester.widget<FilledButton>(button).onPressed,
        isNull,
        reason: 'button must be disabled while an issue is in flight',
      );

      // Second (ignored) tap.
      await tester.tap(button, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 5));

      // Let the in-flight issue finish.
      await tester.pumpAndSettle();

      // 2 students issued exactly once each = 2 create calls, not 4.
      expect(repo.createCount, 2);
    },
  );
}
