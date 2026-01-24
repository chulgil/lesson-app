import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

part 'subscription_providers.g.dart';

/// Repository provider for Subscription.
@riverpod
SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
  return MockSubscriptionRepository();
}

/// Get all subscriptions for a student.
@riverpod
Future<List<Subscription>> studentSubscriptions(
  StudentSubscriptionsRef ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getByStudentId(studentId);
}

/// Get active subscriptions for a student (active or expiring soon).
@riverpod
Future<List<Subscription>> activeStudentSubscriptions(
  ActiveStudentSubscriptionsRef ref,
  String studentId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final subscriptions = await repository.getByStudentId(studentId);
  return subscriptions
      .where((s) =>
          s.status == SubscriptionStatus.active ||
          s.status == SubscriptionStatus.expiringSoon)
      .toList();
}

/// Get active subscription for a membership.
@riverpod
Future<Subscription?> membershipSubscription(
  MembershipSubscriptionRef ref,
  String membershipId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getActiveByMembershipId(membershipId);
}

/// Get a single subscription by ID.
@riverpod
Future<Subscription?> subscription(SubscriptionRef ref, String id) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getById(id);
}

/// Get subscriptions expiring soon (for notifications/alerts).
@riverpod
Future<List<Subscription>> expiringSoonSubscriptions(
  ExpiringSoonSubscriptionsRef ref,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getExpiringSoon();
}

/// Get all subscriptions for a teacher's students.
@riverpod
Future<List<Subscription>> teacherStudentSubscriptions(
  TeacherStudentSubscriptionsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}

/// Notifier for managing Subscription CRUD operations for a student.
@riverpod
class SubscriptionNotifier extends _$SubscriptionNotifier {
  @override
  Future<List<Subscription>> build(String studentId) async {
    final repository = ref.watch(subscriptionRepositoryProvider);
    return repository.getByStudentId(studentId);
  }

  Future<Subscription> create(Subscription subscription) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final created = await repository.create(subscription);
    ref.invalidateSelf();
    return created;
  }

  Future<Subscription> updateSubscription(Subscription subscription) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.update(subscription);
    ref.invalidateSelf();
    return updated;
  }

  Future<Subscription> useLesson(String id) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.useLesson(id);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> updateStatus(String id, SubscriptionStatus status) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    await repository.updateStatus(id, status);
    ref.invalidateSelf();
  }

  Future<void> pause(String id) async {
    await updateStatus(id, SubscriptionStatus.paused);
  }

  Future<void> resume(String id) async {
    await updateStatus(id, SubscriptionStatus.active);
  }
}

/// Notifier for managing a single subscription (for membership).
@riverpod
class MembershipSubscriptionNotifier extends _$MembershipSubscriptionNotifier {
  @override
  Future<Subscription?> build(String membershipId) async {
    final repository = ref.watch(subscriptionRepositoryProvider);
    return repository.getActiveByMembershipId(membershipId);
  }

  Future<Subscription> create(Subscription subscription) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final created = await repository.create(subscription);
    ref.invalidateSelf();
    return created;
  }

  Future<Subscription> useLesson() async {
    final subscription = await future;
    if (subscription == null) {
      throw Exception('No active subscription found');
    }
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.useLesson(subscription.id);
    ref.invalidateSelf();
    return updated;
  }

  Future<void> pause() async {
    final subscription = await future;
    if (subscription == null) return;
    final repository = ref.read(subscriptionRepositoryProvider);
    await repository.updateStatus(subscription.id, SubscriptionStatus.paused);
    ref.invalidateSelf();
  }

  Future<void> resume() async {
    final subscription = await future;
    if (subscription == null) return;
    final repository = ref.read(subscriptionRepositoryProvider);
    await repository.updateStatus(subscription.id, SubscriptionStatus.active);
    ref.invalidateSelf();
  }
}
