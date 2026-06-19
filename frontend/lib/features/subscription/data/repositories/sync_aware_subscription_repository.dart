import 'package:uuid/uuid.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/pending_payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../local/subscription_cache_store.dart';
import 'remote_subscription_repository.dart';

/// Decorator that wraps [RemoteSubscriptionRepository] with:
///   1. Hive read-through cache — successful remote reads are persisted.
///   2. Offline queue support for mutations.
///
/// Read behaviour:
///   - Online success → write to cache, return result.
///   - Network failure ([NetworkException] / [ServerException] / 5xx) →
///     return cached last-known-good if available, otherwise rethrow.
///   - Cache miss + network failure → rethrow original error.
///
/// Streams and online-only operations delegate directly to [_remote].
class SyncAwareSubscriptionRepository implements SubscriptionRepository {
  final RemoteSubscriptionRepository _remote;
  final MutationQueueHelper _queue;
  final SubscriptionCacheStore? _cache;

  SyncAwareSubscriptionRepository({
    required RemoteSubscriptionRepository remote,
    required MutationQueueHelper queue,
    SubscriptionCacheStore? cache,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;

  // ═══════════════════════════════════════════════════════════════════
  // Private cache helpers
  // ═══════════════════════════════════════════════════════════════════

  bool _isNetworkFailure(Exception e) {
    if (e is NetworkException) return true;
    if (e is ServerException) return true;
    if (e is ApiException && e.statusCode != null && e.statusCode! >= 500) {
      return true;
    }
    return false;
  }

  Future<List<Subscription>> _readListWithCache(
    String key,
    Future<List<Subscription>> Function() fetch,
  ) async {
    try {
      final result = await fetch();
      await _cache?.putSubscriptions(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        final cached = _cache?.getSubscriptions(key);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<Subscription?> _readNullableWithCache(
    String key,
    Future<Subscription?> Function() fetch,
  ) async {
    try {
      final result = await fetch();
      await _cache?.putSubscription(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        // getSubscription returns null on cache miss — both safe to fallback
        return _cache?.getSubscription(key);
      }
      rethrow;
    }
  }

  Future<List<SubscriptionUsage>> _readUsageListWithCache(
    String key,
    Future<List<SubscriptionUsage>> Function() fetch,
  ) async {
    try {
      final result = await fetch();
      await _cache?.putUsageHistory(key, result);
      return result;
    } on Exception catch (e) {
      if (_isNetworkFailure(e)) {
        final cached = _cache?.getUsageHistory(key);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Read methods — with cache fallback
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<Subscription>> getByStudentId(String studentId) =>
      _readListWithCache(
        SubscriptionCacheStore.keyStudent(studentId),
        () => _remote.getByStudentId(studentId),
      );

  @override
  Future<Subscription?> getActiveByMembershipId(String membershipId) =>
      _readNullableWithCache(
        SubscriptionCacheStore.keyMembership(membershipId),
        () => _remote.getActiveByMembershipId(membershipId),
      );

  @override
  Future<Subscription?> getById(String id) => _readNullableWithCache(
    SubscriptionCacheStore.keySub(id),
    () => _remote.getById(id),
  );

  @override
  Future<List<Subscription>> getExpiringSoon() => _readListWithCache(
    SubscriptionCacheStore.keyExpiringSoon(),
    _remote.getExpiringSoon,
  );

  @override
  Future<List<Subscription>> getExpired() => _readListWithCache(
    SubscriptionCacheStore.keyExpired(),
    _remote.getExpired,
  );

  @override
  Future<List<Subscription>> getByTeacherId(String teacherId) =>
      _readListWithCache(
        SubscriptionCacheStore.keyTeacher(teacherId),
        () => _remote.getByTeacherId(teacherId),
      );

  @override
  Future<List<Subscription>> getUnpaidSubscriptions(String teacherId) =>
      _readListWithCache(
        SubscriptionCacheStore.keyUnpaid(teacherId),
        () => _remote.getUnpaidSubscriptions(teacherId),
      );

  @override
  Future<List<SubscriptionUsage>> getUsageHistory(String subscriptionId) =>
      _readUsageListWithCache(
        SubscriptionCacheStore.keyUsage(subscriptionId),
        () => _remote.getUsageHistory(subscriptionId),
      );

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
      _queue.executeMutation<Subscription>(
        remoteCall: () => _remote.create(subscription),
        queueCall:
            (syncService) => syncService.queueMutation(
              domain: 'subscription',
              httpMethod: 'POST',
              path: '/subscriptions',
              payload: subscription.toJson(),
            ),
        optimisticResult:
            () => subscription.copyWith(id: 'tmp_${const Uuid().v4()}'),
      );

  @override
  Future<Subscription> update(Subscription subscription) =>
      _queue.executeMutation<Subscription>(
        remoteCall: () => _remote.update(subscription),
        queueCall:
            (syncService) => syncService.queueMutation(
              domain: 'subscription',
              httpMethod: 'PUT',
              path: '/subscriptions/${subscription.id}',
              payload: subscription.toJson(),
            ),
        optimisticResult: () => subscription,
      );

  @override
  Future<Subscription> useLesson(
    String id, {
    String? lessonId,
    String? teacherName,
    String? instrument,
  }) =>
  // Online-only: requires current subscription state for optimistic result
  _remote.useLesson(
    id,
    lessonId: lessonId,
    teacherName: teacherName,
    instrument: instrument,
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
            (syncService) => syncService.queueMutation(
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
            (syncService) => syncService.queueMutation(
              domain: 'subscription',
              httpMethod: 'POST',
              path: '/subscriptions/${usage.subscriptionId}/usage',
              payload: usage.toJson(),
            ),
        optimisticResult: () => usage,
      );
}
