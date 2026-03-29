import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/mock_unified_lesson_request_repository.dart';
import '../../domain/entities/request_event.dart';
import '../../domain/entities/unified_lesson_request.dart';
import '../../domain/repositories/unified_lesson_request_repository.dart';

part 'unified_lesson_request_providers.g.dart';

/// Student name lookup — Mock only (Remote: fetch from API).
/// Returns student name by studentId.
final studentNameMapProvider = Provider<Map<String, String>>((ref) => {
      'student_1': '김민준',
      'student_2': '이서현',
      'student_3': '박지호',
      'student_4': '최수아',
      'student_5': '정하은',
    });

/// Academy name lookup — Mock only.
final academyNameMapProvider = Provider<Map<String, String>>((ref) => {
      'academy_1': '서울음악학원',
      'academy_2': '강남아트스쿨',
    });

/// Repository provider — currently Mock only (Remote in backend integration phase).
final unifiedLessonRequestRepositoryProvider =
    Provider<UnifiedLessonRequestRepository>(
  (ref) => MockUnifiedLessonRequestRepository(),
);

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

  final filtered = all.where((r) {
    if (r.status.isActive) return true;
    if (r.status == UnifiedRequestStatus.completed && r.confirmedAt != null) {
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
        b.status != UnifiedRequestStatus.pending) return -1;
    if (b.status == UnifiedRequestStatus.pending &&
        a.status != UnifiedRequestStatus.pending) return 1;
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

  final filtered = all.where((r) {
    if (r.status.isActive) return true;
    if (r.status == UnifiedRequestStatus.completed && r.confirmedAt != null) {
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

  /// Create a new unified lesson request
  Future<UnifiedLessonRequest> createRequest(
    UnifiedLessonRequest request,
  ) async {
    final result = await _repository.create(request);

    // Create initial request event
    await _repository.addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: result.id,
      actorType: ProposerRole.student,
      actorId: request.studentId,
      eventType: RequestEventType.initialRequest,
      suggestedSlots: request.preferredSlots
          .map((ps) => TimeSlotOption(
                id: 'slot_${ps.priority}',
                dayOfWeek: ps.dayOfWeek ?? 0,
                startTime: ps.startTime,
                endTime: ps.endTime,
              ))
          .toList(),
      message: request.message,
      createdAt: DateTime.now(),
    ));

    _invalidateProviders(request.teacherId, request.studentId,
        requestId: result.id);
    return result;
  }

  /// Approve a lesson request (teacher action).
  /// [selectedSlotIndex] records which preferred slot was chosen (for history display).
  Future<UnifiedLessonRequest> approveRequest(
    String requestId,
    String teacherId,
    String studentId, {
    int? selectedSlotIndex,
  }) async {
    final result = await _repository.approve(requestId);

    await _repository.addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      actorType: ProposerRole.teacher,
      actorId: teacherId,
      eventType: RequestEventType.approve,
      selectedSlotIndex: selectedSlotIndex,
      createdAt: DateTime.now(),
    ));

    _invalidateProviders(teacherId, studentId, requestId: requestId);
    return result;
  }

  /// Withdraw approval — revert to pending so teacher can change decision.
  /// History is preserved; a withdrawApproval event is added.
  Future<UnifiedLessonRequest> withdrawApprovalRequest(
    String requestId,
    String teacherId,
    String studentId,
  ) async {
    final result = await _repository.withdrawApproval(requestId);

    await _repository.addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      actorType: ProposerRole.teacher,
      actorId: teacherId,
      eventType: RequestEventType.withdrawApproval,
      createdAt: DateTime.now(),
    ));

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
    final result = await _repository.reject(requestId, reason: reason);

    await _repository.addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      actorType: ProposerRole.teacher,
      actorId: teacherId,
      eventType: RequestEventType.reject,
      message: reason,
      createdAt: DateTime.now(),
    ));

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
    // Repository internally creates the event — no duplicate here
    final result = await _repository.proposeAlternatives(
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
    // Repository internally creates the event — no duplicate here
    final result = await _repository.acceptAlternative(
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
    // Repository internally creates the event — no duplicate here
    final result = await _repository.counterPropose(
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

    await _repository.addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      actorType: ProposerRole.teacher,
      actorId: teacherId,
      eventType: RequestEventType.completed,
      createdAt: DateTime.now(),
    ));

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

    await _repository.addEvent(RequestEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      requestId: requestId,
      actorType: actorType,
      actorId: actorId,
      eventType: RequestEventType.cancel,
      message: reason,
      createdAt: DateTime.now(),
    ));

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
    if (requestId != null) {
      ref.invalidate(requestEventsProvider(requestId));
      ref.invalidate(unifiedRequestByIdProvider(requestId));
    }
  }
}
