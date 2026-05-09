import 'package:uuid/uuid.dart';

import '../../../../core/sync/application/mutation_queue_helper.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';
import 'remote_subscription_repository.dart';

/// Decorator that wraps [RemoteSubscriptionRepository] with offline queue support.
///
/// Read methods and streams delegate directly to [_remote].
/// Mutation methods use [_queue] to handle offline scenarios with optimistic results.
class SyncAwareSubscriptionRepository implements SubscriptionRepository {
  final RemoteSubscriptionRepository _remote;
  final MutationQueueHelper _queue;

  SyncAwareSubscriptionRepository({
    required RemoteSubscriptionRepository remote,
    required MutationQueueHelper queue,
  })  : _remote = remote,
        _queue = queue;

  // ═══════════════════════════════════════════════════════════════════
  // Read methods — direct delegation
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<List<Subscription>> getByStudentId(String studentId) =>
      _remote.getByStudentId(studentId);

  @override
  Future<Subscription?> getActiveByMembershipId(String membershipId) =>
      _remote.getActiveByMembershipId(membershipId);

  @override
  Future<Subscription?> getById(String id) => _remote.getById(id);

  @override
  Stream<List<Subscription>> watchByStudentId(String studentId) =>
      _remote.watchByStudentId(studentId);

  @override
  Stream<Subscription?> watchActiveByMembershipId(String membershipId) =>
      _remote.watchActiveByMembershipId(membershipId);

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
  // Mutations with offline queue support
  // ═══════════════════════════════════════════════════════════════════

  @override
  Future<Subscription> create(Subscription subscription) =>
      _queue.executeMutation<Subscription>(
        remoteCall: () => _remote.create(subscription),
        queueCall: (syncService) => syncService.queueMutation(
          domain: 'subscription',
          httpMethod: 'POST',
          path: '/subscriptions',
          payload: subscription.toJson(),
        ),
        optimisticResult: () => subscription.copyWith(
          id: 'tmp_${const Uuid().v4()}',
        ),
      );

  @override
  Future<Subscription> update(Subscription subscription) =>
      _queue.executeMutation<Subscription>(
        remoteCall: () => _remote.update(subscription),
        queueCall: (syncService) => syncService.queueMutation(
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
        queueCall: (syncService) => syncService.queueMutation(
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
  Future<SubscriptionUsage> addUsage(SubscriptionUsage usage) =>
      _queue.executeMutation<SubscriptionUsage>(
        remoteCall: () => _remote.addUsage(usage),
        queueCall: (syncService) => syncService.queueMutation(
          domain: 'subscription',
          httpMethod: 'POST',
          path: '/subscriptions/${usage.subscriptionId}/usage',
          payload: usage.toJson(),
        ),
        optimisticResult: () => usage,
      );
}
