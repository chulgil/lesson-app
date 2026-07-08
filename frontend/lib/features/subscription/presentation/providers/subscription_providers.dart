import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../schedule/domain/entities/request_event.dart';
import '../../../schedule/domain/entities/unified_lesson_request.dart';
import '../../data/repositories/mock_subscription_repository.dart';
import '../../data/repositories/remote_subscription_repository.dart';
import 'payment_tracking_provider.dart';
import '../../data/repositories/sync_aware_subscription_repository.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_usage.dart';
import '../../domain/repositories/subscription_repository.dart';

part 'subscription_providers.g.dart';

/// Repository provider for Subscription - switches between Mock and Remote.
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(SubscriptionRepositoryRef ref) {
  return createSyncAwareRepository<SubscriptionRepository>(
    ref: ref,
    mock: () => MockSubscriptionRepository(),
    syncAware:
        (api, queue) => SyncAwareSubscriptionRepository(
          remote: RemoteSubscriptionRepository(api),
          queue: queue,
        ),
  );
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
    // 단일 subscriptionProvider(id)(상세 화면 watch)도 무효화 — 정책 수정이
    // 상세에 즉시 반영되도록. invalidateSelf 는 리스트만 갱신한다.
    ref.invalidate(subscriptionProvider(subscription.id));
    return updated;
  }

  Future<Subscription> useLesson(String id) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.useLesson(id);
    ref.invalidateSelf();
    ref.invalidate(subscriptionProvider(id));
    return updated;
  }

  /// Use one reschedule allowance.
  /// Call this when student changes their booking.
  Future<Subscription> useReschedule(String id) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.useReschedule(id);
    ref.invalidateSelf();
    ref.invalidate(subscriptionProvider(id));
    return updated;
  }

  /// Confirm manual deposit on a subscription.
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

  /// Undo a manual deposit confirmation within 24h — #426.
  Future<Subscription> undoConfirmPayment(String id) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final updated = await repository.undoConfirmPayment(id);
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

/// Invalidate every subscription list/summary provider that surfaces a newly
/// issued subscription, so list and detail views reflect it immediately.
///
/// Callers that create a subscription through the repository directly (issue
/// flow, proposal confirmation) MUST call this so the student/teacher facing
/// providers re-fetch. [membershipId] and [teacherId] are optional and only
/// invalidated when provided.
void invalidateSubscriptionListsForStudent(
  WidgetRef ref,
  String studentId, {
  String? membershipId,
  String? teacherId,
}) {
  ref.invalidate(subscriptionNotifierProvider(studentId));
  ref.invalidate(studentSubscriptionsProvider(studentId));
  ref.invalidate(activeStudentSubscriptionsProvider(studentId));
  if (membershipId != null && membershipId.isNotEmpty) {
    ref.invalidate(membershipSubscriptionProvider(membershipId));
    ref.invalidate(membershipSubscriptionNotifierProvider(membershipId));
  }
  if (teacherId != null && teacherId.isNotEmpty) {
    ref.invalidate(teacherStudentSubscriptionsProvider(teacherId));
    ref.invalidate(unpaidSubscriptionsProvider(teacherId));
  }
  // Payment pending dashboard counts must also refresh so the teacher/student
  // home badges reflect the new subscription state immediately.
  ref.invalidate(paymentPendingListProvider);
  ref.invalidate(paymentPendingCountProvider);
}

// ═══════════════════════════════════════════════════════════════════
// Deposit confirmation pending providers
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

/// In-memory store for subscription session events (Mock).
/// Key: "$subscriptionId:$sessionNumber"
/// Will be replaced with API calls when backend is ready.
final _subscriptionSessionEventStore = <String, List<RequestEvent>>{};

String _sessionEventKey(String subscriptionId, int sessionNumber) =>
    '$subscriptionId:$sessionNumber';

