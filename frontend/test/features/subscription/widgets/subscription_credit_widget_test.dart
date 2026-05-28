import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lessonaza/features/subscription/domain/entities/subscription.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/subscription_credit_widget.dart';

Subscription _buildSubscription({int credits = 0}) {
  return Subscription(
    id: 'sub-test',
    studentId: 'student-1',
    membershipId: 'membership-1',
    type: SubscriptionType.monthly,
    amount: 200000,
    status: SubscriptionStatus.active,
    createdAt: DateTime(2026, 5, 1),
    cancellationCredits: credits,
  );
}

void main() {
  group('SubscriptionCreditWidget', () {
    testWidgets('shows remaining count when credits > 0', (tester) async {
      final sub = _buildSubscription(credits: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SubscriptionCreditWidget(subscription: sub)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('변경권 잔여: 2회'), findsOneWidget);
    });

    testWidgets('shows none label when credits = 0', (tester) async {
      final sub = _buildSubscription();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SubscriptionCreditWidget(subscription: sub)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('변경권 없음'), findsOneWidget);
    });

    testWidgets('renders inside narrow Row without crash', (tester) async {
      final sub = _buildSubscription(credits: 5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: Row(
                children: [SubscriptionCreditWidget(subscription: sub)],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('변경권 잔여: 5회'), findsOneWidget);
    });
  });
}
