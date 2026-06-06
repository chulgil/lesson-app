import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_provider.dart';
import '../../../auth/auth_facade.dart';
import '../../../relationship/relationship_facade.dart';
import '../../../subscription/subscription_facade.dart';
import '../../data/repositories/mock_unified_lesson_request_repository.dart';
import '../../data/repositories/remote_unified_lesson_request_repository.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/schedule_confirmation_card.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/repositories/unified_lesson_request_repository.dart';
import '../../domain/services/unified_lesson_request_workflow_service.dart';
import '../extensions/unified_lesson_request_visuals.dart';
import 'schedule_confirmation_card_providers.dart';

part 'unified_lesson_request_providers.g.dart';

/// Student name lookup — Mock only (Remote: fetch from API).
/// Returns student name by studentId.
@Riverpod(keepAlive: true)
Map<String, String> studentNameMap(Ref ref) {
  return {
    'student_1': '김민준',
    'student_2': '이서현',
    'student_3': '박지호',
    'student_4': '최수아',
    'student_5': '정하은',
  };
}

/// Teacher name lookup — Mock only (Remote: fetch from API).
/// Returns teacher name by teacherId.
@Riverpod(keepAlive: true)
Map<String, String> teacherNameMap(Ref ref) {
  return {'teacher_1': '김선아', 'teacher_2': '박지영', 'teacher_3': '이현우'};
}

/// Academy name lookup — Mock only.
@Riverpod(keepAlive: true)
Map<String, String> academyNameMap(Ref ref) {
  return {'academy_1': '서울음악학원', 'academy_2': '강남아트스쿨'};
}

/// Repository provider — switches between Mock and Remote.
@Riverpod(keepAlive: true)
UnifiedLessonRequestRepository unifiedLessonRequestRepository(Ref ref) {
  return createRepository<UnifiedLessonRequestRepository>(
    ref: ref,
    mock: () => MockUnifiedLessonRequestRepository(),
    remote: (apiClient) => RemoteUnifiedLessonRequestRepository(apiClient),
  );
}

@Riverpod(keepAlive: true)
UnifiedLessonRequestWorkflowService unifiedLessonRequestWorkflowService(
  Ref ref,
) {
  return UnifiedLessonRequestWorkflowService(
    ref.watch(unifiedLessonRequestRepositoryProvider),
  );
}

/// Get all unified lesson requests for a teacher
@riverpod
Future<List<UnifiedLessonRequest>> teacherUnifiedRequests(
  TeacherUnifiedRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getByTeacherId(teacherId);
}

/// Get pending unified requests for a teacher
@riverpod
Future<List<UnifiedLessonRequest>> pendingUnifiedRequests(
  PendingUnifiedRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getPendingByTeacherId(teacherId);
}

/// Get pending unified request count (for badge)
@riverpod
Future<int> pendingUnifiedRequestCount(
  PendingUnifiedRequestCountRef ref,
  String teacherId,
) async {
  final requests = await ref.watch(
    pendingUnifiedRequestsProvider(teacherId).future,
  );
  return requests.length;
}

/// Get unified requests sent by a student
@riverpod
Future<List<UnifiedLessonRequest>> studentUnifiedRequests(
  StudentUnifiedRequestsRef ref,
  String studentId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getByStudentId(studentId);
}

/// Get a single unified request by ID
@riverpod
Future<UnifiedLessonRequest?> unifiedRequestById(
  UnifiedRequestByIdRef ref,
  String requestId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getById(requestId);
}

/// Get all events for a specific request (chat history).
@riverpod
Future<List<RequestEvent>> requestEvents(
  RequestEventsRef ref,
  String requestId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  return repository.getEventsByRequestId(requestId);
}

