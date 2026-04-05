import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../schedule/domain/entities/lesson_schedule_change.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../data/repositories/mock_subscription_repository.dart';
import '../../data/repositories/remote_subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';

part 'subscription_providers.g.dart';

/// Repository provider for Subscription - switches between Mock and Remote.
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) =>
    createRepository<SubscriptionRepository>(
      ref: ref,
      mock: () => MockSubscriptionRepository(),
      remote: (api) => RemoteSubscriptionRepository(api),
    ));

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
      .where(
        (s) =>
            s.status == SubscriptionStatus.active ||
            s.status == SubscriptionStatus.expiringSoon,
      )
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

/// Get expired subscriptions (for dashboard alerts).
@riverpod
Future<List<Subscription>> expiredSubscriptions(
  ExpiredSubscriptionsRef ref,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getExpired();
}

/// Get usage history for a subscription.
@riverpod
Future<List<SubscriptionUsage>> subscriptionUsageHistory(
  SubscriptionUsageHistoryRef ref,
  String subscriptionId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getUsageHistory(subscriptionId);
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

  /// Use one reschedule allowance.
  /// Call this when student changes their booking.
  Future<Subscription> useReschedule(String id) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.useReschedule(id);
    ref.invalidateSelf();
    return updated;
  }

  /// Confirm payment on a subscription (resolve 미수금).
  Future<Subscription> confirmPayment(
    String id, {
    SubscriptionPaymentMethod? paymentMethod,
  }) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.confirmPayment(
      id,
      paymentMethod: paymentMethod,
    );
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

  /// Use one reschedule allowance from the active subscription.
  Future<Subscription> useReschedule() async {
    final subscription = await future;
    if (subscription == null) {
      throw Exception('No active subscription found');
    }
    if (!subscription.canReschedule) {
      throw Exception('No reschedule allowance remaining');
    }
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.useReschedule(subscription.id);
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

// ═══════════════════════════════════════════════════════════════════
// Unpaid (미수금) Providers
// ═══════════════════════════════════════════════════════════════════

/// Get unpaid subscriptions for a teacher.
@riverpod
Future<List<Subscription>> unpaidSubscriptions(
  UnpaidSubscriptionsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getUnpaidSubscriptions(teacherId);
}

/// Get unpaid summary (total amount + student count) for a teacher.
@riverpod
Future<({int totalAmount, int studentCount})> unpaidSummary(
  UnpaidSummaryRef ref,
  String teacherId,
) async {
  final unpaid = await ref.watch(unpaidSubscriptionsProvider(teacherId).future);
  return (
    totalAmount: unpaid.fold(0, (sum, s) => sum + s.amount),
    studentCount: unpaid.map((s) => s.studentId).toSet().length,
  );
}

// ═══════════════════════════════════════════════════════════════════
// Subscription Validation Providers
// ═══════════════════════════════════════════════════════════════════

/// Check if a student has an active subscription with a teacher.
/// Returns the active subscription if found, null otherwise.
@riverpod
Future<Subscription?> activeSubscriptionBetween(
  ActiveSubscriptionBetweenRef ref, {
  required String studentId,
  required String teacherId,
}) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  final teacherSubscriptions = await repository.getByTeacherId(teacherId);

  // Find active subscription for this student
  final studentSubscriptions =
      teacherSubscriptions
          .where(
            (s) =>
                s.studentId == studentId &&
                (s.status == SubscriptionStatus.active ||
                    s.status == SubscriptionStatus.expiringSoon) &&
                (s.remainingLessons ?? 0) > 0,
          )
          .toList();

  if (studentSubscriptions.isEmpty) {
    return null;
  }

  // Return the first active subscription (could prioritize by expiry date later)
  return studentSubscriptions.first;
}

/// Check if a student can book a lesson with a teacher.
/// Returns true if:
/// - It's a trial lesson (no subscription needed)
/// - Student has an active subscription with remaining lessons
@riverpod
Future<bool> canBookLesson(
  CanBookLessonRef ref, {
  required String studentId,
  required String teacherId,
  required bool isTrialLesson,
}) async {
  // Trial lessons don't require subscription
  if (isTrialLesson) {
    return true;
  }

  final subscription = await ref.watch(
    activeSubscriptionBetweenProvider(
      studentId: studentId,
      teacherId: teacherId,
    ).future,
  );

  return subscription != null && (subscription.remainingLessons ?? 0) > 0;
}

// ═══════════════════════════════════════════════════════════════════
// Subscription Session Event Providers
// ═══════════════════════════════════════════════════════════════════

/// Get events for a specific subscription session.
@riverpod
Future<List<RequestEvent>> subscriptionSessionEvents(
  SubscriptionSessionEventsRef ref, {
  required String subscriptionId,
  required int sessionNumber,
}) async {
  // For now, return empty list — will be populated when events are created
  // TODO: Implement actual query by subscriptionId + sessionNumber
  return [];
}

/// Get pending schedule change requests for badge count.
@riverpod
Future<List<RequestEvent>> pendingScheduleChangeRequests(
  PendingScheduleChangeRequestsRef ref,
  String teacherId,
) async {
  // Mock data for UI verification — replace with actual API query later
  final now = DateTime.now();
  return [
    // 시간 변경 요청 (학생 → 선생님)
    RequestEvent(
      id: 'sce_mock_1',
      requestId: '',
      actorType: ProposerRole.student,
      actorId: 'student_1',
      eventType: RequestEventType.scheduleChanged,
      message: '개인 일정이 변경되어 시간 변경을 요청합니다',
      createdAt: now.subtract(const Duration(hours: 2)),
      subscriptionId: 'sub_pkg_01',
      sessionNumber: 6,
    ),
    // 취소 요청
    RequestEvent(
      id: 'sce_mock_2',
      requestId: '',
      actorType: ProposerRole.student,
      actorId: 'student_3',
      eventType: RequestEventType.lessonCancelled,
      message: '컨디션이 좋지 않아 취소 요청드립니다',
      createdAt: now.subtract(const Duration(minutes: 30)),
      subscriptionId: 'sub_pkg_02',
      sessionNumber: 3,
    ),
    // 전체 스케줄 변경 요청
    RequestEvent(
      id: 'sce_mock_3',
      requestId: '',
      actorType: ProposerRole.student,
      actorId: 'student_1',
      eventType: RequestEventType.scheduleChanged,
      message: '학교 시간표가 바뀌어서 전체 변경 부탁드립니다',
      createdAt: now.subtract(const Duration(days: 1)),
      subscriptionId: 'sub_mon_01',
      sessionNumber: 4,
      scheduleChangeType: ScheduleChangeType.bulkChange,
    ),
    // 시간 변경 제안 완료 (선생님이 이미 응답)
    RequestEvent(
      id: 'sce_mock_4',
      requestId: '',
      actorType: ProposerRole.teacher,
      actorId: 'teacher_1',
      eventType: RequestEventType.scheduleChangeProposed,
      message: '아래 시간 중 선택해주세요',
      createdAt: now.subtract(const Duration(hours: 5)),
      subscriptionId: 'sub_mon_02',
      sessionNumber: 5,
    ),
    // 수락 완료
    RequestEvent(
      id: 'sce_mock_5',
      requestId: '',
      actorType: ProposerRole.student,
      actorId: 'student_5',
      eventType: RequestEventType.scheduleChangeAccepted,
      message: '1순위 시간으로 확정합니다',
      createdAt: now.subtract(const Duration(days: 2)),
      subscriptionId: 'sub_mon_03',
      sessionNumber: 2,
    ),
  ];
}
