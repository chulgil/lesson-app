import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pending_payment.dart';
import 'subscription_providers.dart';

/// Pending-payment list for the teacher dashboard — #424.
///
/// Server already returns rows sorted by D+N descending.
final paymentPendingListProvider =
    FutureProvider.autoDispose<List<PendingPayment>>((ref) async {
      final repository = ref.watch(subscriptionRepositoryProvider);
      return repository.getPendingPayments();
    });

/// Lightweight count for the home card — #424.
final paymentPendingCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getPendingPaymentCount();
});

/// Actions used by the home card and list screen.
final paymentTrackingActionsProvider = Provider<PaymentTrackingActions>(
  (ref) => PaymentTrackingActions(ref),
);

class PaymentTrackingActions {
  PaymentTrackingActions(this._ref);

  final Ref _ref;

  Future<void> resend(String proposalId) async {
    final repo = _ref.read(subscriptionRepositoryProvider);
    await repo.resendProposalReminder(proposalId);
    _ref.invalidate(paymentPendingListProvider);
    _ref.invalidate(paymentPendingCountProvider);
  }

  Future<void> revoke(String proposalId) async {
    final repo = _ref.read(subscriptionRepositoryProvider);
    await repo.revokeProposal(proposalId);
    _ref.invalidate(paymentPendingListProvider);
    _ref.invalidate(paymentPendingCountProvider);
  }

  void refresh() {
    _ref.invalidate(paymentPendingListProvider);
    _ref.invalidate(paymentPendingCountProvider);
  }
}