List<RequestEvent> _mockScheduleChangeEvents() {
  final now = DateTime.now();
  return [
    RequestEvent(
      id: 'sce_mock_1',
      requestId: 'sub_pkg_01',
      actorType: ProposerRole.student,
      actorId: 'student_1',
      eventType: RequestEventType.scheduleChanged,
      message: '개인 일정이 변경되어 6회차 시간 변경을 요청합니다',
      suggestedSlots: [
        TimeSlotOption(
          id: 'sce_mock_1_slot_1',
          dayOfWeek: 1,
          startTime: '18:00',
          endTime: '19:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_1_slot_2',
          dayOfWeek: 3,
          startTime: '19:00',
          endTime: '20:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_1_slot_3',
          dayOfWeek: 5,
          startTime: '11:00',
          endTime: '12:00',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
      scheduleChangeType: ScheduleChangeType.singleLesson,
      subscriptionId: 'sub_pkg_01',
      sessionNumber: 6,
    ),
    RequestEvent(
      id: 'sce_mock_2',
      requestId: 'sub_pkg_02',
      actorType: ProposerRole.student,
      actorId: 'student_3',
      eventType: RequestEventType.lessonCancelled,
      message: '3회차 레슨 취소를 요청합니다. 취소/변경권 1회를 사용합니다.',
      createdAt: now.subtract(const Duration(minutes: 30)),
      subscriptionId: 'sub_pkg_02',
      sessionNumber: 3,
    ),
    RequestEvent(
      id: 'sce_mock_3',
      requestId: 'sub_mon_01',
      actorType: ProposerRole.student,
      actorId: 'student_2',
      eventType: RequestEventType.scheduleChanged,
      message: '학교 시간표가 바뀌어서 앞으로 모든 레슨을 아래 시간으로 변경 요청합니다',
      suggestedSlots: [
        TimeSlotOption(
          id: 'sce_mock_3_slot_1',
          dayOfWeek: 0,
          startTime: '18:00',
          endTime: '19:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_3_slot_2',
          dayOfWeek: 2,
          startTime: '17:00',
          endTime: '18:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_3_slot_3',
          dayOfWeek: 4,
          startTime: '20:00',
          endTime: '21:00',
        ),
      ],
      createdAt: now.subtract(const Duration(days: 1)),
      scheduleChangeType: ScheduleChangeType.bulkChange,
      proposedDayOfWeek: 0,
      proposedTime: '18:00',
      subscriptionId: 'sub_mon_01',
      sessionNumber: 4,
    ),
    RequestEvent(
      id: 'sce_mock_4',
      requestId: 'sub_mon_02',
      actorType: ProposerRole.teacher,
      actorId: 'teacher_1',
      eventType: RequestEventType.scheduleChangeProposed,
      message: '4회차 시간 변경안입니다. 가능한 시간을 선택해주세요.',
      suggestedSlots: [
        TimeSlotOption(
          id: 'sce_mock_4_slot_1',
          dayOfWeek: 4,
          startTime: '16:00',
          endTime: '17:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_4_slot_2',
          dayOfWeek: 5,
          startTime: '11:00',
          endTime: '12:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_4_slot_3',
          dayOfWeek: 6,
          startTime: '15:00',
          endTime: '16:00',
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 5)),
      scheduleChangeType: ScheduleChangeType.singleLesson,
      subscriptionId: 'sub_mon_02',
      sessionNumber: 4,
    ),
    RequestEvent(
      id: 'sce_mock_5',
      requestId: 'sub_mon_03',
      actorType: ProposerRole.student,
      actorId: 'student_11',
      eventType: RequestEventType.scheduleChangeAccepted,
      message: '2회차는 1순위 시간으로 확정합니다',
      suggestedSlots: [
        TimeSlotOption(
          id: 'sce_mock_5_slot_1',
          dayOfWeek: 1,
          startTime: '14:00',
          endTime: '15:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_5_slot_2',
          dayOfWeek: 3,
          startTime: '18:00',
          endTime: '19:00',
        ),
        TimeSlotOption(
          id: 'sce_mock_5_slot_3',
          dayOfWeek: 5,
          startTime: '10:00',
          endTime: '11:00',
        ),
      ],
      selectedSlotIndex: 0,
      createdAt: now.subtract(const Duration(days: 2)),
      scheduleChangeType: ScheduleChangeType.singleLesson,
      subscriptionId: 'sub_mon_03',
      sessionNumber: 2,
    ),
  ];
}

List<RequestEvent> _dedupeAndSortEvents(Iterable<RequestEvent> events) {
  final byId = <String, RequestEvent>{};
  for (final event in events) {
    byId[event.id] = event;
  }
  return byId.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

const _pendingScheduleChangeSourceTypes = {
  RequestEventType.scheduleChanged,
  RequestEventType.scheduleChangeProposed,
  RequestEventType.scheduleChangeCountered,
  RequestEventType.lessonCancelled,
};

/// SSOT for schedule-change negotiation terminal events shared across the
/// subscription detail UI (#543). These types end the negotiation thread for
/// BOTH parties, so the input bar reverts to Default and the pending badge
/// clears. [scheduleChangeAccepted] is intentionally excluded here: the
/// acceptor keeps seeing Waiting until the thread moves on, so accept is
/// terminal only for the pending-list provider below.
const scheduleChangeNegotiationTerminalTypes = {
  RequestEventType.scheduleChangeRejected,
  // #692: 72h 만료 시 양측 Default 복귀
  RequestEventType.scheduleChangeExpired,
};

const _pendingScheduleChangeTerminalTypes = {
  RequestEventType.scheduleChangeAccepted,
  ...scheduleChangeNegotiationTerminalTypes,
};

String _scheduleChangeThreadKey(RequestEvent event) {
  return [
    event.subscriptionId ?? event.requestId,
    event.sessionNumber?.toString() ?? '',
  ].join(':');
}

List<RequestEvent> pendingScheduleChangeEventsFromHistory(
  Iterable<RequestEvent> events,
) {
  final latestPendingByThread = <String, RequestEvent>{};
  for (final event in _dedupeAndSortEvents(events)) {
    final threadKey = _scheduleChangeThreadKey(event);
    if (_pendingScheduleChangeSourceTypes.contains(event.eventType)) {
      latestPendingByThread[threadKey] = event;
      continue;
    }
    if (_pendingScheduleChangeTerminalTypes.contains(event.eventType)) {
      latestPendingByThread.remove(threadKey);
    }
  }

  return latestPendingByThread.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

void resetMockSubscriptionSessionEventsForTesting() {
  _subscriptionSessionEventStore.clear();
}

@Riverpod(keepAlive: true)
SubscriptionSessionEventActions subscriptionSessionEventActions(
  SubscriptionSessionEventActionsRef ref,
) {
  return SubscriptionSessionEventActions(ref);
}

class SubscriptionSessionEventActions {
  const SubscriptionSessionEventActions(this._ref);

  final dynamic _ref;

  Future<void> addSessionEvent({
    required String subscriptionId,
    required int sessionNumber,
    required RequestEvent event,
    String? affectedTeacherId,
    String? affectedStudentId,
  }) async {
    addSubscriptionSessionEvent(_ref, subscriptionId, sessionNumber, event);
    if (affectedTeacherId != null) {
      _ref.invalidate(pendingScheduleChangeRequestsProvider(affectedTeacherId));
    }
    if (affectedStudentId != null) {
      _ref.invalidate(pendingScheduleChangeRequestsProvider(affectedStudentId));
    }
  }
}

/// Add an event to a subscription session and invalidate the provider.
void addSubscriptionSessionEvent(
  dynamic ref,
  String subscriptionId,
  int sessionNumber,
  RequestEvent event,
) {
  final key = _sessionEventKey(subscriptionId, sessionNumber);
  _subscriptionSessionEventStore.putIfAbsent(key, () => []).add(event);

  // Invalidate provider to trigger UI refresh
  ref.invalidate(
    subscriptionSessionEventsProvider(
      subscriptionId: subscriptionId,
      sessionNumber: sessionNumber,
    ),
  );
}

/// Get events for a specific subscription session.
@riverpod
Future<List<RequestEvent>> subscriptionSessionEvents(
  SubscriptionSessionEventsRef ref, {
  required String subscriptionId,
  required int sessionNumber,
}) async {
  final key = _sessionEventKey(subscriptionId, sessionNumber);
  final seededEvents = _mockScheduleChangeEvents().where(
    (event) =>
        event.subscriptionId == subscriptionId &&
        event.sessionNumber == sessionNumber,
  );
  final storedEvents = _subscriptionSessionEventStore[key] ?? const [];
  return _dedupeAndSortEvents([...seededEvents, ...storedEvents]);
}

/// Get pending schedule change requests for badge count.
@riverpod
Future<List<RequestEvent>> pendingScheduleChangeRequests(
  PendingScheduleChangeRequestsRef ref,
  String teacherId,
) async {
  if (!ref.watch(mockDataModeProvider)) {
    return const [];
  }

  final storedEvents = _subscriptionSessionEventStore.values.expand(
    (events) => events,
  );
  return pendingScheduleChangeEventsFromHistory([
    ..._mockScheduleChangeEvents(),
    ...storedEvents,
  ]);
}