/// Today's requests for a teacher: active + completed today, pending first.
@riverpod
Future<List<UnifiedLessonRequest>> todayRequests(
  TodayRequestsRef ref,
  String teacherId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  final all = await repository.getByTeacherId(teacherId);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final filtered =
      all.where((r) {
        if (r.status.isActive) return true;
        if (r.status == UnifiedRequestStatus.completed &&
            r.confirmedAt != null) {
          final confirmedDate = DateTime(
            r.confirmedAt!.year,
            r.confirmedAt!.month,
            r.confirmedAt!.day,
          );
          return confirmedDate == today;
        }
        return false;
      }).toList();

  // Sort: pending first, then by createdAt desc
  filtered.sort((a, b) {
    if (a.status == UnifiedRequestStatus.pending &&
        b.status != UnifiedRequestStatus.pending) {
      return -1;
    }
    if (b.status == UnifiedRequestStatus.pending &&
        a.status != UnifiedRequestStatus.pending) {
      return 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  });

  return filtered;
}

/// Today's requests for a student: active + completed today, pending first.
@riverpod
Future<List<UnifiedLessonRequest>> studentTodayRequests(
  StudentTodayRequestsRef ref,
  String studentId,
) async {
  final repository = ref.watch(unifiedLessonRequestRepositoryProvider);
  final all = await repository.getByStudentId(studentId);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final filtered =
      all.where((r) {
        if (r.status.isActive) return true;
        if (r.status == UnifiedRequestStatus.completed &&
            r.confirmedAt != null) {
          final confirmedDate = DateTime(
            r.confirmedAt!.year,
            r.confirmedAt!.month,
            r.confirmedAt!.day,
          );
          return confirmedDate == today;
        }
        return false;
      }).toList();

  filtered.sort((a, b) {
    if (a.status == UnifiedRequestStatus.pending &&
        b.status != UnifiedRequestStatus.pending) {
      return -1;
    }
    if (b.status == UnifiedRequestStatus.pending &&
        a.status != UnifiedRequestStatus.pending) {
      return 1;
    }
    return b.createdAt.compareTo(a.createdAt);
  });

  return filtered;
}

/// Actions for unified lesson requests (create, approve, reject, cancel, modify).
/// Accepts both Ref and WidgetRef since it's called from providers and widgets.
class UnifiedLessonRequestActions {
  final dynamic ref;

  UnifiedLessonRequestActions(this.ref);

  UnifiedLessonRequestRepository get _repository =>
      ref.read(unifiedLessonRequestRepositoryProvider);

  UnifiedLessonRequestWorkflowService get _workflowService =>
      ref.read(unifiedLessonRequestWorkflowServiceProvider);

  /// Create a new unified lesson request
  Future<UnifiedLessonRequest> createRequest(
    UnifiedLessonRequest request,
  ) async {
    final result = await _workflowService.createRequest(
      request,
      currentUserId: ref.read(currentUserIdProvider),
    );

    _invalidateProviders(
      result.teacherId,
      result.studentId,
      requestId: result.id,
    );
    return result;
  }

  /// Approve a lesson request (teacher action).
  /// [selectedSlotIndex] records which preferred slot was chosen (for history display).
  Future<UnifiedLessonRequest> approveRequest(
    String requestId,
    String teacherId,
    String studentId, {
    int? selectedSlotIndex,
    String? message,
  }) async {
    final result = await _workflowService.approveRequest(
      requestId,
      teacherId: teacherId,
      selectedSlotIndex: selectedSlotIndex,
      message: message,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Student accepts teacher's alternative proposal.
  Future<UnifiedLessonRequest> acceptAlternativeRequest(
    String requestId,
    String teacherId,
    String studentId, {
    int? selectedSlotIndex,
    String? message,
  }) async {
    final result = await _workflowService.acceptAlternativeRequest(
      requestId,
      studentId: studentId,
      selectedSlotIndex: selectedSlotIndex,
      message: message,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Withdraw approval — revert to pending so actor can change decision.
  /// Records the previously selected slot index for history display.
  Future<UnifiedLessonRequest> withdrawApprovalRequest(
    String requestId,
    String teacherId,
    String studentId, {
    ProposerRole actorRole = ProposerRole.teacher,
  }) async {
    final result = await _workflowService.withdrawApprovalRequest(
      requestId,
      teacherId: teacherId,
      studentId: studentId,
      actorRole: actorRole,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Reject a lesson request (teacher action)
  Future<UnifiedLessonRequest> rejectRequest(
    String requestId,
    String teacherId,
    String studentId, {
    String? reason,
  }) async {
    final result = await _workflowService.rejectRequest(
      requestId,
      teacherId: teacherId,
      reason: reason,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Teacher proposes alternative time slots
  Future<UnifiedLessonRequest> proposeAlternatives(
    String requestId,
    String teacherId,
    String studentId, {
    required List<TimeSlotOption> slots,
    String? message,
  }) async {
    final result = await _workflowService.proposeAlternatives(
      requestId,
      slots: slots,
      message: message,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Student accepts one of the teacher's proposed alternatives
  Future<UnifiedLessonRequest> acceptAlternative(
    String requestId,
    String teacherId,
    String studentId, {
    required int selectedSlotIndex,
    String? message,
  }) async {
    final result = await _workflowService.acceptAlternative(
      requestId,
      selectedSlotIndex: selectedSlotIndex,
      message: message,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Student counter-proposes a different time slot
  Future<UnifiedLessonRequest> counterPropose(
    String requestId,
    String teacherId,
    String studentId, {
    required TimeSlotOption slot,
    String? message,
  }) async {
    final result = await _workflowService.counterPropose(
      requestId,
      slot: slot,
      message: message,
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Complete a request (trial: direct, regular: after subscription issued)
  Future<UnifiedLessonRequest> completeRequest(
    String requestId,
    String teacherId,
    String studentId,
  ) async {
    final request = await _repository.getById(requestId);
    if (request == null) throw Exception('Request not found: $requestId');
    final updated = request.copyWith(
      status: UnifiedRequestStatus.completed,
      confirmedAt: DateTime.now(),
    );
    final result = await _repository.update(updated);

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.completed,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Cancel a request (student or teacher action)
  Future<UnifiedLessonRequest> cancelRequest(
    String requestId,
    String actorId,
    ProposerRole actorType,
    String teacherId,
    String studentId, {
    String? reason,
  }) async {
    final request = await _repository.getById(requestId);
    if (request == null) throw Exception('Request not found: $requestId');
    if (!request.canTransitionTo(UnifiedRequestStatus.cancelled)) {
      throw Exception(
        'Cannot cancel request in ${request.status.label} status',
      );
    }

    final updated = request.copyWith(
      status: UnifiedRequestStatus.cancelled,
      cancelledAt: DateTime.now(),
    );
    final result = await _repository.update(updated);

    // Phase 3 statuses (subscriptionIssued / inProgress) use lessonCancelled;
    // Phase 1 negotiation statuses use cancel.
    final isPhase3 =
        request.status == UnifiedRequestStatus.subscriptionIssued ||
        request.status == UnifiedRequestStatus.inProgress;
    final eventType =
        isPhase3
            ? RequestEventType.lessonCancelled
            : RequestEventType.cancel;

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorType,
        actorId: actorId,
        eventType: eventType,
        message: reason,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Modify a pending request's preferred slots (before teacher responds)
  Future<UnifiedLessonRequest> modifyLastAction(
    String requestId,
    String studentId,
    String teacherId, {
    List<PreferredTimeSlot>? preferredSlots,
    String? message,
  }) async {
    final request = await _repository.getById(requestId);
    if (request == null) throw Exception('Request not found: $requestId');
    if (request.status != UnifiedRequestStatus.pending) {
      throw Exception(
        'Can only modify pending requests, current: ${request.status.label}',
      );
    }

    final updated = request.copyWith(
      preferredSlots: preferredSlots ?? request.preferredSlots,
      message: message ?? request.message,
    );
    final result = await _repository.update(updated);

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  // ── Phase 2: Subscription & Payment ─────────────────────

  /// Teacher sends payment guidance (proposal) to student.
  /// Updates request status to proposalSent.
  Future<void> sendPaymentGuide(
    String requestId,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    // Transition request to proposalSent
    final request = await _repository.getById(requestId);
    if (request != null) {
      final updated = request.copyWith(
        status: UnifiedRequestStatus.proposalSent,
      );
      await _repository.update(updated);
    }

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.proposalSent,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Student accepts the proposal (selects template if multi-choice).
  /// Updates request status to proposalAccepted.
  Future<void> acceptProposal(
    String requestId,
    String studentId,
    String teacherId, {
    String? selectedTemplateId,
    String? message,
  }) async {
    final request = await _repository.getById(requestId);
    if (request != null) {
      final updated = request.copyWith(
        status: UnifiedRequestStatus.proposalAccepted,
      );
      await _repository.update(updated);
    }

    // Include selected template in event message for traceability
    final eventMessage =
        selectedTemplateId != null
            ? (message ?? '수강권을 수락했습니다 (템플릿: $selectedTemplateId)')
            : message;

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.student,
        actorId: studentId,
        eventType: RequestEventType.proposalAccepted,
        message: eventMessage,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Student rejects the proposal.
  Future<void> rejectProposal(
    String requestId,
    String studentId,
    String teacherId, {
    String? reason,
  }) async {
    final request = await _repository.getById(requestId);
    if (request != null) {
      final updated = request.copyWith(status: UnifiedRequestStatus.rejected);
      await _repository.update(updated);
    }

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.student,
        actorId: studentId,
        eventType: RequestEventType.reject,
        message: reason,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Student notifies payment completed.
  /// Updates request status to paymentNotified.
  Future<void> confirmPayment(
    String requestId,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    final request = await _repository.getById(requestId);
    if (request != null) {
      final updated = request.copyWith(
        status: UnifiedRequestStatus.paymentNotified,
      );
      await _repository.update(updated);
    }

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.student,
        actorId: studentId,
        eventType: RequestEventType.paymentNotified,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Issue subscription (무료/후불/입금확인 후).
  /// Creates the subscription, creates a schedule confirmation card, and sets
  /// request status to subscriptionIssued.
  Future<void> issueSubscription(
    String requestId,
    String teacherId,
    String studentId, {
    required bool paymentConfirmed,
    String? message,
  }) async {
    final request = await _repository.getById(requestId);
    Subscription? subscription;
    if (request != null) {
      subscription = await _createSubscriptionForRequest(
        request,
        paymentConfirmed: paymentConfirmed,
      );
      await _activateRelationshipForRequest(request, subscription);
      await _createScheduleConfirmationCardForRequest(request, subscription);

      final updated = request.copyWith(
        status: UnifiedRequestStatus.subscriptionIssued,
      );
      await _repository.update(updated);
    }

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.subscriptionIssued,
        message:
            message ??
            (paymentConfirmed ? '수강권이 발행되었습니다' : '수강권이 발행되었습니다 (후불)'),
        subscriptionId: subscription?.id,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  Future<Subscription> _createSubscriptionForRequest(
    UnifiedLessonRequest request, {
    required bool paymentConfirmed,
  }) async {
    final repository = ref.read(subscriptionRepositoryProvider);
    final now = DateTime.now();
    final subscription = Subscription(
      id: 'sub_${now.microsecondsSinceEpoch}',
      studentId: request.studentId,
      membershipId: '',
      type: switch (request.type) {
        LessonRequestType.trial => SubscriptionType.trial,
        LessonRequestType.package => SubscriptionType.package,
        LessonRequestType.regular => SubscriptionType.monthly,
      },
      totalLessons: switch (request.type) {
        LessonRequestType.trial => 1,
        LessonRequestType.package => 4,
        LessonRequestType.regular => null,
      },
      lessonsPerMonth: request.type == LessonRequestType.regular ? 4 : null,
      usedLessons: 0,
      startDate: now,
      amount: request.suggestedPrice ?? 0,
      status: SubscriptionStatus.active,
      createdAt: now,
      paymentConfirmed: paymentConfirmed,
      paymentMethod:
          paymentConfirmed ? SubscriptionPaymentMethod.bankTransfer : null,
      paymentConfirmedAt: paymentConfirmed ? now : null,
    );
    return repository.create(subscription);
  }

  Future<void> _createScheduleConfirmationCardForRequest(
    UnifiedLessonRequest request,
    Subscription subscription,
  ) async {
    final repository = ref.read(scheduleConfirmationCardRepositoryProvider);
    final teacherNames = ref.read(teacherNameMapProvider);
    final primarySlot =
        request.preferredSlots.isNotEmpty ? request.preferredSlots.first : null;
    final suggestedDay =
        request.preferredDay != null
            ? request.preferredDay! + 1
            : primarySlot?.dayOfWeek != null
            ? primarySlot!.dayOfWeek! + 1
            : null;
    final suggestedTime = request.preferredTime ?? primarySlot?.startTime;

    await repository.createCard(
      ScheduleConfirmationCard(
        id: '',
        studentId: request.studentId,
        teacherId: request.teacherId,
        teacherName: teacherNames[request.teacherId] ?? '선생님',
        instrument: request.instrument,
        subscriptionId: subscription.id,
        suggestedDay: suggestedDay,
        suggestedTime: suggestedTime,
        lessonDuration: request.preferredDuration,
        cardType:
            request.isReturningStudent
                ? ScheduleCardType.reEnrollment
                : ScheduleCardType.afterTrial,
        createdAt: DateTime.now(),
        totalLessons: subscription.totalLessonsForDisplay,
        lessonRequestId: request.id,
      ),
    );
  }

  Future<void> _activateRelationshipForRequest(
    UnifiedLessonRequest request,
    Subscription subscription,
  ) async {
    final repository = ref.read(teacherStudentRelationRepositoryProvider);
    await repository.onSubscriptionIssued(
      teacherId: request.teacherId,
      studentId: request.studentId,
      subscriptionId: subscription.id,
    );
  }

  // ── Phase 3: Lesson Progress ───────────────────────────

  /// Record a lesson as completed + transition request to inProgress.
  Future<void> recordLessonCompleted(
    String requestId,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    // Transition request to inProgress if not already
    final request = await _repository.getById(requestId);
    if (request != null &&
        request.status == UnifiedRequestStatus.subscriptionIssued) {
      final updated = request.copyWith(status: UnifiedRequestStatus.inProgress);
      await _repository.update(updated);
    }

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.lessonCompleted,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Record a lesson cancellation.
  Future<void> recordLessonCancelled(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.lessonCancelled,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Record a schedule change.
  Future<void> recordScheduleChanged(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.scheduleChanged,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Teacher adds a lesson note.
  Future<void> recordLessonNote(
    String requestId,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.lessonNoteAdded,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Complete the entire subscription (all lessons done).
  Future<void> completeSubscription(
    String requestId,
    String teacherId,
    String studentId,
  ) async {
    final request = await _repository.getById(requestId);
    if (request == null) throw Exception('Request not found: $requestId');

    final updated = request.copyWith(
      status: UnifiedRequestStatus.completed,
      confirmedAt: DateTime.now(),
    );
    await _repository.update(updated);

    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: ProposerRole.teacher,
        actorId: teacherId,
        eventType: RequestEventType.subscriptionCompleted,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  // ── Phase 3: Schedule Change Negotiation ────────────────

  /// Propose a schedule change (single or bulk).
  Future<void> recordScheduleChangeProposed(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    required ScheduleChangeType changeType,
    List<TimeSlotOption> suggestedSlots = const [],
    int? proposedDayOfWeek,
    String? proposedTime,
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.scheduleChangeProposed,
        scheduleChangeType: changeType,
        suggestedSlots: suggestedSlots,
        proposedDayOfWeek: proposedDayOfWeek,
        proposedTime: proposedTime,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Accept a schedule change proposal.
  Future<void> recordScheduleChangeAccepted(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    int? selectedSlotIndex,
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.scheduleChangeAccepted,
        selectedSlotIndex: selectedSlotIndex,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    // Record final scheduleChanged event for timeline summary
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch + 1}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.scheduleChanged,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Reject a schedule change proposal.
  Future<void> recordScheduleChangeRejected(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.scheduleChangeRejected,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Counter-propose a schedule change with new times.
  Future<void> recordScheduleChangeCountered(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    required ScheduleChangeType changeType,
    List<TimeSlotOption> suggestedSlots = const [],
    int? proposedDayOfWeek,
    String? proposedTime,
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.scheduleChangeCountered,
        scheduleChangeType: changeType,
        suggestedSlots: suggestedSlots,
        proposedDayOfWeek: proposedDayOfWeek,
        proposedTime: proposedTime,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  /// Renew a subscription (extend lessons).
  Future<void> renewSubscription(
    String requestId,
    String actorId,
    ProposerRole actorRole,
    String teacherId,
    String studentId, {
    String? message,
  }) async {
    await _repository.addEvent(
      RequestEvent(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        requestId: requestId,
        actorType: actorRole,
        actorId: actorId,
        eventType: RequestEventType.subscriptionRenewed,
        message: message,
        createdAt: DateTime.now(),
      ),
    );

    _invalidateProviders(teacherId, studentId, requestId: requestId);
  }

  void _invalidateProviders(
    String teacherId,
    String studentId, {
    String? requestId,
  }) {
    ref.invalidate(teacherUnifiedRequestsProvider(teacherId));
    ref.invalidate(pendingUnifiedRequestsProvider(teacherId));
    ref.invalidate(pendingUnifiedRequestCountProvider(teacherId));
    ref.invalidate(studentUnifiedRequestsProvider(studentId));
    ref.invalidate(todayRequestsProvider(teacherId));
    ref.invalidate(studentTodayRequestsProvider(studentId));
    if (requestId != null) {
      ref.invalidate(requestEventsProvider(requestId));
      ref.invalidate(unifiedRequestByIdProvider(requestId));
    }
  }
}
