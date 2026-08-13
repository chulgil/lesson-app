import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/pending_payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'remote_subscription_repository.dart';

/// Decorator that wraps [RemoteSubscriptionRepository] with offline
/// **write-queue** support ([MutationQueueHelper]).
///
/// Reads delegate straight to the remote repository — offline read fallback is
/// provided transparently at the HTTP layer by `ResponseCacheInterceptor`
/// (offline-first plan §3 option A; batch 1d 일원화 — the previous Hive
/// read-through cache layer was removed in favour of the single HTTP response
/// cache). Writes are queued when offline and replayed on reconnect.
class SyncAwareSubscriptionRepository implements SubscriptionRepository {
  SyncAwareSubscriptionRepository({
    required RemoteSubscriptionRepository remote,
    required MutationQueueHelper queue,
  }) : _remote = remote,
       _queue = queue;

  final RemoteSubscriptionRepository _remote;
  final MutationQueueHelper _queue;

  // --------------------------------------------------------------------------
  // Read methods — delegate to remote; HTTP response cache handles offline.
  // --------------------------------------------------------------------------

  @override
  Future<List<Subscription>> getByStudentId(String studentId) =>
      _remote.getByStudentId(studentId);

  @override
  Future<Subscription?> getActiveByMembershipId(String membershipId) =>
      _remote.getActiveByMembershipId(membershipId);

  @override
  Future<Subscription?> getById(String id) => _remote.getById(id);

  @override
  Future<List<Subscription>> getExpiringSoon() => _remote.getExpiringSoon();

  @override
  Future<List<Subscription>> getExpired() => _remote.getExpired();

  @override
  Future<List<Subscription>> getByTeacherId(String teacherId) =>
      _remote.getByTeacherId(teacherId);

  @override
  Future<List<Subscription>> getUnpaidSubscriptions(String teacherId) =>
      _remote.getUnpaidSubscriptions(teacherId);

  @override
  Future<List<SubscriptionUsage>> getUsageHistory(String subscriptionId) =>
      _remote.getUsageHistory(subscriptionId);

  // ═══════════════════════════════════════════════════════════════════
  // Streams — delegate directly (stream-based caching is out of scope)
  // ═══════════════════════════════════════════════════════════════════

  @override
  Stream<List<Subscription>> watchByStudentId(String studentId) =>
      _remote.watchByStudentId(studentId);

  @override
  Stream<Subscription?> watchActiveByMembershipId(String membershipId) =>
      _remote.watchActiveByMembershipId(membershipId);

  // ═══════════════════════════════════════════════════════════════════
  // Mutations with offline queue support
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Subscription> create(Subscription subscription) =>
  // Issuance is online-required (#1248). Every create caller immediately
  // chains direct-HTTP follow-ups (proposal confirmPayment, membership/
  // relationship wiring, orphan cleanup) that need the real server id.
  // Queueing an optimistic tmp_ id let those steps run against an id the
  // server never learns about — after replay the real subscription stayed
  // active+paymentConfirmed with no matching proposal (money-integrity
  // orphan). Failing fast keeps the flow atomic: the teacher sees the
  // error and retries online.
  _remote.create(subscription);

  @override
  Future<Subscription> update(Subscription subscription) =>
      _queue.executeMutation<Subscription>(
        remoteCall: () => _remote.update(subscription),
        queueCall:
            (syncService, idempotencyKey) => syncService.queueMutation(
              idempotencyKey: idempotencyKey,
              domain: 'subscription',
              httpMethod: 'PUT',
              path: '/subscriptions/${subscription.id}',
              payload: subscription.toJson(),
            ),
        optimisticResult: () => subscription,
      );

  @override
  Future<Subscription> useReschedule(String id) =>
  // Online-only: requires current subscription state for optimistic result
  _remote.useReschedule(id);

  @override
  Future<void> updateStatus(String id, SubscriptionStatus status) =>
      _queue.executeVoidMutation(
        remoteCall: () => _remote.updateStatus(id, status),
        queueCall:
            (syncService, idempotencyKey) => syncService.queueMutation(
              idempotencyKey: idempotencyKey,
              domain: 'subscription',
              httpMethod: 'PATCH',
              path: '/subscriptions/$id/status',
              payload: {'status': status.name},
            ),
      );

  @override
  Future<Subscription> confirmPayment(
    String id, {
    SubscriptionPaymentMethod? paymentMethod,
  }) =>
  // Online-only: payment operations require immediate server confirmation
  _remote.confirmPayment(id, paymentMethod: paymentMethod);

  @override
  Future<Subscription> undoConfirmPayment(String id) =>
  // Online-only: payment operations require immediate server confirmation
  _remote.undoConfirmPayment(id);

  // ═══════════════════════════════════════════════════════════════════
  // Payment-pending dashboard — #424 (online-only, no offline queue)
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<PendingPayment>> getPendingPayments() =>
      _remote.getPendingPayments();

  @override
  Future<int> getPendingPaymentCount() => _remote.getPendingPaymentCount();

  @override
  Future<void> resendProposalReminder(String proposalId) =>
      _remote.resendProposalReminder(proposalId);

  @override
  Future<bool> requestPaymentConfirmation(String proposalId) =>
      _remote.requestPaymentConfirmation(proposalId);

  @override
  Future<void> revokeProposal(String proposalId) =>
      _remote.revokeProposal(proposalId);

  @override
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) =>
      _queue.executeMutation<SubscriptionUsage>(
        remoteCall: () => _remote.addUsage(usage),
        queueCall:
            (syncService, idempotencyKey) => syncService.queueMutation(
              idempotencyKey: idempotencyKey,
              domain: 'subscription',
              httpMethod: 'POST',
              path: '/subscriptions/${usage.subscriptionId}/usage',
              payload: usage.toJson(),
            ),
        optimisticResult: () => usage,
      );
}
