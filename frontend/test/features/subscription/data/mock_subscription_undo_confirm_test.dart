import 'package:flutter_test/flutter_test.dart';
import 'package:lessonaza/features/subscription/data/repositories/mock_subscription_repository.dart';

void main() {
  group('MockSubscriptionRepository.undoConfirmPayment — #426', () {
    test(
      'confirm → undo: paymentConfirmed back to false, paymentConfirmedAt null',
      () async {
        final repo = MockSubscriptionRepository();
        final unpaid = await repo.getUnpaidSubscriptions('any');
        expect(
          unpaid,
          isNotEmpty,
          reason: 'seed must include unpaid subscriptions',
        );
        final target = unpaid.first;

        final confirmed = await repo.confirmPayment(target.id);
        expect(confirmed.paymentConfirmed, isTrue);
        expect(confirmed.paymentConfirmedAt, isNotNull);

        final undone = await repo.undoConfirmPayment(target.id);
        expect(undone.paymentConfirmed, isFalse);
        expect(undone.paymentConfirmedAt, isNull);
      },
    );

    test('undo on never-confirmed throws', () async {
      final repo = MockSubscriptionRepository();
      final unpaid = await repo.getUnpaidSubscriptions('any');
      expect(unpaid, isNotEmpty);
      await expectLater(
        () => repo.undoConfirmPayment(unpaid.first.id),
        throwsA(isA<Exception>()),
      );
    });

    test('undo on missing id throws', () async {
      final repo = MockSubscriptionRepository();
      await expectLater(
        () => repo.undoConfirmPayment('nonexistent-id'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
