import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/presentation/providers/payment_tracking_provider.dart';
import 'package:lessonaza/features/subscription/presentation/widgets/payment_pending_card.dart';

void main() {
  group('PaymentPendingCard smoke — #424', () {
    testWidgets('renders nothing when count is 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [paymentPendingCountProvider.overrideWith((_) async => 0)],
          child: const MaterialApp(home: Scaffold(body: PaymentPendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('입금 확인 대기'), findsNothing);
    });

    testWidgets('renders title and count when count > 0', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [paymentPendingCountProvider.overrideWith((_) async => 3)],
          child: const MaterialApp(home: Scaffold(body: PaymentPendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('입금 확인 대기'), findsOneWidget);
      expect(find.text('3건'), findsOneWidget);
    });

    testWidgets('renders nothing on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentPendingCountProvider.overrideWith((_) async {
              throw Exception('boom');
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: PaymentPendingCard())),
        ),
      );
      await tester.pumpAndSettle();
      // takeException returns the thrown error; we just verify the card stayed hidden.
      tester.takeException();
      expect(find.text('입금 확인 대기'), findsNothing);
    });
  });
}
